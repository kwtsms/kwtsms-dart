// FILE:      test/mock_bulk_test.dart
// CREATED:   2026-11-05 08:25 +03
// TASK:      int-testnumber (Boss 2026-11-05 00:33)
// AUTHOR:    M Alhassoun
// WHAT:      Offline test of send() with 250 numbers: internal bulk send in
//            two batches (200 + 50) against an in-process fake HttpClient.
// WHY:       Replaces the live 250-number bulk test, which sent test=1 to
//            generated Kuwait numbers that belong to real people and held
//            250 credits. Nothing here touches the network.
// USAGE:     dart test test/mock_bulk_test.dart
// DEPENDS:   dart:io HttpOverrides, package:test. No credentials, no env vars.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kwtsms/kwtsms.dart';
import 'package:test/test.dart';

/// Every request the fake client received: host, path and decoded payload.
class _Captured {
  _Captured(this.url, this.payload);
  final Uri url;
  final Map<String, dynamic> payload;
}

/// HttpClient stand-in: answers every send with OK, charging 1 per number.
class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.calls);
  final List<_Captured> calls;
  double balance = 1000;

  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeRequest(this, url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this._client, this._url);
  final _FakeHttpClient _client;
  final Uri _url;
  final _body = <int>[];

  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  int contentLength = -1;

  @override
  void add(List<int> data) => _body.addAll(data);

  @override
  Future<HttpClientResponse> close() async {
    final payload = jsonDecode(utf8.decode(_body)) as Map<String, dynamic>;
    _client.calls.add(_Captured(_url, payload));
    final count = (payload['mobile'] as String).split(',').length;
    _client.balance -= count;
    return _FakeResponse(jsonEncode({
      'result': 'OK',
      'msg-id': 'mock-${_client.calls.length}',
      'numbers': count,
      'points-charged': count,
      'balance-after': _client.balance,
      'unix-timestamp': 1700000000,
    }));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

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
  test('send() with 250 numbers batches 200 + 50 (mocked, offline)', () async {
    final calls = <_Captured>[];
    final fake = _FakeHttpClient(calls);

    // 250 unique generated Kuwait-format numbers. They never leave this
    // process: every HttpClient in the zone is the fake above.
    final numbers =
        List.generate(250, (i) => '9659${(1000000 + i).toString()}');

    final sms =
        KwtSMS('dart_username', 'dart_password', testMode: true, logFile: '');

    final result = await HttpOverrides.runZoned(
      () => sms.send(numbers.join(','), 'Dart bulk test 250 numbers'),
      createHttpClient: (_) => fake,
    );

    expect(calls.length, 2, reason: '250 numbers should need 2 requests');
    for (final c in calls) {
      expect(c.url.host, 'www.kwtsms.com');
      expect(c.url.path, '/API/send/');
      expect(c.payload['test'], '1');
    }
    final batch1 = (calls[0].payload['mobile'] as String).split(',');
    final batch2 = (calls[1].payload['mobile'] as String).split(',');
    expect(batch1.length, 200);
    expect(batch2.length, 50);
    expect([...batch1, ...batch2], numbers,
        reason: 'all numbers sent once, in order');

    expect(result.result, 'OK');
    expect(result.msgId, 'mock-1', reason: 'first batch msg-id is returned');
    expect(result.numbers, 250);
    expect(result.pointsCharged, 250);
    expect(result.balanceAfter, 750);
    expect(sms.cachedBalance, 750);
  });
}
