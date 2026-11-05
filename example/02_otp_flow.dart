// 02_otp_flow.dart -- One-time password (OTP) flow.
//
// Demonstrates: validate a phone number, generate an OTP code,
// send it via SMS, and track the message ID.
//
// This is a simplified example. For production OTP with rate limiting,
// hashing, and attestation, see example/06_otp_production/.
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/02_otp_flow.dart

import 'dart:math';

import 'package:kwtsms/kwtsms.dart';

/// Generate a random numeric OTP code of the given length.
String generateOtp({int length = 6}) {
  final rng = Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < length; i++) {
    buf.write(rng.nextInt(10)); // 0-9
  }
  return buf.toString();
}

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  // The phone number to send the OTP to.
  const phone = '965XXXXXXXX'; // Replace with a real number.

  // -- 1. Validate the phone number --
  print('--- Validate phone ---');
  final (valid, error, normalized) = validatePhoneInput(phone);
  if (!valid) {
    print('Invalid phone number: $error');
    return;
  }
  print('Normalized number: $normalized');

  // Optionally validate with the API (checks carrier status).
  final validation = await sms.validate([phone]);
  if (validation.ok.contains(normalized)) {
    print('Phone $normalized is active (carrier confirmed).');
  } else if (validation.er.contains(normalized)) {
    print('Warning: phone $normalized may be inactive (carrier error).');
  } else if (validation.nr.contains(normalized)) {
    print('Warning: phone $normalized has no carrier response.');
  }

  // -- 2. Generate OTP --
  print('\n--- Generate OTP ---');
  final code = generateOtp();
  print('Generated OTP: $code');
  // In production, hash the code before storing. See 06_otp_production.

  // -- 3. Send OTP via SMS --
  print('\n--- Send OTP ---');
  final message = 'Your verification code is: $code\nValid for 5 minutes.';
  final result = await sms.send(normalized, message);

  if (result.result == 'OK') {
    print('OTP sent successfully.');
    print('msg-id: ${result.msgId}');
    print('Points charged: ${result.pointsCharged}');

    // -- 4. Track delivery status --
    if (result.msgId != null) {
      print('\n--- Check delivery status ---');
      // In practice, wait a few seconds before checking.
      final status = await sms.status(result.msgId!);
      print('Status: ${status.status ?? "pending"}');
      if (status.statusDescription != null) {
        print('Detail: ${status.statusDescription}');
      }
    }
  } else {
    print('Failed to send OTP: ${result.code} -- ${result.description}');
    if (result.action != null) {
      print('Action: ${result.action}');
    }
  }

  print('\nDone.');
}
