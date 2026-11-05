// HTTP request utility for kwtSMS API.
import 'dart:convert';
import 'dart:io';

import 'logger.dart';

/// Base URL for the kwtSMS API.
const String apiBaseUrl = 'https://www.kwtsms.com/API/';

/// Library version, sent in the User-Agent. Must equal `version:` in
/// pubspec.yaml: a unit test and the publish workflow fail when it differs.
// 2026-11-05 14:18 +03: added so kwtSMS can count accounts per integration (#939).
const String kwtsmsVersion = '0.1.12';

/// Build the User-Agent from an optional app token: `[app token ]kwtsms-dart/<version>`.
///
/// The token is caller input, so control characters (CR/LF would split the
/// header) and non-ASCII characters are removed, whitespace runs become '-',
/// leading and trailing '-' are trimmed, and it is cut to 64 characters.
/// Empty gives the library token only.
// 2026-11-05 14:18 +03: added for per-integration counts (#939).
String buildUserAgent([String appName = '']) {
  final kept = appName.runes
      // 2026-11-05 14:19 +03: non-ASCII spaces only above C1, so CR/LF never become '-' (#939).
      .where((r) => (r >= 0x20 && r < 0x7f) || (r > 0x9f && _isSpace(r)))
      .map(String.fromCharCode)
      .join();
  var app =
      kept.replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  if (app.length > 64) {
    app = app.substring(0, 64).replaceAll(RegExp(r'-+$'), '');
  }
  const lib = 'kwtsms-dart/$kwtsmsVersion';
  return app.isEmpty ? lib : '$app $lib';
}

bool _isSpace(int r) => String.fromCharCode(r).trim().isEmpty;

/// Make a POST request to a kwtSMS API endpoint.
///
/// Returns the parsed JSON response as a Map.
/// Throws [HttpException] on network errors.
/// Throws [FormatException] on invalid JSON responses.
Future<Map<String, dynamic>> apiRequest({
  required String endpoint,
  required Map<String, dynamic> payload,
  String logFile = '',
  // 2026-11-05 14:18 +03: User-Agent header; empty sends the library token only (#939).
  String userAgent = '',
}) async {
  final url = Uri.parse('$apiBaseUrl$endpoint/');
  String responseBody = '';
  bool success = false;
  String? errorMsg;

  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    final request = await client.postUrl(url);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    // 2026-11-05 14:18 +03: 'kwtsms-dart/<version>', prefixed by the app token when given (#939).
    request.headers
        .set('User-Agent', userAgent.isEmpty ? buildUserAgent() : userAgent);

    final body = utf8.encode(jsonEncode(payload));
    request.contentLength = body.length;
    request.add(body);

    final response = await request.close().timeout(
          const Duration(seconds: 15),
        );

    responseBody = await response.transform(utf8.decoder).join();
    client.close(force: false);

    // Parse JSON response (read body even on 4xx/5xx)
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      errorMsg = 'Invalid JSON response: $responseBody';
      throw FormatException(errorMsg);
    }

    success = data['result'] == 'OK';
    if (!success) {
      errorMsg = data['description'] as String? ?? 'Unknown error';
    }

    return data;
  } on SocketException catch (e) {
    errorMsg = 'Network error: ${e.message}';
    rethrow;
  } on HttpException catch (e) {
    errorMsg = 'HTTP error: ${e.message}';
    rethrow;
  } catch (e) {
    errorMsg ??= 'Request failed: $e';
    if (e is FormatException || e is SocketException || e is HttpException) {
      rethrow;
    }
    throw HttpException(errorMsg);
  } finally {
    writeLog(
      logFile: logFile,
      endpoint: endpoint,
      request: payload,
      response: responseBody,
      ok: success,
      error: errorMsg,
    );
  }
}
