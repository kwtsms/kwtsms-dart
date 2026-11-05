// 01_basic_usage.dart -- Basic kwtSMS operations.
//
// Demonstrates: verify credentials, check balance, send SMS,
// list sender IDs, and check coverage.
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/01_basic_usage.dart

import 'package:kwtsms/kwtsms.dart';

Future<void> main() async {
  // Load credentials from environment / .env file.
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  // -- 1. Verify credentials --
  print('--- Verify credentials ---');
  final verify = await sms.verify();
  if (!verify.ok) {
    print('Credential check failed: ${verify.error}');
    return; // No point continuing with bad credentials.
  }
  print('Credentials OK. Balance: ${verify.balance} credits.');

  // -- 2. Check balance --
  print('\n--- Check balance ---');
  final balance = await sms.balance();
  print('Available balance: $balance credits.');

  // -- 3. Send SMS to a single number --
  print('\n--- Send SMS ---');
  final result = await sms.send(
    '965XXXXXXXX', // Replace with a real Kuwait number.
    'Hello from kwtSMS Dart client!',
  );

  if (result.result == 'OK') {
    print('Sent! msg-id: ${result.msgId}');
    print('Numbers reached: ${result.numbers}');
    print('Points charged: ${result.pointsCharged}');
    print('Balance after: ${result.balanceAfter}');
  } else {
    print('Send failed: ${result.code} -- ${result.description}');
    if (result.action != null) print('Action: ${result.action}');
  }

  // Report any locally-rejected numbers.
  if (result.invalid.isNotEmpty) {
    print('Invalid numbers:');
    for (final inv in result.invalid) {
      print('  ${inv.input}: ${inv.error}');
    }
  }

  // -- 4. List sender IDs --
  print('\n--- Sender IDs ---');
  final senders = await sms.senderIds();
  if (senders.result == 'OK') {
    print('Available sender IDs: ${senders.senderIds.join(", ")}');
  } else {
    print('Could not list sender IDs: ${senders.description}');
  }

  // -- 5. Check coverage --
  print('\n--- Coverage ---');
  final cov = await sms.coverage();
  if (cov.result == 'OK') {
    print('Active prefixes (${cov.prefixes.length}):');
    // Print first 10 as a preview.
    for (final prefix in cov.prefixes.take(10)) {
      print('  $prefix');
    }
    if (cov.prefixes.length > 10) {
      print('  ... and ${cov.prefixes.length - 10} more.');
    }
  } else {
    print('Could not fetch coverage: ${cov.description}');
  }

  print('\nDone.');
}
