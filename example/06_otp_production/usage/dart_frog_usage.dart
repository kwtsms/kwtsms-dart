// dart_frog_usage.dart -- Wiring the OTP service into a Dart Frog server.
//
// Dart Frog is a server framework by Very Good Ventures.
// https://dartfrog.vgv.dev/
//
// NOTE: This file shows the integration pattern. In a real Dart Frog project,
// these would live in the routes/ directory with the proper file structure.
//
// Project structure:
//   routes/
//     otp/
//       send.dart      -> POST /otp/send
//       verify.dart    -> POST /otp/verify
//   lib/
//     otp_service.dart -> OtpService (copy from this example)
//   main.dart          -> provider setup
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/06_otp_production/usage/dart_frog_usage.dart

import 'dart:io';

import 'package:kwtsms/kwtsms.dart';

import '../adapters/memory_store.dart';
import '../otp_service.dart';

// In a real Dart Frog project, you would import:
// import 'package:dart_frog/dart_frog.dart';

// ---------------------------------------------------------------------------
// Provider setup (main.dart in Dart Frog)
// ---------------------------------------------------------------------------

// In Dart Frog, you register providers in main.dart:
//
//   import 'package:dart_frog/dart_frog.dart';
//   import 'package:kwtsms/kwtsms.dart';
//   import 'otp_service.dart';
//   import 'memory_store.dart';
//
//   Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
//     final sms = KwtSMS.fromEnv();
//     final store = MemoryOtpStore();
//     final otpService = OtpService(sms: sms, store: store);
//
//     return serve(
//       handler.use(provider<OtpService>((_) => otpService)),
//       ip,
//       port,
//     );
//   }

// ---------------------------------------------------------------------------
// Route: POST /otp/send (routes/otp/send.dart)
// ---------------------------------------------------------------------------

// In Dart Frog, each route file exports an onRequest function.
//
// Example routes/otp/send.dart:
//
//   import 'dart:convert';
//   import 'package:dart_frog/dart_frog.dart';
//   import '../../lib/otp_service.dart';
//
//   Future<Response> onRequest(RequestContext context) async {
//     if (context.request.method != HttpMethod.post) {
//       return Response(statusCode: 405);
//     }
//
//     final otp = context.read<OtpService>();
//     final body = await context.request.body();
//     final payload = jsonDecode(body) as Map<String, dynamic>;
//     final phone = payload['phone'] as String?;
//
//     if (phone == null || phone.isEmpty) {
//       return Response.json(
//         statusCode: 400,
//         body: {'ok': false, 'error': 'Missing field: phone'},
//       );
//     }
//
//     final attestToken = context.request.headers['X-Attestation-Token'];
//     final ip = context.request.headers['X-Forwarded-For'];
//
//     final result = await otp.sendOtp(
//       phone,
//       attestationToken: attestToken,
//       ip: ip,
//     );
//
//     if (result.ok) {
//       return Response.json(body: {'ok': true, 'message': 'OTP sent.'});
//     }
//
//     return Response.json(
//       statusCode: result.retryAfterSeconds != null ? 429 : 400,
//       body: {'ok': false, 'error': result.error},
//     );
//   }

// ---------------------------------------------------------------------------
// Route: POST /otp/verify (routes/otp/verify.dart)
// ---------------------------------------------------------------------------

// Example routes/otp/verify.dart:
//
//   import 'dart:convert';
//   import 'package:dart_frog/dart_frog.dart';
//   import '../../lib/otp_service.dart';
//
//   Future<Response> onRequest(RequestContext context) async {
//     if (context.request.method != HttpMethod.post) {
//       return Response(statusCode: 405);
//     }
//
//     final otp = context.read<OtpService>();
//     final body = await context.request.body();
//     final payload = jsonDecode(body) as Map<String, dynamic>;
//     final phone = payload['phone'] as String?;
//     final code = payload['code'] as String?;
//
//     if (phone == null || code == null) {
//       return Response.json(
//         statusCode: 400,
//         body: {'ok': false, 'error': 'Missing fields: phone, code'},
//       );
//     }
//
//     final ip = context.request.headers['X-Forwarded-For'];
//     final result = await otp.verifyOtp(phone, code, ip: ip);
//
//     if (result.ok) {
//       // Issue a session token or JWT here.
//       return Response.json(body: {'ok': true, 'message': 'Phone verified.'});
//     }
//
//     return Response.json(
//       statusCode: 400,
//       body: {
//         'ok': false,
//         'error': result.error,
//         if (result.remainingAttempts != null)
//           'remainingAttempts': result.remainingAttempts,
//       },
//     );
//   }

// ---------------------------------------------------------------------------
// Runnable demo
// ---------------------------------------------------------------------------

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  final store = MemoryOtpStore();
  final otpService = OtpService(sms: sms, store: store);

  // Verify credentials.
  final verify = await sms.verify();
  if (!verify.ok) {
    print('kwtSMS credential check failed: ${verify.error}');
    exit(1);
  }
  print('kwtSMS credentials verified. Balance: ${verify.balance}');

  print('\nThis file shows the Dart Frog integration pattern.');
  print('See the comments above for the route file structure.');
  print('');
  print('Dart Frog project setup:');
  print('  dart pub global activate dart_frog_cli');
  print('  dart_frog create my_otp_server');
  print('  cd my_otp_server');
  print('  dart pub add kwtsms');
  print('  # Copy otp_service.dart and memory_store.dart into lib/');
  print('  # Create routes/otp/send.dart and routes/otp/verify.dart');
  print('  dart_frog dev');

  // Quick demo.
  print('\n--- Direct OTP demo ---');
  final sendResult = await otpService.sendOtp('965XXXXXXXX');
  print('sendOtp result: ok=${sendResult.ok}, error=${sendResult.error}');
}
