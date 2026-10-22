import 'package:test/test.dart';
import 'package:kwtsms/kwtsms.dart';

void main() {
  group('apiErrors', () {
    test('contains all 33 error codes', () {
      final expectedCodes = [
        'ERR001',
        'ERR002',
        'ERR003',
        'ERR004',
        'ERR005',
        'ERR006',
        'ERR007',
        'ERR008',
        'ERR009',
        'ERR010',
        'ERR011',
        'ERR012',
        'ERR013',
        'ERR019',
        'ERR020',
        'ERR021',
        'ERR022',
        'ERR023',
        'ERR024',
        'ERR025',
        'ERR026',
        'ERR027',
        'ERR028',
        'ERR029',
        'ERR030',
        'ERR031',
        'ERR032',
        'ERR033',
        'ERR_INVALID_INPUT',
      ];
      for (final code in expectedCodes) {
        expect(apiErrors.containsKey(code), isTrue,
            reason: 'Missing error code: $code');
      }
    });

    test('all action messages are non-empty', () {
      for (final entry in apiErrors.entries) {
        expect(entry.value, isNotEmpty,
            reason: '${entry.key} has empty action message');
      }
    });

    test('ERR003 mentions credentials', () {
      expect(apiErrors['ERR003'], contains('KWTSMS_USERNAME'));
      expect(apiErrors['ERR003'], contains('KWTSMS_PASSWORD'));
    });

    test('ERR010 mentions kwtsms.com', () {
      expect(apiErrors['ERR010'], contains('kwtsms.com'));
    });

    test('ERR024 mentions IP', () {
      expect(apiErrors['ERR024'], contains('IP'));
    });

    // 2026-10-22 15:38 +03: the ERR028 window is per account, not a fixed 15 s.
    test('ERR028 says too soon', () {
      expect(apiErrors['ERR028'], contains('too soon'));
    });
  });

  group('enrichError', () {
    test('adds action for known error code', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR003',
        'description': 'Authentication error',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], isNotNull);
      expect(enriched['action'], contains('KWTSMS_USERNAME'));
    });

    test('preserves original fields', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR003',
        'description': 'Authentication error',
      };
      final enriched = enrichError(response);
      expect(enriched['result'], 'ERROR');
      expect(enriched['code'], 'ERR003');
      expect(enriched['description'], 'Authentication error');
    });

    test('does not add action for unknown code', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR999',
        'description': 'Unknown error',
      };
      final enriched = enrichError(response);
      expect(enriched.containsKey('action'), isFalse);
    });

    test('does not modify OK responses', () {
      final response = {'result': 'OK', 'balance': 150};
      final enriched = enrichError(response);
      expect(enriched.containsKey('action'), isFalse);
      expect(enriched['result'], 'OK');
    });

    test('does not mutate original map', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR003',
        'description': 'Auth error',
      };
      enrichError(response);
      expect(response.containsKey('action'), isFalse);
    });

    test('handles response without code field', () {
      final response = {'result': 'ERROR', 'description': 'Some error'};
      final enriched = enrichError(response);
      expect(enriched.containsKey('action'), isFalse);
    });

    test('handles all error codes', () {
      for (final code in apiErrors.keys) {
        final response = {
          'result': 'ERROR',
          'code': code,
          'description': 'Test',
        };
        final enriched = enrichError(response);
        expect(enriched['action'], isNotNull,
            reason: 'enrichError failed for $code');
        expect(enriched['action'], apiErrors[code]);
      }
    });

    // Mocked API error response tests
    test('ERR003 (wrong credentials) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR003',
        'description':
            'Authentication error, username or password are not correct.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('Check KWTSMS_USERNAME'));
    });

    test('ERR026 (country not allowed) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR026',
        'description': 'Country not activated.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('country'));
    });

    test('ERR025 (invalid number) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR025',
        'description': 'Invalid phone number.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('country code'));
    });

    test('ERR010 (zero balance) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR010',
        'description': 'Balance is zero.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('kwtsms.com'));
    });

    test('ERR024 (IP not whitelisted) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR024',
        'description': 'IP not allowed.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('IP'));
    });

    // 2026-10-22 15:38 +03: ERR028 is duplicate SMS protection with a per-account window.
    test('ERR028 (duplicate SMS protection) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR028',
        'description': 'Sent to the same number too soon.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('too soon'));
    });

    test('ERR008 (banned sender ID) returns action', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR008',
        'description': 'Sender ID banned.',
      };
      final enriched = enrichError(response);
      expect(enriched['action'], contains('sender ID'));
    });

    test('ERR999 (unknown error code) does not crash', () {
      final response = {
        'result': 'ERROR',
        'code': 'ERR999',
        'description': 'Something unknown happened.',
      };
      final enriched = enrichError(response);
      expect(enriched['description'], 'Something unknown happened.');
      expect(enriched.containsKey('action'), isFalse);
    });
  });
}
