// 00_raw_api.dart -- Raw kwtSMS API calls without the client library.
//
// This example calls every kwtSMS API endpoint directly using dart:io
// and dart:convert. No client library, no abstractions. Copy-paste
// any section into your own code.
//
// Run:
//   dart run example/00_raw_api.dart

import 'dart:convert';
import 'dart:io';

// ── Configuration ─────────────────────────────────────────────────────
// Replace these with your real kwtSMS API credentials.
// Get them at: https://www.kwtsms.com/login/ → Account → API

const username = 'dart_username';
const password = 'dart_password';
const senderId = 'KWT-SMS';
const testMode = '1'; // '1' = test (no delivery), '0' = live
const apiBase = 'https://www.kwtsms.com/API';

// ── Helper: POST JSON to a kwtSMS endpoint ────────────────────────────

Future<Map<String, dynamic>> post(
    String endpoint, Map<String, dynamic> body) async {
  final url = Uri.parse('$apiBase/$endpoint/');
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 15);

  final request = await client.postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  request.headers.set('Accept', 'application/json');

  final encoded = utf8.encode(jsonEncode(body));
  request.contentLength = encoded.length;
  request.add(encoded);

  final response = await request.close().timeout(const Duration(seconds: 15));
  final responseBody = await response.transform(utf8.decoder).join();
  client.close(force: false);

  return jsonDecode(responseBody) as Map<String, dynamic>;
}

// ── Main ──────────────────────────────────────────────────────────────

