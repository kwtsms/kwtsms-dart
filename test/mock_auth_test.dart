// FILE:      test/mock_auth_test.dart
// CREATED:   2026-11-07 00:03 +03
// TASK:      neg-auth-tests
// AUTHOR:    M Alhassoun
// WHAT:      Offline test of verify() with wrong credentials: an in-process
//            fake HttpClient answers the balance call with HTTP 403 + ERR003,
//            as the live API does.
// WHY:       2026-11-07 00:03 +03: wrong-credential test mocked; live failed
//            logins trip the security log (task neg-auth-tests). Replaces the
//            live 'verify with wrong credentials fails' integration test.
// USAGE:     dart test test/mock_auth_test.dart
// DEPENDS:   dart:io HttpOverrides, package:test. No credentials, no network.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kwtsms/kwtsms.dart';
import 'package:test/test.dart';

/// HttpClient stand-in: every request gets the ERR003 response below.
class _AuthErrorHttpClient implements HttpClient {
  final List<Uri> urls = [];

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    urls.add(url);
    return _AuthErrorRequest();
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthErrorRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  int contentLength = -1;

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async => _AuthErrorResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AuthErrorResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final _json = jsonEncode({
    'result': 'ERROR',
    'code': 'ERR003',
    'description':
        'Authentication error, username or password are not correct.',
  });

  @override
  int get statusCode => 403;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(utf8.encode(_json)).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('verify with wrong credentials fails (mocked ERR003, offline)',
      () async {
    final fake = _AuthErrorHttpClient();
    final bad = KwtSMS('dart_wrong_user', 'dart_wrong_pass',
        testMode: true, logFile: '');

    final result = await HttpOverrides.runZoned(
      () => bad.verify(),
      createHttpClient: (_) => fake,
    );

    expect(fake.urls.single.path, '/API/balance/');
    expect(result.ok, isFalse);
    expect(result.balance, isNull);
    expect(result.error, contains('KWTSMS_USERNAME'));
  });
}
