// FILE:      test/user_agent_test.dart
// CREATED:   2026-11-05 14:18 +03
// TASK:      #939 (int-measure-signups)
// AUTHOR:    M Alhassoun
// WHAT:      Unit tests for the User-Agent the client sends.
// WHY:       kwtSMS counts accounts per integration from the User-Agent; it
//            must be kwtsms-dart/<pubspec version> and a caller's app token
//            must never inject headers.
// USAGE:     dart test test/user_agent_test.dart
// DEPENDS:   dart:io HttpOverrides, package:test. No network, no credentials.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kwtsms/kwtsms.dart';
import 'package:test/test.dart';

/// HttpClient stand-in that records the User-Agent header of each request.
class _FakeHttpClient implements HttpClient {
  final sent = <String>[];

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeRequest(this);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this._client);
  final _FakeHttpClient _client;

  @override
  late final HttpHeaders headers = _FakeHeaders(_client);

  @override
  int contentLength = -1;

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async =>
      _FakeResponse('{"result":"OK","available":1,"purchased":1}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  _FakeHeaders(this._client);
  final _FakeHttpClient _client;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    if (name.toLowerCase() == 'user-agent') _client.sent.add('$value');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this._json);
  final String _json;

  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(utf8.encode(_json)).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('version equals pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    expect(KwtSMS.version, line.substring('version:'.length).trim());
    expect(kwtsmsVersion, KwtSMS.version);
  });

  test('default User-Agent is the library token', () {
    final sms = KwtSMS('dart_username', 'dart_password', logFile: '');
    expect(sms.userAgent, 'kwtsms-dart/${KwtSMS.version}');
    expect(sms.userAgent, matches(r'^kwtsms-dart/[0-9][0-9A-Za-z.+-]*$'));
  });

  test('app token is prepended', () {
    final sms = KwtSMS('dart_username', 'dart_password',
        logFile: '', appName: 'kwtsms-wordpress/3.5.2');
    expect(
        sms.userAgent, 'kwtsms-wordpress/3.5.2 kwtsms-dart/${KwtSMS.version}');
  });

  test('sanitizer removes CR/LF, non-ASCII and limits length', () {
    final ua = buildUserAgent('my app\r\nX-Injected: 1');
    expect(ua.contains('\r') || ua.contains('\n'), isFalse);
    expect(ua.contains(' X-Injected'), isFalse);
    expect(ua, 'my-appX-Injected:-1 kwtsms-dart/${KwtSMS.version}');
    expect(buildUserAgent('a' * 200).split(' ').first.length, 64);
    expect(buildUserAgent(' \r\n '), 'kwtsms-dart/${KwtSMS.version}');
    expect(
        buildUserAgent('كوshop/1.0'), 'shop/1.0 kwtsms-dart/${KwtSMS.version}');
  });

  test('User-Agent header is sent (mocked, offline)', () async {
    final fake = _FakeHttpClient();
    final sms = KwtSMS('dart_username', 'dart_password',
        logFile: '', appName: 'my-shop/2.1.0');
    await HttpOverrides.runZoned(() => sms.verify(),
        createHttpClient: (_) => fake);
    expect(fake.sent, ['my-shop/2.1.0 kwtsms-dart/${KwtSMS.version}']);
  });
}