Future<void> main() async {
  print('kwtSMS Raw API Example');
  print('======================\n');

  if (testMode == '1') {
    print('TEST MODE: messages are queued but NOT delivered.\n');
  }

  // ─── 1. Balance ─────────────────────────────────────────────────────
  // Endpoint: POST /API/balance/
  // Returns: { "result": "OK", "available": 150, "purchased": 500 }
  //
  // Use this to verify credentials and check your credit balance.

  print('--- 1. Balance ---');
  final balanceResponse = await post('balance', {
    'username': username,
    'password': password,
  });
  print('Response: ${jsonEncode(balanceResponse)}');

  if (balanceResponse['result'] == 'OK') {
    print('Available: ${balanceResponse['available']} credits');
    print('Purchased: ${balanceResponse['purchased']} credits');
  } else {
    print('ERROR: ${balanceResponse['description']}');
    print('Check your username and password.');
    return;
  }

  // ─── 2. Sender IDs ─────────────────────────────────────────────────
  // Endpoint: POST /API/senderid/
  // Returns: { "result": "OK", "senderid": ["KWT-SMS", "MY-APP"] }
  //
  // Lists all sender IDs registered on your account.

  print('\n--- 2. Sender IDs ---');
  final senderIdResponse = await post('senderid', {
    'username': username,
    'password': password,
  });
  print('Response: ${jsonEncode(senderIdResponse)}');

  if (senderIdResponse['result'] == 'OK') {
    final ids = senderIdResponse['senderid'] as List;
    print('Your sender IDs: ${ids.join(", ")}');
  } else {
    print('ERROR: ${senderIdResponse['description']}');
  }

  // ─── 3. Coverage ────────────────────────────────────────────────────
  // Endpoint: POST /API/coverage/
  // Returns: { "result": "OK", "coverage": [ {"prefix": "965", ...}, ... ] }
  //
  // Lists which country prefixes are active for SMS delivery on your
  // account. International sending is disabled by default.

  print('\n--- 3. Coverage ---');
  final coverageResponse = await post('coverage', {
    'username': username,
    'password': password,
  });

  if (coverageResponse['result'] == 'OK') {
    final coverage = coverageResponse['coverage'];
    if (coverage is List) {
      print('Active country prefixes (${coverage.length}):');
      for (final item in coverage.take(10)) {
        if (item is Map) {
          print('  +${item['prefix'] ?? item['Prefix']}');
        } else {
          print('  +$item');
        }
      }
      if (coverage.length > 10) {
        print('  ... and ${coverage.length - 10} more');
      }
    }
  } else {
    print('ERROR: ${coverageResponse['description']}');
  }

  // ─── 4. Validate ────────────────────────────────────────────────────
  // Endpoint: POST /API/validate/
  // Body:     { "username", "password", "mobile": "965XXXXXXXX,123456789" }
  // Returns:  { "result": "OK", "mobile": { "OK": [...], "ER": [...], "NR": [...] } }
  //
  // OK = valid and routable
  // ER = format error (invalid number)
  // NR = no route (country not activated on your account)

  print('\n--- 4. Validate Numbers ---');
  final validateResponse = await post('validate', {
    'username': username,
    'password': password,
    'mobile': '965XXXXXXXX,123456789,44712345678',
  });
  print('Response: ${jsonEncode(validateResponse)}');

  if (validateResponse['result'] == 'OK') {
    final mobile = validateResponse['mobile'] as Map<String, dynamic>;
    print('Valid    (OK): ${mobile['OK'] ?? []}');
    print('Invalid  (ER): ${mobile['ER'] ?? []}');
    print('No route (NR): ${mobile['NR'] ?? []}');
  } else {
    print('ERROR: ${validateResponse['description']}');
  }

  // ─── 5. Send SMS ────────────────────────────────────────────────────
  // Endpoint: POST /API/send/
  // Body:     { "username", "password", "sender", "mobile", "message", "test" }
  // Returns:  { "result": "OK", "msg-id": "abc123", "numbers": 1,
  //             "points-charged": 1, "balance-after": 149 }
  //
  // Important:
  //   - Always POST (never GET: GET leaks credentials in server logs)
  //   - Always set Content-Type: application/json
  //   - Phone numbers must include the country code (e.g., 965XXXXXXXX)
  //   - Multiple numbers: comma-separated, max 200 per request
  //   - Save msg-id immediately: you need it for status/delivery reports
  //   - "test": "1" queues the message but does NOT deliver it

  print('\n--- 5. Send SMS ---');
  final sendResponse = await post('send', {
    'username': username,
    'password': password,
    'sender': senderId,
    'mobile': '965XXXXXXXX',
    'message': 'Hello from raw Dart API example!',
    'test': testMode,
  });
  print('Response: ${jsonEncode(sendResponse)}');

  String? msgId;
  if (sendResponse['result'] == 'OK') {
    msgId = sendResponse['msg-id'] as String?;
    print('Sent! msg-id: $msgId');
    print('Numbers: ${sendResponse['numbers']}');
    print('Points charged: ${sendResponse['points-charged']}');
    print('Balance after: ${sendResponse['balance-after']}');
  } else {
    print('ERROR: ${sendResponse['code']} -- ${sendResponse['description']}');
  }

  // ─── 6. Send to Multiple Numbers ────────────────────────────────────
  // Same endpoint, just comma-separate the numbers.
  // Max 200 per request. For more, split into batches yourself.

  print('\n--- 6. Send to Multiple Numbers ---');
  final multiSendResponse = await post('send', {
    'username': username,
    'password': password,
    'sender': senderId,
    'mobile': '965XXXXXXXX,96512345678',
    'message': 'Hello to two numbers!',
    'test': testMode,
  });
  print('Response: ${jsonEncode(multiSendResponse)}');

  if (multiSendResponse['result'] == 'OK') {
    print('Sent to ${multiSendResponse['numbers']} numbers');
    print('Points charged: ${multiSendResponse['points-charged']}');
    // Save this msg-id too!
    msgId ??= multiSendResponse['msg-id'] as String?;
  } else {
    print(
        'ERROR: ${multiSendResponse['code']} -- ${multiSendResponse['description']}');
  }

  // ─── 7. Message Status ──────────────────────────────────────────────
  // Endpoint: POST /API/status/
  // Body:     { "username", "password", "msgid": "<msg-id from send>" }
  // Returns:  { "result": "OK", "status": "Delivered", "description": "..." }
  //
  // Note: test-mode messages return ERR030 (stuck in queue). This is normal.

  print('\n--- 7. Message Status ---');
  if (msgId != null) {
    final statusResponse = await post('status', {
      'username': username,
      'password': password,
      'msgid': msgId,
    });
    print('Response: ${jsonEncode(statusResponse)}');

    if (statusResponse['result'] == 'OK') {
      print('Status: ${statusResponse['status']}');
      print('Description: ${statusResponse['description']}');
    } else {
      print('Code: ${statusResponse['code']}');
      print('Description: ${statusResponse['description']}');
      if (statusResponse['code'] == 'ERR030') {
        print('(This is normal for test-mode messages)');
      }
    }
  } else {
    print('No msg-id available (send did not succeed).');
  }

  // ─── 8. Delivery Report (DLR) ──────────────────────────────────────
  // Endpoint: POST /API/dlr/
  // Body:     { "username", "password", "msgid": "<msg-id from send>" }
  // Returns:  { "result": "OK", "report": [ {"Number": "965...", "Status": "Delivered"} ] }
  //
  // Only works for international numbers. Kuwait numbers do not support DLR.
  // Wait at least 5 minutes after sending before checking.

  print('\n--- 8. Delivery Report ---');
  if (msgId != null) {
    final dlrResponse = await post('dlr', {
      'username': username,
      'password': password,
      'msgid': msgId,
    });
    print('Response: ${jsonEncode(dlrResponse)}');

    if (dlrResponse['result'] == 'OK') {
      final report = dlrResponse['report'] as List?;
      if (report != null) {
        for (final entry in report) {
          print('  ${entry['Number']}: ${entry['Status']}');
        }
      }
    } else {
      print('Code: ${dlrResponse['code']}');
      print('Description: ${dlrResponse['description']}');
    }
  } else {
    print('No msg-id available (send did not succeed).');
  }

  // ─── Summary ────────────────────────────────────────────────────────
  print('\n--- Summary ---');
  print('API base URL:  $apiBase');
  print('Method:        POST (always, never GET)');
  print('Content-Type:  application/json');
  print('Auth:          username + password in every request body');
  print('Phone format:  country code + number (e.g., 965XXXXXXXX)');
  print('Test mode:     "test": "1" in send body');
  print('');
  print('Endpoints:');
  print('  POST /API/balance/   : Check credits');
  print('  POST /API/senderid/  : List sender IDs');
  print('  POST /API/coverage/  : List active country prefixes');
  print('  POST /API/validate/  : Validate phone numbers');
  print('  POST /API/send/      : Send SMS');
  print('  POST /API/status/    : Check message delivery status');
  print('  POST /API/dlr/       : Get delivery report (international only)');

  print('\nDone.');
}
