// 05_error_handling.dart -- Handling all kwtSMS error cases.
//
// Demonstrates: distinguishing user-facing errors from admin errors,
// handling network failures, invalid input, API errors, and edge cases.
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/05_error_handling.dart

import 'dart:io';

import 'package:kwtsms/kwtsms.dart';

/// Classify an error code as user-facing or admin/ops.
///
/// User-facing errors can be shown to end users (e.g., "invalid number").
/// Admin errors require developer or account-owner action.
String classifyError(String? code) {
  // Errors safe to show to end users.
  const userFacing = {
    'ERR006', // No valid phone numbers
    'ERR009', // Empty message
    'ERR012', // Message too long
    'ERR025', // Invalid phone number
    'ERR028', // Sent to the same number too soon (opt-in duplicate SMS window). 2026-10-22 15:38 +03: no fixed 15 s
  };

  // Errors that require admin / ops intervention.
  const adminOnly = {
    'ERR001', // API disabled on account
    'ERR002', // Missing parameter (bug)
    'ERR003', // Wrong credentials
    'ERR004', // No API access
    'ERR005', // Account blocked
    'ERR008', // Sender ID banned
    'ERR010', // Zero balance
    'ERR011', // Insufficient balance
    'ERR013', // Queue full (transient)
    'ERR024', // IP not whitelisted
    'ERR026', // Country not activated
    'ERR027', // HTML in message
    'ERR031', // Bad language
    'ERR032', // Spam detected
    'ERR033', // No coverage
  };

  if (code == null) return 'unknown';
  if (userFacing.contains(code)) return 'user';
  if (adminOnly.contains(code)) return 'admin';
  return 'unknown';
}

/// Return a safe message for end users. Never expose internal details.
String userMessage(SendResult result) {
  final kind = classifyError(result.code);

  if (result.result == 'OK') return 'Message sent successfully.';

  switch (kind) {
    case 'user':
      // These errors are safe to show.
      return result.action ?? result.description ?? 'Invalid request.';
    case 'admin':
      // Do not expose internal API details to end users.
      return 'SMS service is temporarily unavailable. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

/// Log the full error details for the ops team.
void logAdminError(String operation,
    {String? code, String? desc, String? action}) {
  // In production, send this to your logging pipeline (Sentry, CloudWatch, etc.).
  stderr.writeln('[ADMIN] $operation failed:');
  stderr.writeln('  code:        $code');
  stderr.writeln('  description: $desc');
  stderr.writeln('  action:      $action');
}

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  // -- 1. Credential errors --
  print('=== 1. Credential verification ===');
  final verify = await sms.verify();
  if (!verify.ok) {
    // This is always an admin error -- never expose to end users.
    logAdminError('verify', desc: verify.error);
    print('User sees: "SMS service is temporarily unavailable."');
    // Decide whether to continue or abort based on your use case.
  } else {
    print('Credentials OK. Balance: ${verify.balance}');
  }

  // -- 2. Invalid phone number (user error) --
  print('\n=== 2. Invalid phone number ===');
  final badResult = await sms.send('not-a-number', 'Hello');
  print('Result: ${badResult.result}');
  print('User sees: ${userMessage(badResult)}');
  if (badResult.invalid.isNotEmpty) {
    print('Invalid entries:');
    for (final inv in badResult.invalid) {
      print('  "${inv.input}": ${inv.error}');
    }
  }

  // -- 3. Empty message (user error) --
  print('\n=== 3. Empty message ===');
  final emptyResult = await sms.send('965XXXXXXXX', '');
  print('Result: ${emptyResult.result}');
  print('User sees: ${userMessage(emptyResult)}');

  // -- 4. Successful send --
  print('\n=== 4. Successful send ===');
  final okResult = await sms.send('965XXXXXXXX', 'Test message');
  print('Result: ${okResult.result}');
  print('User sees: ${userMessage(okResult)}');
  if (okResult.result == 'OK') {
    print('msg-id: ${okResult.msgId}');
  } else {
    // Log for admin if it was an admin-level error.
    final kind = classifyError(okResult.code);
    if (kind == 'admin') {
      logAdminError('send',
          code: okResult.code,
          desc: okResult.description,
          action: okResult.action);
    }
  }

  // -- 5. Mixed valid and invalid numbers --
  print('\n=== 5. Mixed valid/invalid numbers ===');
  final mixedResult = await sms.send(
    '965XXXXXXXX, bad, @email.com',
    'Hello everyone',
  );
  print('Result: ${mixedResult.result}');
  if (mixedResult.invalid.isNotEmpty) {
    print('Rejected locally (${mixedResult.invalid.length}):');
    for (final inv in mixedResult.invalid) {
      print('  "${inv.input}": ${inv.error}');
    }
  }
  // Valid numbers may still have been sent.
  if (mixedResult.msgId != null) {
    print('Sent to valid numbers. msg-id: ${mixedResult.msgId}');
  }

  // -- 6. Status check with bad msg-id --
  print('\n=== 6. Invalid msg-id ===');
  final statusResult = await sms.status('nonexistent-id');
  print('Result: ${statusResult.result}');
  if (statusResult.result != 'OK') {
    // ERR020 or ERR029 -- admin should know, user just sees "not found".
    final kind = classifyError(statusResult.code);
    if (kind == 'admin') {
      logAdminError('status',
          code: statusResult.code,
          desc: statusResult.description,
          action: statusResult.action);
    }
    print('User sees: "Message status not available."');
  }

  // -- 7. Using the enriched error map --
  print('\n=== 7. Error code lookup ===');
  // You can look up any error code directly.
  for (final code in ['ERR003', 'ERR010', 'ERR028']) {
    final action = apiErrors[code];
    print('$code -> $action');
  }

  print('\nDone.');
}
