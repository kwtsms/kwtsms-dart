// Core kwtSMS client class.
import 'dart:io';

import 'env.dart';
import 'errors.dart';
import 'message.dart';
import 'phone.dart';
import 'request.dart';

// -- Result types --

/// Result from [KwtSMS.verify].
class VerifyResult {
  final bool ok;
  final double? balance;
  final String? error;

  const VerifyResult({required this.ok, this.balance, this.error});

  Map<String, dynamic> toJson() =>
      {'ok': ok, 'balance': balance, 'error': error};

  @override
  String toString() =>
      'VerifyResult(ok: $ok, balance: $balance, error: $error)';
}

/// Result from [KwtSMS.send].
class SendResult {
  final String result;
  final String? msgId;
  final int? numbers;
  final int? pointsCharged;
  final double? balanceAfter;
  final String? code;
  final String? description;
  final String? action;
  final List<InvalidEntry> invalid;

  const SendResult({
    required this.result,
    this.msgId,
    this.numbers,
    this.pointsCharged,
    this.balanceAfter,
    this.code,
    this.description,
    this.action,
    this.invalid = const [],
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        if (msgId != null) 'msg-id': msgId,
        if (numbers != null) 'numbers': numbers,
        if (pointsCharged != null) 'points-charged': pointsCharged,
        if (balanceAfter != null) 'balance-after': balanceAfter,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (action != null) 'action': action,
        if (invalid.isNotEmpty)
          'invalid': invalid.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() => 'SendResult(result: $result, code: $code)';
}

/// Per-batch error in a bulk send.
class BatchError {
  final int batch;
  final String code;
  final String description;
  final String? action;

  const BatchError({
    required this.batch,
    required this.code,
    required this.description,
    this.action,
  });

  Map<String, dynamic> toJson() => {
        'batch': batch,
        'code': code,
        'description': description,
        if (action != null) 'action': action,
      };
}

/// Result from [KwtSMS.sendBulk].
class BulkSendResult {
  final String result;
  final bool bulk;
  final int batches;
  final int numbers;
  final int pointsCharged;
  final double? balanceAfter;
  final List<String> msgIds;
  final List<BatchError> errors;
  final List<InvalidEntry> invalid;

  const BulkSendResult({
    required this.result,
    this.bulk = true,
    required this.batches,
    required this.numbers,
    required this.pointsCharged,
    this.balanceAfter,
    this.msgIds = const [],
    this.errors = const [],
    this.invalid = const [],
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        'bulk': bulk,
        'batches': batches,
        'numbers': numbers,
        'points-charged': pointsCharged,
        if (balanceAfter != null) 'balance-after': balanceAfter,
        'msg-ids': msgIds,
        if (errors.isNotEmpty) 'errors': errors.map((e) => e.toJson()).toList(),
        if (invalid.isNotEmpty)
          'invalid': invalid.map((e) => e.toJson()).toList(),
      };

  @override
  String toString() =>
      'BulkSendResult(result: $result, batches: $batches, numbers: $numbers)';
}

/// Result from [KwtSMS.validate].
class ValidateResult {
  final List<String> ok;
  final List<String> er;
  final List<String> nr;
  final List<InvalidEntry> rejected;
  final String? error;
  final Map<String, dynamic>? raw;

  const ValidateResult({
    this.ok = const [],
    this.er = const [],
    this.nr = const [],
    this.rejected = const [],
    this.error,
    this.raw,
  });

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'er': er,
        'nr': nr,
        if (rejected.isNotEmpty)
          'rejected': rejected.map((e) => e.toJson()).toList(),
        if (error != null) 'error': error,
        if (raw != null) 'raw': raw,
      };

  @override
  String toString() =>
      'ValidateResult(ok: ${ok.length}, er: ${er.length}, nr: ${nr.length})';
}

/// Result from [KwtSMS.senderIds].
class SenderIdResult {
  final String result;
  final List<String> senderIds;
  final String? code;
  final String? description;
  final String? action;

  const SenderIdResult({
    required this.result,
    this.senderIds = const [],
    this.code,
    this.description,
    this.action,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        'senderid': senderIds,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (action != null) 'action': action,
      };

  @override
  String toString() => 'SenderIdResult(result: $result, senderIds: $senderIds)';
}

/// Result from [KwtSMS.coverage].
class CoverageResult {
  final String result;
  final List<String> prefixes;
  final String? code;
  final String? description;
  final String? action;

  const CoverageResult({
    required this.result,
    this.prefixes = const [],
    this.code,
    this.description,
    this.action,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        'prefixes': prefixes,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (action != null) 'action': action,
      };

  @override
  String toString() =>
      'CoverageResult(result: $result, prefixes: ${prefixes.length} entries)';
}

/// Result from [KwtSMS.status].
class StatusResult {
  final String result;
  final String? status;
  final String? statusDescription;
  final String? code;
  final String? description;
  final String? action;

  const StatusResult({
    required this.result,
    this.status,
    this.statusDescription,
    this.code,
    this.description,
    this.action,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        if (status != null) 'status': status,
        if (statusDescription != null) 'statusDescription': statusDescription,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (action != null) 'action': action,
      };

  @override
  String toString() => 'StatusResult(result: $result, status: $status)';
}

/// Single entry in a delivery report.
class DeliveryReportEntry {
  final String number;
  final String status;

  const DeliveryReportEntry({required this.number, required this.status});

  Map<String, dynamic> toJson() => {'number': number, 'status': status};

  @override
  String toString() => 'DeliveryReportEntry(number: $number, status: $status)';
}

/// Result from [KwtSMS.deliveryReport].
class DeliveryReportResult {
  final String result;
  final List<DeliveryReportEntry> report;
  final String? code;
  final String? description;
  final String? action;

  const DeliveryReportResult({
    required this.result,
    this.report = const [],
    this.code,
    this.description,
    this.action,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        if (report.isNotEmpty) 'report': report.map((e) => e.toJson()).toList(),
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (action != null) 'action': action,
      };

  @override
  String toString() =>
      'DeliveryReportResult(result: $result, entries: ${report.length})';
}

// -- Main client --

/// kwtSMS API client.
///
/// All API methods are async and return typed result objects.
/// Dart is single-threaded (event loop), so no mutex is needed for cached
/// balance. If using Isolates, create a separate [KwtSMS] instance per Isolate.
class KwtSMS {
  final String _username;
  final String _password;
  final String _senderId;
  final bool testMode;
  final String _logFile;

  // 2026-11-05 14:18 +03: User-Agent sent on every API call (#939).
  final String _userAgent;

  /// Library version, sent in the User-Agent.
  static const String version = kwtsmsVersion;

  /// The User-Agent this client sends: `[app token ]kwtsms-dart/<version>`.
  String get userAgent => _userAgent;

  double? _cachedBalance;
  double? _cachedPurchased;

  /// Last known available balance from [verify] or successful [send].
  double? get cachedBalance => _cachedBalance;

  /// Total purchased credits from the last [verify] call.
  double? get cachedPurchased => _cachedPurchased;

  /// Create a new kwtSMS client.
  ///
  /// - [username]: API username
  /// - [password]: API password
  /// - [senderId]: sender ID (defaults to `KWT-SMS`, for testing only)
  /// - [testMode]: if true, messages are queued but not delivered
  /// - [logFile]: path to JSONL log file (empty string disables logging)
  /// - [appName]: product token of the calling app or plugin, e.g.
  ///   `kwtsms-wordpress/3.5.2`, sent before the library token in the User-Agent
  // 2026-11-05 14:18 +03: appName added for per-integration counts (#939).
  KwtSMS(
    this._username,
    this._password, {
    String senderId = 'KWT-SMS',
    this.testMode = false,
    String logFile = 'kwtsms.log',
    String appName = '',
  })  : _senderId = senderId,
        _logFile = logFile,
        _userAgent = buildUserAgent(appName);

  /// Create a client from environment variables and/or .env file.
  ///
  /// Reads `KWTSMS_USERNAME`, `KWTSMS_PASSWORD`, `KWTSMS_SENDER_ID`,
  /// `KWTSMS_TEST_MODE`, `KWTSMS_LOG_FILE` from the environment first,
  /// then falls back to the .env file.
  factory KwtSMS.fromEnv({String envFile = '.env'}) {
    final fileVars = loadEnvFile(envFile);
    final env = Platform.environment;

    String get(String key, String fallback) =>
        env[key] ?? fileVars[key] ?? fallback;

    final username = get('KWTSMS_USERNAME', '');
    final password = get('KWTSMS_PASSWORD', '');
    final senderId = get('KWTSMS_SENDER_ID', 'KWT-SMS');
    final testModeStr = get('KWTSMS_TEST_MODE', '0');
    final logFile = get('KWTSMS_LOG_FILE', 'kwtsms.log');

    final testMode = testModeStr == '1' || testModeStr.toLowerCase() == 'true';

    return KwtSMS(
      username,
      password,
      senderId: senderId,
      testMode: testMode,
      logFile: logFile,
    );
  }

  Map<String, dynamic> get _authPayload => {
        'username': _username,
        'password': _password,
      };

  // -- API methods --

  /// Test credentials and return the current balance.
  ///
  /// Never throws. Returns a [VerifyResult] with `ok: false` on any error.
  Future<VerifyResult> verify() async {
    try {
      final data = await apiRequest(
        endpoint: 'balance',
        payload: _authPayload,
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        final available = (data['available'] as num?)?.toDouble();
        final purchased = (data['purchased'] as num?)?.toDouble();
        _cachedBalance = available;
        _cachedPurchased = purchased;
        return VerifyResult(ok: true, balance: available);
      }

      final enriched = enrichError(data);
      return VerifyResult(
        ok: false,
        error: enriched['action'] as String? ??
            enriched['description'] as String? ??
            'Unknown error',
      );
    } catch (e) {
      return VerifyResult(ok: false, error: '$e');
    }
  }

  /// Get the current SMS credit balance.
  ///
  /// Returns the live balance on success, or the cached value if the API
  /// call fails. Returns null if no cached value exists.
  Future<double?> balance() async {
    try {
      final data = await apiRequest(
        endpoint: 'balance',
        payload: _authPayload,
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        final available = (data['available'] as num?)?.toDouble();
        final purchased = (data['purchased'] as num?)?.toDouble();
        _cachedBalance = available;
        _cachedPurchased = purchased;
        return available;
      }

      return _cachedBalance;
    } catch (_) {
      return _cachedBalance;
    }
  }

  /// Send an SMS to one or more phone numbers.
  ///
  /// - [mobile]: one or more phone numbers (comma-separated or single)
  /// - [message]: the message text (cleaned automatically)
  /// - [sender]: override sender ID for this send
  ///
  /// Phone numbers are validated locally before sending. Invalid numbers
  /// are collected in [SendResult.invalid] without crashing the call.
  /// Numbers are deduplicated after normalization.
  ///
  /// For >200 numbers, automatically batches with 0.5s delay between batches.
  Future<SendResult> send(
    String mobile,
    String message, {
    String? sender,
  }) async {
    // Split comma-separated numbers
    final rawNumbers = mobile
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawNumbers.length > 200) {
      // Delegate to bulk send and convert result
      final bulkResult = await sendBulk(rawNumbers, message, sender: sender);
      return SendResult(
        result: bulkResult.result,
        msgId: bulkResult.msgIds.isNotEmpty ? bulkResult.msgIds.first : null,
        numbers: bulkResult.numbers,
        pointsCharged: bulkResult.pointsCharged,
        balanceAfter: bulkResult.balanceAfter,
        code:
            bulkResult.errors.isNotEmpty ? bulkResult.errors.first.code : null,
        description: bulkResult.errors.isNotEmpty
            ? bulkResult.errors.first.description
            : null,
        action: bulkResult.errors.isNotEmpty
            ? bulkResult.errors.first.action
            : null,
        invalid: bulkResult.invalid,
      );
    }

    return _sendToPhones(rawNumbers, message, sender: sender);
  }

  /// Explicitly send SMS to multiple phone numbers in batches.
  ///
  /// Splits into batches of 200 with 0.5s delay between batches.
  /// ERR013 (queue full) is retried up to 3 times with exponential backoff.
  Future<BulkSendResult> sendBulk(
    List<String> mobiles,
    String message, {
    String? sender,
  }) async {
    return _sendBulkInternal(mobiles, message, sender: sender);
  }

  /// Validate phone numbers with the kwtSMS API.
  ///
  /// Runs local validation first, then sends valid numbers to the API.
  /// Invalid numbers are collected in [ValidateResult.rejected].
  Future<ValidateResult> validate(List<String> phones) async {
    final invalid = <InvalidEntry>[];
    final validNumbers = <String>[];

    for (final phone in phones) {
      final (valid, error, normalized) = validatePhoneInput(phone);
      if (!valid) {
        invalid.add(InvalidEntry(input: phone, error: error!));
      } else {
        validNumbers.add(normalized);
      }
    }

    final deduped = deduplicatePhones(validNumbers);

    if (deduped.isEmpty) {
      return ValidateResult(
        rejected: invalid,
        error: invalid.isNotEmpty
            ? 'All numbers failed local validation'
            : 'No phone numbers provided',
      );
    }

    try {
      final data = await apiRequest(
        endpoint: 'validate',
        payload: {
          ..._authPayload,
          'mobile': deduped.join(','),
        },
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        final mobile = data['mobile'] as Map<String, dynamic>? ?? {};
        return ValidateResult(
          ok: _toStringList(mobile['OK']),
          er: _toStringList(mobile['ER']),
          nr: _toStringList(mobile['NR']),
          rejected: invalid,
          raw: data,
        );
      }

      final enriched = enrichError(data);
      return ValidateResult(
        rejected: invalid,
        error:
            enriched['action'] as String? ?? enriched['description'] as String?,
        raw: data,
      );
    } catch (e) {
      return ValidateResult(
        rejected: invalid,
        error: '$e',
      );
    }
  }

  /// List available sender IDs on this account.
  Future<SenderIdResult> senderIds() async {
    try {
      final data = await apiRequest(
        endpoint: 'senderid',
        payload: _authPayload,
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        return SenderIdResult(
          result: 'OK',
          senderIds: _toStringList(data['senderid']),
        );
      }

      final enriched = enrichError(data);
      return SenderIdResult(
        result: 'ERROR',
        code: enriched['code'] as String?,
        description: enriched['description'] as String?,
        action: enriched['action'] as String?,
      );
    } catch (e) {
      return SenderIdResult(
        result: 'ERROR',
        description: '$e',
      );
    }
  }

  /// List active country prefixes for SMS delivery.
  Future<CoverageResult> coverage() async {
    try {
      final data = await apiRequest(
        endpoint: 'coverage',
        payload: _authPayload,
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        // The API returns coverage data; extract prefix list
        final prefixes = <String>[];
        final coverage = data['coverage'];
        if (coverage is List) {
          for (final item in coverage) {
            if (item is Map) {
              final prefix = item['prefix'] ?? item['Prefix'];
              if (prefix != null) prefixes.add('$prefix');
            } else {
              prefixes.add('$item');
            }
          }
        } else if (coverage is Map) {
          for (final key in coverage.keys) {
            prefixes.add('$key');
          }
        }
        // If no coverage key, try prefixes directly
        if (prefixes.isEmpty && data.containsKey('prefixes')) {
          prefixes.addAll(_toStringList(data['prefixes']));
        }
        return CoverageResult(result: 'OK', prefixes: prefixes);
      }

      final enriched = enrichError(data);
      return CoverageResult(
        result: 'ERROR',
        code: enriched['code'] as String?,
        description: enriched['description'] as String?,
        action: enriched['action'] as String?,
      );
    } catch (e) {
      return CoverageResult(result: 'ERROR', description: '$e');
    }
  }

  /// Check delivery status of a sent message.
  ///
  /// [msgId] is the `msg-id` from a successful [send] response.
  Future<StatusResult> status(String msgId) async {
    try {
      final data = await apiRequest(
        endpoint: 'status',
        payload: {..._authPayload, 'msgid': msgId},
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        return StatusResult(
          result: 'OK',
          status: data['status'] as String?,
          statusDescription: data['description'] as String?,
        );
      }

      final enriched = enrichError(data);
      return StatusResult(
        result: 'ERROR',
        code: enriched['code'] as String?,
        description: enriched['description'] as String?,
        action: enriched['action'] as String?,
      );
    } catch (e) {
      return StatusResult(result: 'ERROR', description: '$e');
    }
  }

  /// Get delivery reports for a sent message (international numbers only).
  ///
  /// Kuwait numbers do not support DLR. Wait 5+ minutes after sending
  /// before checking international DLR.
  Future<DeliveryReportResult> deliveryReport(String msgId) async {
    try {
      final data = await apiRequest(
        endpoint: 'dlr',
        payload: {..._authPayload, 'msgid': msgId},
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        final reportList = data['report'];
        final entries = <DeliveryReportEntry>[];
        if (reportList is List) {
          for (final item in reportList) {
            if (item is Map) {
              entries.add(DeliveryReportEntry(
                number: '${item['Number'] ?? item['number'] ?? ''}',
                status: '${item['Status'] ?? item['status'] ?? ''}',
              ));
            }
          }
        }
        return DeliveryReportResult(result: 'OK', report: entries);
      }

      final enriched = enrichError(data);
      return DeliveryReportResult(
        result: 'ERROR',
        code: enriched['code'] as String?,
        description: enriched['description'] as String?,
        action: enriched['action'] as String?,
      );
    } catch (e) {
      return DeliveryReportResult(result: 'ERROR', description: '$e');
    }
  }

  // -- Private methods --

  Future<SendResult> _sendToPhones(
    List<String> rawNumbers,
    String message, {
    String? sender,
  }) async {
    // Clean message
    final cleaned = cleanMessage(message);
    if (cleaned.trim().isEmpty) {
      return const SendResult(
        result: 'ERROR',
        code: 'ERR009',
        description: 'Message is empty after cleaning.',
        action: 'Message is empty. Provide a non-empty message text.',
        invalid: [],
      );
    }

    // Validate and normalize each number
    final invalid = <InvalidEntry>[];
    final validNumbers = <String>[];

    for (final raw in rawNumbers) {
      final (valid, error, normalized) = validatePhoneInput(raw);
      if (!valid) {
        invalid.add(InvalidEntry(input: raw, error: error!));
      } else {
        validNumbers.add(normalized);
      }
    }

    // Deduplicate
    final deduped = deduplicatePhones(validNumbers);

    if (deduped.isEmpty) {
      return SendResult(
        result: 'ERROR',
        code: 'ERR_INVALID_INPUT',
        description: 'All phone numbers are invalid.',
        action: apiErrors['ERR_INVALID_INPUT'],
        invalid: invalid,
      );
    }

    try {
      final data = await apiRequest(
        endpoint: 'send',
        payload: {
          ..._authPayload,
          'sender': sender ?? _senderId,
          'mobile': deduped.join(','),
          'message': cleaned,
          'test': testMode ? '1' : '0',
        },
        logFile: _logFile,
        userAgent: _userAgent,
      );

      if (data['result'] == 'OK') {
        final bal = (data['balance-after'] as num?)?.toDouble();
        if (bal != null) _cachedBalance = bal;

        return SendResult(
          result: 'OK',
          msgId: data['msg-id'] as String?,
          numbers: data['numbers'] as int?,
          pointsCharged: data['points-charged'] as int?,
          balanceAfter: bal,
          invalid: invalid,
        );
      }

      final enriched = enrichError(data);
      return SendResult(
        result: 'ERROR',
        code: enriched['code'] as String?,
        description: enriched['description'] as String?,
        action: enriched['action'] as String?,
        invalid: invalid,
      );
    } catch (e) {
      return SendResult(
        result: 'ERROR',
        description: '$e',
        invalid: invalid,
      );
    }
  }

  Future<BulkSendResult> _sendBulkInternal(
    List<String> mobiles,
    String message, {
    String? sender,
  }) async {
    // Clean message
    final cleaned = cleanMessage(message);
    if (cleaned.trim().isEmpty) {
      return const BulkSendResult(
        result: 'ERROR',
        batches: 0,
        numbers: 0,
        pointsCharged: 0,
      );
    }

    // Validate all numbers
    final invalid = <InvalidEntry>[];
    final validNumbers = <String>[];

    for (final raw in mobiles) {
      final (valid, error, normalized) = validatePhoneInput(raw);
      if (!valid) {
        invalid.add(InvalidEntry(input: raw, error: error!));
      } else {
        validNumbers.add(normalized);
      }
    }

    final deduped = deduplicatePhones(validNumbers);

    if (deduped.isEmpty) {
      return BulkSendResult(
        result: 'ERROR',
        batches: 0,
        numbers: 0,
        pointsCharged: 0,
        invalid: invalid,
      );
    }

    // Split into batches of 200
    final batches = <List<String>>[];
    for (var i = 0; i < deduped.length; i += 200) {
      batches.add(deduped.sublist(
        i,
        i + 200 > deduped.length ? deduped.length : i + 200,
      ));
    }

    final msgIds = <String>[];
    final errors = <BatchError>[];
    var totalNumbers = 0;
    var totalPoints = 0;
    double? lastBalance;

    for (var i = 0; i < batches.length; i++) {
      // 0.5s delay between batches (except first)
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final batchResult = await _sendSingleBatch(
        batches[i],
        cleaned,
        sender: sender,
        batchIndex: i,
      );

      if (batchResult['result'] == 'OK') {
        final mid = batchResult['msg-id'] as String?;
        if (mid != null) msgIds.add(mid);
        totalNumbers += (batchResult['numbers'] as int?) ?? 0;
        totalPoints += (batchResult['points-charged'] as int?) ?? 0;
        final bal = (batchResult['balance-after'] as num?)?.toDouble();
        if (bal != null) {
          lastBalance = bal;
          _cachedBalance = bal;
        }
      } else {
        final enriched = enrichError(batchResult);
        errors.add(BatchError(
          batch: i + 1,
          code: enriched['code'] as String? ?? 'UNKNOWN',
          description: enriched['description'] as String? ?? 'Unknown error',
          action: enriched['action'] as String?,
        ));
      }
    }

    // Determine overall result
    final String overallResult;
    if (errors.isEmpty) {
      overallResult = 'OK';
    } else if (msgIds.isNotEmpty) {
      overallResult = 'PARTIAL';
    } else {
      overallResult = 'ERROR';
    }

    return BulkSendResult(
      result: overallResult,
      batches: batches.length,
      numbers: totalNumbers,
      pointsCharged: totalPoints,
      balanceAfter: lastBalance,
      msgIds: msgIds,
      errors: errors,
      invalid: invalid,
    );
  }

  /// Send a single batch (up to 200 numbers) with ERR013 retry.
  Future<Map<String, dynamic>> _sendSingleBatch(
    List<String> numbers,
    String cleanedMessage, {
    String? sender,
    int batchIndex = 0,
  }) async {
    const retryDelays = [30, 60, 120]; // seconds
    var attempt = 0;

    while (true) {
      try {
        final data = await apiRequest(
          endpoint: 'send',
          payload: {
            ..._authPayload,
            'sender': sender ?? _senderId,
            'mobile': numbers.join(','),
            'message': cleanedMessage,
            'test': testMode ? '1' : '0',
          },
          logFile: _logFile,
          userAgent: _userAgent,
        );

        // Retry on ERR013 (queue full)
        if (data['code'] == 'ERR013' && attempt < retryDelays.length) {
          await Future.delayed(Duration(seconds: retryDelays[attempt]));
          attempt++;
          continue;
        }

        return data;
      } catch (e) {
        if (attempt < retryDelays.length) {
          await Future.delayed(Duration(seconds: retryDelays[attempt]));
          attempt++;
          continue;
        }
        return {
          'result': 'ERROR',
          'description': '$e',
        };
      }
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e').toList();
    }
    return [];
  }
}
