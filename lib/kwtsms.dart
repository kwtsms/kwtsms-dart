/// Official Dart/Flutter client for the kwtSMS SMS gateway API.
///
/// Send SMS, check balance, validate numbers, and more with the kwtSMS API.
/// Zero dependencies: uses only dart:io, dart:convert, and dart:math.
library kwtsms;

export 'src/client.dart'
    show
        KwtSMS,
        VerifyResult,
        SendResult,
        BulkSendResult,
        BatchError,
        ValidateResult,
        SenderIdResult,
        CoverageResult,
        StatusResult,
        DeliveryReportEntry,
        DeliveryReportResult;
export 'src/errors.dart' show apiErrors, enrichError;
export 'src/phone.dart'
    show
        normalizePhone,
        validatePhoneInput,
        deduplicatePhones,
        InvalidEntry,
        PhoneRule,
        phoneRules,
        countryNames,
        findCountryCode,
        validatePhoneFormat;
export 'src/message.dart' show cleanMessage;
export 'src/env.dart' show loadEnvFile;
// 2026-11-05 14:18 +03: buildUserAgent and kwtsmsVersion exported (#939).
export 'src/request.dart' show apiRequest, buildUserAgent, kwtsmsVersion;
