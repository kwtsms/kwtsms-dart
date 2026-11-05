import 'dart:io';
import 'package:test/test.dart';
import 'package:kwtsms/kwtsms.dart';

import 'test_number.dart';

// 2026-11-05 08:20 +03: live sends go only to KWTSMS_TEST_NUMBER (skipped when
// unset); local-rejection tests use the 965XXXXXXXX placeholder; the live
// 250-number bulk send to generated numbers is removed (covered offline by
// mock_bulk_test.dart). Why: those numbers belong to real people. int-testnumber.
void main() {
  final username = Platform.environment['DART_USERNAME'] ?? '';
  final password = Platform.environment['DART_PASSWORD'] ?? '';
  final hasCredentials = username.isNotEmpty && password.isNotEmpty;

  // Shared client instance: created once, reused across all tests.
  // cachedBalance tracks the running balance as credits are consumed.
  late KwtSMS sms;
  late double startingBalance;

  // Credit budget for this entire test file:
  //
  // Tests that consume credits (send reaches the API):
  //   send to valid Kuwait number .............. 1
  //   send with + prefix ...................... 1
  //   send with 00 prefix ..................... 1
  //   send with Arabic digits ................. 1
  //   send mixed valid+invalid (1 valid) ...... 1
  //   send deduplicates (3→1 unique) .......... 1
  //   send with wrong sender ID ............... 1
  //                                     total = 7
  //
  // Tests that do NOT consume credits (rejected locally):
  //   send to too-short, email, empty, emoji-only, wrong creds: 0
  //
  const totalCreditsNeeded = 7;

  setUpAll(() async {
    if (!hasCredentials) return;

    sms = KwtSMS(username, password, testMode: true, logFile: '');

    // Get the starting balance ONCE before any test runs
    final bal = await sms.balance();
    expect(bal, isNotNull, reason: 'balance() must return a value');
    startingBalance = bal!;

    // Abort early if insufficient credits
    expect(startingBalance, greaterThanOrEqualTo(totalCreditsNeeded),
        reason: 'Need $totalCreditsNeeded credits for all tests. '
            'Current balance: $startingBalance');
  });

  group('Integration tests (real API, test mode)', () {
    test('verify with valid credentials succeeds', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.verify();
      expect(result.ok, isTrue);
      expect(result.balance, isNotNull);
      expect(result.balance, greaterThanOrEqualTo(0));
    });

    test('verify with wrong credentials fails', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final bad = KwtSMS('dart_wrong_user', 'dart_wrong_pass',
          testMode: true, logFile: '');
      final result = await bad.verify();
      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('balance returns a number', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final bal = await sms.balance();
      expect(bal, isNotNull);
      expect(bal, greaterThanOrEqualTo(0));
    });

    // --- Send tests that CONSUME credits (1 each) ---

    test('send to valid Kuwait number succeeds (test mode) [1 credit]',
        () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send(n, 'Test from Dart client');
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.msgId, isNotNull);
        expect(result.pointsCharged, 1);
        expect(result.balanceAfter, balBefore! - 1,
            reason: 'balance should decrease by 1 credit');
      }
    });

    test('send with + prefix normalizes correctly [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send('+$n', 'Test normalization');
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.balanceAfter, balBefore! - 1);
      }
    });

    test('send with 00 prefix normalizes correctly [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send('00$n', 'Test 00 prefix');
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.balanceAfter, balBefore! - 1);
      }
    });

    test('send with Arabic digits normalizes correctly [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send(
        toArabicIndic(n),
        'Test Arabic digits',
      );
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.balanceAfter, balBefore! - 1);
      }
    });

    test('send mixed valid and invalid numbers [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send(
        '$n,123,user@email.com',
        'Test mixed numbers',
      );
      // 2 invalid (123 too short, email), 1 valid → 1 credit
      expect(result.invalid, isNotEmpty);
      if (result.result == 'OK') {
        expect(result.numbers, 1);
        expect(result.pointsCharged, 1);
        expect(result.balanceAfter, balBefore! - 1);
      }
    });

    test('send deduplicates normalized numbers [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final balBefore = await sms.balance();
      final result = await sms.send(
        '+$n,00$n,$n',
        'Test deduplication',
      );
      // All three normalize to the same number, deduplicated to 1
      expect(result.result, anyOf('OK', 'ERROR'));
      if (result.result == 'OK') {
        expect(result.numbers, 1);
        expect(result.pointsCharged, 1);
        expect(result.balanceAfter, balBefore! - 1);
      }
    });

    test('send with wrong sender ID [1 credit]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final result = await sms.send(
        n,
        'Test wrong sender',
        sender: 'INVALID-SENDER-ID-THAT-DOES-NOT-EXIST',
      );
      // API may reject the sender ID (ERR008) or accept it
      expect(result.result, anyOf('OK', 'ERROR'));
    });

    // --- Send tests that do NOT consume credits (local rejection) ---

    test('send to too-short number returns error [0 credits]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('12345', 'Test message');
      expect(result.result, 'ERROR');
      expect(result.invalid, isNotEmpty);
      expect(result.invalid.first.error, contains('too short'));
    });

    test('send to email returns error [0 credits]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send('user@example.com', 'Test message');
      expect(result.result, 'ERROR');
      expect(result.invalid, isNotEmpty);
      expect(result.invalid.first.error, contains('email'));
    });

    test('send empty message returns error [0 credits]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.send(testNumberPlaceholder, '');
      expect(result.result, 'ERROR');
    });

    test('send emoji-only message returns error [0 credits]', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result =
          await sms.send(testNumberPlaceholder, '\u{1F600}\u{1F601}');
      expect(result.result, 'ERROR');
      expect(result.code, 'ERR009');
    });

    // --- Non-send tests ---

    test('validate numbers', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final n = testNumberOrSkip();
      if (n == null) return;
      final result = await sms.validate([n, '123', 'test@email.com']);
      // 123 and email should be rejected locally
      expect(result.rejected.length, 2);
    });

    test('senderIds returns a list', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.senderIds();
      expect(result.result, 'OK');
      expect(result.senderIds, isNotEmpty);
    });

    test('coverage returns prefixes', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.coverage();
      expect(result.result, 'OK');
    });

    test('status with invalid msgId returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.status('invalid_msg_id_12345');
      expect(result.result, 'ERROR');
    });

    test('deliveryReport with invalid msgId returns error', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      final result = await sms.deliveryReport('invalid_msg_id_12345');
      expect(result.result, 'ERROR');
    });

    test('cachedBalance is updated after verify', () async {
      if (!hasCredentials) {
        markTestSkipped('DART_USERNAME / DART_PASSWORD not set');
        return;
      }
      await sms.verify();
      expect(sms.cachedBalance, isNotNull);
    });
  });
}
