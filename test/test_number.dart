// FILE:      test/test_number.dart
// CREATED:   2026-11-05 08:16 +03
// TASK:      int-testnumber (Boss 2026-11-05 00:33)
// AUTHOR:    M Alhassoun
// WHAT:      Shared test helper: the test phone number and its format variants.
// WHY:       Tests must not hardcode a phone number. The number comes from the
//            KWTSMS_TEST_NUMBER environment variable (an international Kuwait
//            mobile, digits only, 965XXXXXXXX) and every test that needs one
//            is skipped when it is unset or malformed.
// USAGE:     KWTSMS_TEST_NUMBER=965XXXXXXXX dart test --exclude-tags=integration
//            CI reads it from the repository secret of the same name.
//            Unit tests: test(..., skip: testNumberSkip) and testNumber().
//            Live tests: final n = testNumberOrSkip(); if (n == null) return;
//            Never print or log the returned value.
// DEPENDS:   dart:io, package:test. Not a *_test.dart file, so the runner
//            does not load it on its own.

import 'dart:io';

import 'package:test/test.dart';

/// For values only passed through unchanged (for example a number echoed
/// back in a mocked API response).
const String testNumberPlaceholder = '965XXXXXXXX';

const String _skipReason =
    'KWTSMS_TEST_NUMBER not set (digits only, 965 plus 8 digits)';

final String? _envTestNumber = () {
  final n = (Platform.environment['KWTSMS_TEST_NUMBER'] ?? '').trim();
  return RegExp(r'^965[0-9]{8}$').hasMatch(n) ? n : null;
}();

/// Pass as `skip:` to a test that needs the number: null when it is set,
/// otherwise the skip reason.
final String? testNumberSkip = _envTestNumber == null ? _skipReason : null;

/// KWTSMS_TEST_NUMBER (965 plus 8 digits). Only call it inside a test
/// declared with `skip: testNumberSkip`.
String testNumber() {
  final n = _envTestNumber;
  if (n == null) throw StateError(_skipReason);
  return n;
}

/// KWTSMS_TEST_NUMBER, or null after marking the running test skipped.
String? testNumberOrSkip() {
  if (_envTestNumber == null) markTestSkipped(_skipReason);
  return _envTestNumber;
}

String _shiftDigits(String s, int zero) => String.fromCharCodes(
    s.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? zero + (c - 0x30) : c));

/// Latin digits to Arabic-Indic (U+0660-0669).
String toArabicIndic(String s) => _shiftDigits(s, 0x0660);

/// Latin digits to Extended Arabic-Indic / Persian (U+06F0-06F9).
String toPersian(String s) => _shiftDigits(s, 0x06F0);

/// Split 965XXXXXXXX into country code, first 4 and last 4 local digits.
(String, String, String) splitKw(String n) =>
    (n.substring(0, 3), n.substring(3, 7), n.substring(7));

/// Expect equality without printing either value (they may hold the number).
void expectSameNumber(Object? actual, String expected) {
  expect(actual == expected, isTrue,
      reason: 'phone number does not match the expected value (values hidden)');
}
