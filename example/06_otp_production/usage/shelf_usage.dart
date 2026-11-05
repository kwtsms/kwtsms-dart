// shelf_usage.dart -- Wiring the OTP service into a Shelf HTTP server.
//
// NOTE: Requires the `shelf` package. Add to pubspec.yaml:
//   dependencies:
//     shelf: ^1.4.0
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/06_otp_production/usage/shelf_usage.dart
//
// Endpoints:
//   POST /otp/send    {"phone": "965XXXXXXXX"}
//   POST /otp/verify  {"phone": "965XXXXXXXX", "code": "123456"}

import 'dart:io';

import 'package:kwtsms/kwtsms.dart';

import '../adapters/memory_store.dart';
import '../otp_service.dart';

// Uncomment when shelf is available:
// import 'package:shelf/shelf.dart';
// import 'package:shelf_io/shelf_io.dart' as shelf_io;

/* -- Uncomment this block when shelf is available --

/// Build a Shelf handler with OTP send and verify routes.
Handler makeOtpHandler(OtpService otpService) {
  return (Request request) async {
    final path = request.url.path;

    // POST /otp/send
    if (path == 'otp/send' && request.method == 'POST') {
      return _handleSendOtp(request, otpService);
    }

    // POST /otp/verify
    if (path == 'otp/verify' && request.method == 'POST') {
      return _handleVerifyOtp(request, otpService);
    }

    return Response.notFound('{"error": "Not found"}');
  };
}

Future<Response> _handleSendOtp(Request request, OtpService otp) async {
  final body = await request.readAsString();
  final Map<String, dynamic> payload;
  try {
    payload = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return Response(400,
        body: '{"error": "Invalid JSON"}',
        headers: {'Content-Type': 'application/json'});
  }

  final phone = payload['phone'] as String?;
  if (phone == null || phone.isEmpty) {
    return Response(400,
        body: '{"error": "Missing field: phone"}',
        headers: {'Content-Type': 'application/json'});
  }

  // Extract optional attestation token from header.
  final attestToken = request.headers['X-Attestation-Token'];

  // Extract client IP (behind reverse proxy, check X-Forwarded-For).
  final ip = request.headers['X-Forwarded-For'] ??
      request.headers['X-Real-IP'];

  final result = await otp.sendOtp(
    phone,
    attestationToken: attestToken,
    ip: ip,
  );

  if (result.ok) {
    return Response.ok(
        jsonEncode({'ok': true, 'message': 'OTP sent.'}),
        headers: {'Content-Type': 'application/json'});
  }

  // Do not reveal msg-id or internal details to the client.
  final status = result.retryAfterSeconds != null ? 429 : 400;
  return Response(status,
      body: jsonEncode({'ok': false, 'error': result.error}),
      headers: {
        'Content-Type': 'application/json',
        if (result.retryAfterSeconds != null)
          'Retry-After': '${result.retryAfterSeconds}',
      });
}

Future<Response> _handleVerifyOtp(Request request, OtpService otp) async {
  final body = await request.readAsString();
  final Map<String, dynamic> payload;
  try {
    payload = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return Response(400,
        body: '{"error": "Invalid JSON"}',
        headers: {'Content-Type': 'application/json'});
  }

  final phone = payload['phone'] as String?;
  final code = payload['code'] as String?;

  if (phone == null || phone.isEmpty || code == null || code.isEmpty) {
    return Response(400,
        body: '{"error": "Missing fields: phone, code"}',
        headers: {'Content-Type': 'application/json'});
  }

  final ip = request.headers['X-Forwarded-For'] ??
      request.headers['X-Real-IP'];

  final result = await otp.verifyOtp(phone, code, ip: ip);

  if (result.ok) {
    // In production, issue a session token or JWT here.
    return Response.ok(
        jsonEncode({'ok': true, 'message': 'Phone verified.'}),
        headers: {'Content-Type': 'application/json'});
  }

  return Response(400,
      body: jsonEncode({
        'ok': false,
        'error': result.error,
        if (result.remainingAttempts != null)
          'remainingAttempts': result.remainingAttempts,
      }),
      headers: {'Content-Type': 'application/json'});
}

-- End uncomment block -- */

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  final store = MemoryOtpStore();

  final otpService = OtpService(
    sms: sms,
    store: store,
    config: const OtpConfig(
      codeLength: 6,
      ttlSeconds: 300,
      maxAttempts: 3,
      rateLimitMaxSends: 5,
      rateLimitWindowSeconds: 3600,
    ),
  );

  // Verify credentials before starting.
  final verify = await sms.verify();
  if (!verify.ok) {
    print('kwtSMS credential check failed: ${verify.error}');
    exit(1);
  }
  print('kwtSMS credentials verified. Balance: ${verify.balance}');

  // Uncomment when shelf is available:
  // final handler = makeOtpHandler(otpService);
  // final server = await shelf_io.serve(handler, 'localhost', 8080);
  // print('OTP server listening on http://${server.address.host}:${server.port}');
  // print('POST /otp/send    {"phone": "965XXXXXXXX"}');
  // print('POST /otp/verify  {"phone": "965XXXXXXXX", "code": "123456"}');

  print('\nThis example shows the Shelf + OTP wiring pattern.');
  print('Add shelf to your pubspec.yaml and uncomment the code to run.');

  // Quick demo of the OTP service directly.
  print('\n--- Direct OTP demo ---');
  final sendResult = await otpService.sendOtp('965XXXXXXXX');
  print('sendOtp result: ok=${sendResult.ok}, error=${sendResult.error}');
}
