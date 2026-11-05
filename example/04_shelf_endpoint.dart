// 04_shelf_endpoint.dart -- Shelf web server with a POST /send-sms endpoint.
//
// Demonstrates: how to wire kwtSMS into a Dart HTTP server using Shelf.
//
// NOTE: This example requires the `shelf` and `shelf_io` packages.
//   Add to pubspec.yaml:
//     dependencies:
//       shelf: ^1.4.0
//       shelf_io: ^1.1.0   (or use shelf_io from the shelf package)
//
// Run:
//   KWTSMS_TEST_MODE=1 dart run example/04_shelf_endpoint.dart
//
// Test with curl:
//   curl -X POST http://localhost:8080/send-sms \
//     -H "Content-Type: application/json" \
//     -d '{"to": "965XXXXXXXX", "message": "Hello from Shelf!"}'

import 'dart:io';

import 'package:kwtsms/kwtsms.dart';

// NOTE: In a real project, uncomment these imports after adding shelf to
// your pubspec.yaml. This file shows the code pattern; it will not compile
// without the shelf dependency.
//
// import 'package:shelf/shelf.dart';
// import 'package:shelf_io/shelf_io.dart' as shelf_io;

// -- Handler --

/// Creates a Shelf handler that sends SMS via POST /send-sms.
///
/// Request body (JSON):
///   { "to": "965XXXXXXXX", "message": "Hello" }
///
/// Response (JSON):
///   { "ok": true, "msgId": "...", "pointsCharged": 1 }
///   { "ok": false, "error": "..." }

/* -- Uncomment this block when shelf is available --

Response Function(Request) makeSmsHandler(KwtSMS sms) {
  return (Request request) async {
    // Only accept POST.
    if (request.method != 'POST') {
      return Response(405, body: '{"error": "Method not allowed"}');
    }

    // Parse body.
    final body = await request.readAsString();
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: '{"error": "Invalid JSON"}',
          headers: {'Content-Type': 'application/json'});
    }

    final to = payload['to'] as String?;
    final message = payload['message'] as String?;

    if (to == null || to.isEmpty) {
      return Response(400,
          body: '{"error": "Missing field: to"}',
          headers: {'Content-Type': 'application/json'});
    }
    if (message == null || message.isEmpty) {
      return Response(400,
          body: '{"error": "Missing field: message"}',
          headers: {'Content-Type': 'application/json'});
    }

    // Send SMS.
    final result = await sms.send(to, message);

    if (result.result == 'OK') {
      final json = jsonEncode({
        'ok': true,
        'msgId': result.msgId,
        'pointsCharged': result.pointsCharged,
        'balanceAfter': result.balanceAfter,
      });
      return Response.ok(json,
          headers: {'Content-Type': 'application/json'});
    }

    // Error response.
    final json = jsonEncode({
      'ok': false,
      'error': result.action ?? result.description ?? 'Unknown error',
      'code': result.code,
    });
    return Response(502,
        body: json, headers: {'Content-Type': 'application/json'});
  };
}

-- End uncomment block -- */

Future<void> main() async {
  final sms = KwtSMS.fromEnv();

  if (sms.testMode) {
    print('[TEST MODE] Messages are queued but NOT delivered.\n');
  }

  // Verify credentials before starting the server.
  final verify = await sms.verify();
  if (!verify.ok) {
    print('kwtSMS credential check failed: ${verify.error}');
    exit(1);
  }
  print('kwtSMS credentials verified. Balance: ${verify.balance}');

  // -- Start server --
  // Uncomment the following lines when shelf is available:
  //
  // final handler = makeSmsHandler(sms);
  // final server = await shelf_io.serve(handler, 'localhost', 8080);
  // print('Listening on http://${server.address.host}:${server.port}');
  // print('POST /send-sms with {"to": "965XXXXXXXX", "message": "Hello"}');

  // Placeholder: show the pattern without shelf dependency.
  print('\nThis example shows the Shelf handler pattern.');
  print('To run it, add shelf to your pubspec.yaml and uncomment the code.');
  print('See the comments in the source for details.');
}
