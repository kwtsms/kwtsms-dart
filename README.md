# kwtSMS Dart Client

[![pub package](https://img.shields.io/pub/v/kwtsms.svg)](https://pub.dev/packages/kwtsms)
[![CI](https://github.com/kwtsms/kwtsms-dart/actions/workflows/test.yml/badge.svg)](https://github.com/kwtsms/kwtsms-dart/actions/workflows/test.yml)
[![Static Analysis](https://github.com/kwtsms/kwtsms-dart/actions/workflows/codeql.yml/badge.svg)](https://github.com/kwtsms/kwtsms-dart/actions/workflows/codeql.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3](https://img.shields.io/badge/dart-%3E%3D3.0-blue.svg)](https://dart.dev)
[![pub points](https://img.shields.io/pub/points/kwtsms)](https://pub.dev/packages/kwtsms/score)

Dart/Flutter client for the [kwtSMS API](https://www.kwtsms.com). Send SMS, check balance, validate numbers, list sender IDs, check coverage, get delivery reports.

## About kwtSMS

kwtSMS is a Kuwaiti SMS gateway trusted by top businesses to deliver messages anywhere in the world, with private Sender ID, free API testing, non-expiring credits, and competitive flat-rate pricing. Secure, simple to integrate, built to last. Open a free account in under 1 minute, no paperwork or payment required. [Click here to get started](https://www.kwtsms.com/signup/)

## Prerequisites

You need **Dart** (3.0 or newer) installed. If you use Flutter, Dart is included. Zero runtime dependencies.

### Option A: Dart only (server-side)

```bash
dart --version
```

If you see a version number (e.g., `Dart SDK version: 3.x.x`), Dart is installed. If not:

- **macOS:** `brew tap dart-lang/dart && brew install dart`
- **Ubuntu/Debian:** Follow instructions at https://dart.dev/get-dart#install
- **Windows:** Download from https://dart.dev/get-dart#install

### Option B: Flutter (mobile / cross-platform apps)

```bash
flutter --version
```

If you see a version number, Flutter (with Dart) is installed. If not, follow https://docs.flutter.dev/get-started/install

### Install kwtsms

For a Dart project:
```bash
dart pub add kwtsms
```

For a Flutter project:
```bash
flutter pub add kwtsms
```

## Quick Start

```dart
import 'package:kwtsms/kwtsms.dart';

void main() async {
  final sms = KwtSMS('dart_username', 'dart_password');

  // Verify credentials
  final verify = await sms.verify();
  print('Balance: ${verify.balance}');

  // Send SMS
  final result = await sms.send('96598765432', 'Hello from Dart!');
  print('Result: ${result.result}, Message ID: ${result.msgId}');
}
```

## Setup / Configuration

### Option 1: Environment variables

```bash
export KWTSMS_USERNAME=dart_username
export KWTSMS_PASSWORD=dart_password
export KWTSMS_SENDER_ID=YOUR-SENDERID
export KWTSMS_TEST_MODE=0
export KWTSMS_LOG_FILE=kwtsms.log
```

```dart
final sms = KwtSMS.fromEnv();
```

### Option 2: .env file

Create a `.env` file in your project root:

```ini
KWTSMS_USERNAME=dart_username
KWTSMS_PASSWORD=dart_password
KWTSMS_SENDER_ID=YOUR-SENDERID
KWTSMS_TEST_MODE=1
KWTSMS_LOG_FILE=kwtsms.log
```

```dart
final sms = KwtSMS.fromEnv(); // reads .env automatically
```

### Option 3: Direct constructor

```dart
final sms = KwtSMS(
  'dart_username',
  'dart_password',
  senderId: 'YOUR-SENDERID',
  testMode: true,
  logFile: 'kwtsms.log',
);
```

## Credential Management

**Never hardcode credentials.** Use one of these approaches:

1. **Environment variables / .env file** (default): `KwtSMS.fromEnv()` loads from env vars, then `.env` file. The file is `.gitignore`d and editable without redeployment.

2. **Constructor injection**: `KwtSMS(username, password, ...)` for custom config systems, DI containers, or remote config.

3. **Secrets manager**: Load from AWS Secrets Manager, HashiCorp Vault, Google Secret Manager, or your own config API, then pass to the constructor.

4. **Admin settings UI** (for web apps): Store credentials in your database with a settings page. Include a "Test Connection" button that calls `verify()`.

### Additional requirements for mobile apps (Flutter)

**Backend proxy (strongly recommended):** The mobile app calls YOUR backend server, which holds the kwtSMS credentials and makes the API call. The app never touches the SMS API directly. This is the only pattern that fully protects credentials.

**If calling the API directly (not recommended):** Store credentials using `flutter_secure_storage` and provide a settings screen for entering/updating them. NEVER store credentials in assets, hardcoded strings, or environment files bundled with the app.

### Thread Safety

Dart is single-threaded (event loop). No mutex is needed for cached balance in standard use. If using Isolates, create a separate `KwtSMS` instance per Isolate.

## All Methods

### verify()

Test credentials and get the current balance.

```dart
final result = await sms.verify();
// VerifyResult(ok: true, balance: 150.0, error: null)

if (result.ok) {
  print('Balance: ${result.balance}');
} else {
  print('Error: ${result.error}');
}
```

### balance()

Get the current SMS credit balance. Returns cached value if the API call fails.

```dart
final bal = await sms.balance();
print('Balance: $bal');

// Cached values (updated after verify/send):
print('Cached balance: ${sms.cachedBalance}');
print('Purchased: ${sms.cachedPurchased}');
```

### send(mobile, message, {sender})

Send SMS to one or more phone numbers. Auto-batches when >200 numbers.

```dart
// Single number
final result = await sms.send('96598765432', 'Your OTP is: 123456');

if (result.result == 'OK') {
  print('Message ID: ${result.msgId}');         // save this!
  print('Points charged: ${result.pointsCharged}');
  print('Balance after: ${result.balanceAfter}'); // save this too!
}

// Multiple numbers (comma-separated)
final result2 = await sms.send(
  '96598765432,96512345678',
  'Hello everyone!',
);

// Override sender ID
final result3 = await sms.send(
  '96598765432',
  'Alert!',
  sender: 'MY-APP',
);
```

**What happens automatically:**
- Phone numbers are normalized (strips +, 00, spaces, dashes, converts Arabic digits ٠١٢٣٤٥٦٧٨٩)
- Numbers are deduplicated after normalization
- Invalid numbers are collected in `result.invalid` without crashing
- Message text is cleaned (emojis stripped, HTML removed, control chars removed)
- For >200 numbers, splits into batches of 200 with 0.5s delay

### sendBulk(mobiles, message, {sender})

Explicitly send to a list of numbers in batches.

```dart
final numbers = ['96598765432', '96512345678', /* ... hundreds more */];
final result = await sms.sendBulk(numbers, 'Campaign message');

// BulkSendResult
print('Result: ${result.result}');     // OK, PARTIAL, or ERROR
print('Batches: ${result.batches}');
print('Numbers sent: ${result.numbers}');
print('Points charged: ${result.pointsCharged}');
print('Message IDs: ${result.msgIds}');

if (result.errors.isNotEmpty) {
  for (final err in result.errors) {
    print('Batch ${err.batch}: ${err.code} - ${err.description}');
  }
}
```

### validate(phones)

Validate phone numbers with the kwtSMS API.

```dart
final result = await sms.validate(['96598765432', '123', 'test@email.com']);

print('Valid (OK): ${result.ok}');        // routable numbers
print('Format error (ER): ${result.er}'); // format issues
print('No route (NR): ${result.nr}');     // country not activated

// Numbers that failed local validation (never sent to API):
for (final entry in result.rejected) {
  print('${entry.input}: ${entry.error}');
}
```

### senderIds()

List available sender IDs on this account.

```dart
final result = await sms.senderIds();
if (result.result == 'OK') {
  for (final id in result.senderIds) {
    print('Sender ID: $id');
  }
}
```

### coverage()

List active country prefixes for SMS delivery.

```dart
final result = await sms.coverage();
if (result.result == 'OK') {
  for (final prefix in result.prefixes) {
    print('Active prefix: $prefix');
  }
}
```

### status(msgId)

Check delivery status of a sent message.

```dart
final result = await sms.status('f4c841adee210f31307633ceaebff2ec');
if (result.result == 'OK') {
  print('Status: ${result.status}');
  print('Description: ${result.statusDescription}');
}
```

### deliveryReport(msgId)

Get per-number delivery reports (international numbers only, Kuwait numbers do not support DLR).

```dart
final result = await sms.deliveryReport('f4c841adee210f31307633ceaebff2ec');
if (result.result == 'OK') {
  for (final entry in result.report) {
    print('${entry.number}: ${entry.status}');
  }
}
```

## Utility Functions

These are exported publicly and can be used independently.

### normalizePhone(phone)

Strips non-digits, converts Arabic/Persian digits to Latin, removes leading zeros, and strips domestic trunk prefixes after the country code.

```dart
normalizePhone('+96598765432');     // '96598765432'
normalizePhone('0096598765432');    // '96598765432'
normalizePhone('965 9876 5432');    // '96598765432'
normalizePhone('965-9876-5432');    // '96598765432'
normalizePhone('٩٦٥٩٨٧٦٥٤٣٢');         // '96598765432' (Arabic digits converted)

// Trunk prefix stripping: removes the leading 0 after the country code
normalizePhone('9660559876543');    // '966559876543' (Saudi 0 stripped)
normalizePhone('+9660559876543');   // '966559876543'
normalizePhone('9710501234567');    // '971501234567' (UAE 0 stripped)
normalizePhone('20010123456789');   // '2010123456789' (Egypt 0 stripped)
```

### validatePhoneInput(phone)

Validates a phone number input. Runs normalization, basic checks (empty, email, length), and country-specific format validation (local length + mobile prefix).

```dart
final (valid, error, normalized) = validatePhoneInput('96598765432');
// (true, null, '96598765432')

final (v2, e2, n2) = validatePhoneInput('123');
// (false, "'123' is too short (3 digits, minimum is 7)", '123')

final (v3, e3, n3) = validatePhoneInput('user@example.com');
// (false, "'user@example.com' is an email address, not a phone number", '')

// Country-specific validation
final (v4, e4, n4) = validatePhoneInput('96512345678');
// (false, "Invalid Kuwait mobile number: after +965 must start with 4, 5, 6, 9", '96512345678')

final (v5, e5, n5) = validatePhoneInput('9651234567');
// (false, "Invalid Kuwait number: expected 8 digits after +965, got 7", '9651234567')
```

### findCountryCode(normalized)

Finds the country code prefix from a normalized phone number. Tries 3-digit, then 2-digit, then 1-digit (longest match wins).

```dart
findCountryCode('96598765432');   // '965' (Kuwait)
findCountryCode('201012345678');  // '20'  (Egypt)
findCountryCode('12025551234');   // '1'   (USA/Canada)
findCountryCode('9991234567');    // null  (unknown)
```

### validatePhoneFormat(normalized)

Validates a normalized phone number against country-specific rules: local number length and mobile starting digits. Numbers with no matching country rules pass through.

```dart
final (valid, error) = validatePhoneFormat('96598765432');
// (true, null)

final (v2, e2) = validatePhoneFormat('96512345678');
// (false, "Invalid Kuwait mobile number: after +965 must start with 4, 5, 6, 9")
```

### phoneRules

Map of 80+ countries with validation rules. Each entry has `localLengths` (valid digit counts after country code) and `mobileStartDigits` (valid first digits for mobile numbers).

```dart
phoneRules['965']; // PhoneRule(localLengths: [8], mobileStartDigits: ['4','5','6','9'])
phoneRules['966']; // PhoneRule(localLengths: [9], mobileStartDigits: ['5'])
phoneRules['1'];   // PhoneRule(localLengths: [10]) -- USA/Canada, no prefix check
```

### countryNames

Map of country codes to human-readable country names. Used in error messages.

```dart
countryNames['965']; // 'Kuwait'
countryNames['966']; // 'Saudi Arabia'
countryNames['44'];  // 'UK'
```

### deduplicatePhones(phones)

Removes duplicate phone numbers from a list while preserving order.

```dart
deduplicatePhones(['96598765432', '96512345678', '96598765432']);
// ['96598765432', '96512345678']
```

### cleanMessage(text)

```dart
cleanMessage('Hello \u{1F600}');  // 'Hello ' (emoji stripped)
cleanMessage('<b>Bold</b>');      // 'Bold' (HTML stripped)
cleanMessage('\uFEFFHello');      // 'Hello' (BOM stripped)
cleanMessage('رمز التحقق: ١٢٣٤٥٦'); // 'رمز التحقق: 123456' (Arabic digits converted)
```

### enrichError(response)

```dart
final enriched = enrichError({
  'result': 'ERROR',
  'code': 'ERR003',
  'description': 'Authentication error',
});
print(enriched['action']); // Developer-friendly guidance
```

### apiErrors

Read-only map of all 33 error codes to action messages. Useful for building custom error UIs.

```dart
print(apiErrors['ERR003']); // 'Wrong API username or password...'
```

### loadEnvFile([path])

```dart
final vars = loadEnvFile('.env');
print(vars['KWTSMS_USERNAME']);
```

## Input Sanitization

`cleanMessage()` is called automatically by `send()` before every API call. It prevents the #1 cause of "message sent but not received" support tickets:

| Content | Effect without cleaning | What cleanMessage() does |
|---------|------------------------|--------------------------|
| Emojis | Stuck in queue, credits wasted, no error | Stripped |
| Hidden control characters (BOM, zero-width space, soft hyphen) | Spam filter rejection or queue stuck | Stripped |
| Arabic/Hindi numerals in body | OTP codes render inconsistently | Converted to Latin digits |
| HTML tags | ERR027, message rejected | Stripped |
| Directional marks (LTR, RTL) | May cause display issues | Stripped |

Arabic letters and Arabic text are fully supported and never stripped.

## Error Handling

Every ERROR response includes an `action` field with a developer-friendly fix:

```dart
final result = await sms.send('96598765432', 'Hello');

if (result.result == 'OK') {
  // Save msg-id and balance-after
  db.save('sms_balance', result.balanceAfter);
  db.save('msg_id', result.msgId);
} else {
  // Error handling
  print('Code: ${result.code}');
  print('Description: ${result.description}');
  print('Action: ${result.action}'); // developer-friendly guidance
}

// Invalid numbers are collected, never crash the call
for (final entry in result.invalid) {
  print('${entry.input}: ${entry.error}');
}
```

### User-facing error mapping

Raw API errors should never be shown to end users. Map them:

| Situation | API error | Show to user |
|-----------|----------|--------------|
| Invalid phone number | ERR006, ERR025 | "Please enter a valid phone number in international format (e.g., +965 9876 5432)." |
| Wrong credentials | ERR003 | "SMS service is temporarily unavailable. Please try again later." (log + alert admin) |
| No balance | ERR010, ERR011 | "SMS service is temporarily unavailable. Please try again later." (alert admin) |
| Country not supported | ERR026 | "SMS delivery to this country is not available." |
| Rate limited | ERR028 | "Please wait a moment before requesting another code." |
| Message rejected | ERR031, ERR032 | "Your message could not be sent. Please try again with different content." |
| Queue full | ERR013 | "SMS service is busy. Please try again in a few minutes." (library retries automatically) |
| Network error | Connection timeout | "Could not connect to SMS service." |

### Common Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| ERR003 | Wrong credentials | Check KWTSMS_USERNAME and KWTSMS_PASSWORD |
| ERR006 | No valid phone numbers | Include country code (e.g., 96598765432) |
| ERR008 | Sender ID banned | Use a different sender ID |
| ERR009 | Empty message | Provide a non-empty message |
| ERR010 | Zero balance | Recharge at kwtsms.com |
| ERR011 | Insufficient balance | Buy more credits |
| ERR013 | Queue full | Retried automatically (3x with backoff) |
| ERR024 | IP not whitelisted | Add IP at kwtsms.com > API > IP Lockdown |
| ERR025 | Invalid phone number | Include the country code |
| ERR026 | Country not activated | Contact kwtSMS support |
| ERR028 | 15-second rate limit | Wait before resending to same number |

## Phone Number Formats

All formats are accepted and normalized automatically:

| Input | Normalized | Valid? |
|-------|-----------|--------|
| `96598765432` | `96598765432` | Yes |
| `+96598765432` | `96598765432` | Yes |
| `0096598765432` | `96598765432` | Yes |
| `965 9876 5432` | `96598765432` | Yes |
| `965-9876-5432` | `96598765432` | Yes |
| `(965) 98765432` | `96598765432` | Yes |
| `٩٦٥٩٨٧٦٥٤٣٢` | `96598765432` | Yes |
| `۹۶۵۹۸۷۶۵۴۳۲` | `96598765432` | Yes |
| `+٩٦٥٩٨٧٦٥٤٣٢` | `96598765432` | Yes |
| `٠٠٩٦٥٩٨٧٦٥٤٣٢` | `96598765432` | Yes |
| `٩٦٥ ٩٨٧٦ ٥٤٣٢` | `96598765432` | Yes |
| `٩٦٥-٩٨٧٦-٥٤٣٢` | `96598765432` | Yes |
| `965٩٨٧٦٥٤٣٢` | `96598765432` | Yes |
| `123456` (too short) | rejected | No |
| `user@gmail.com` | rejected | No |

## Test Mode

**Test mode** (`KWTSMS_TEST_MODE=1`) sends your message to the kwtSMS queue but does NOT deliver it to the handset. No SMS credits are consumed. Use this during development.

**Live mode** (`KWTSMS_TEST_MODE=0`) delivers the message for real and deducts credits. Always develop in test mode and switch to live only when ready for production.

```dart
final sms = KwtSMS('user', 'pass', testMode: true);
final result = await sms.send('96598765432', 'Test message');
// Message is queued but NOT delivered. No credits consumed.
```

Test messages appear in the Sending Queue at kwtsms.com. Delete them from the queue to recover any tentatively held credits. Remember to set `testMode: false` before going live.

## Sender ID

A **Sender ID** is the name that appears as the sender on the recipient's phone (e.g., "MY-APP" instead of a random number).

| | Promotional | Transactional |
|--|-------------|---------------|
| **Use for** | Bulk SMS, marketing, offers | OTP, alerts, notifications |
| **Delivery to DND numbers** | Blocked/filtered, credits lost | Bypasses DND (whitelisted) |
| **Speed** | May have delays | Priority delivery |
| **Cost** | 10 KD one-time | 15 KD one-time |

`KWT-SMS` is a shared test sender. It causes delivery delays, is blocked on Virgin Kuwait, and should never be used in production. Register your own private Sender ID through your kwtSMS account. For OTP/authentication messages, you need a **Transactional** Sender ID to bypass DND filtering. Sender ID is **case sensitive**.

## Timestamps

`unix-timestamp` values in API responses are in **GMT+3 (Asia/Kuwait)** server time, not UTC. Convert when storing or displaying.

## Best Practices

### Always save msg-id and balance-after

```dart
final result = await sms.send(phone, message);
if (result.result == 'OK') {
  db.save('sms_msg_id', result.msgId);         // needed for status/DLR
  db.save('sms_balance', result.balanceAfter);  // no extra API call needed
}
```

### Validate locally before calling the API

```dart
final (valid, error, normalized) = validatePhoneInput(userInput);
if (!valid) {
  return {'error': error};  // rejected locally, no API call
}
```

### Country coverage pre-check

Call `coverage()` once at startup and cache the active prefixes. Before every send, check if the number's country prefix is in the list. If not, return an error immediately without hitting the API.

```dart
// At startup
final coverage = await sms.coverage();
final activePrefixes = coverage.prefixes;

// Before send
if (!activePrefixes.any((p) => normalized.startsWith(p))) {
  return {'error': 'SMS delivery to this country is not available.'};
}
```

### OTP requirements

- Always include app/company name: `"Your OTP for APPNAME is: 123456"`
- Resend timer: minimum 3-4 minutes (KNET standard is 4 minutes)
- OTP expiry: 3-5 minutes
- New code on resend: always generate a fresh code, invalidate previous
- Use Transactional Sender ID for OTP (not Promotional, not KWT-SMS)
- One number per OTP request: never batch OTP sends

## Implementation Checklist

Before going live, verify you have implemented these correctly:

- [ ] Validate phone numbers locally before calling the API (reject emails, too-short, too-long)
- [ ] Clean message text before sending (emojis, HTML, hidden characters)
- [ ] Check country coverage before sending (cache prefixes from `coverage()`)
- [ ] Save `msg-id` from every successful send (needed for status/DLR)
- [ ] Save `balance-after` from every successful send (never call `balance()` after `send()`)
- [ ] Map raw API errors to user-facing messages (never expose ERR codes to users)
- [ ] Log errors with full details for admin review
- [ ] Set up low-balance alerts
- [ ] Handle ERR028 (15-second same-number rate limit) in your UI
- [ ] Use Transactional Sender ID for OTP (not Promotional)

## Security Checklist

Before going live:

- [ ] Bot protection enabled (Device Attestation for mobile, CAPTCHA for web)
- [ ] Rate limit per phone number (max 3-5 OTP/hour)
- [ ] Rate limit per IP address (max 10-20/hour)
- [ ] Rate limit per user/session if authenticated
- [ ] Monitoring/alerting on abuse patterns
- [ ] Admin notification on low balance
- [ ] Test mode OFF (`KWTSMS_TEST_MODE=0`)
- [ ] Private Sender ID registered (not KWT-SMS)
- [ ] Transactional Sender ID for OTP (not promotional)

## What's Handled Automatically

- **Phone normalization**: `+`, `00`, spaces, dashes, dots, parentheses stripped. Arabic-Indic digits converted. Leading zeros removed.
- **Duplicate phone removal**: If the same number appears multiple times (in different formats), it is sent only once.
- **Message cleaning**: Emojis removed (codepoint-safe). Hidden control characters (BOM, zero-width spaces, directional marks) removed. HTML tags stripped. Arabic-Indic digits in message body converted to Latin.
- **Batch splitting**: More than 200 numbers are automatically split into batches of 200 with 0.5s delay between batches.
- **ERR013 retry**: Queue-full errors are automatically retried up to 3 times with exponential backoff (30s / 60s / 120s).
- **Error enrichment**: Every API error response includes an `action` field with a developer-friendly fix hint.
- **Credential masking**: Passwords are always masked as `***` in log files. Never exposed.
- **Balance caching**: Balance is cached from every `verify()` and `send()` response. `balance()` falls back to the cached value on API failure.

## Examples

See the [example/](example/) directory:

| # | Example | Description |
|---|---------|-------------|
| 00 | [Raw API](example/00_raw_api.dart) | Call every kwtSMS endpoint directly, no library, just dart:io ([docs](example/00_raw_api.md)) |
| 01 | [Basic Usage](example/01_basic_usage.dart) | Load credentials, verify, send SMS, print result |
| 02 | [OTP Flow](example/02_otp_flow.dart) | Generate OTP, validate phone, send, save msg-id |
| 03 | [Bulk SMS](example/03_bulk_sms.dart) | Send to multiple numbers with mixed formats |
| 04 | [Shelf Endpoint](example/04_shelf_endpoint.dart) | Shelf HTTP endpoint for sending SMS with validation |
| 05 | [Error Handling](example/05_error_handling.dart) | Handle all error types with user-facing messages |
| 06 | [OTP Production](example/06_otp_production/) | Production OTP service: rate limiting, hashing, device attestation, resend cooldown |

## CLI

For command-line usage, see [kwtsms-cli](https://github.com/kwtsms/kwtsms-cli), a standalone cross-platform binary (no Dart SDK required).

## FAQ

**1. My message was sent successfully (result: OK) but the recipient didn't receive it. What happened?**

Check the **Sending Queue** at [kwtsms.com](https://www.kwtsms.com/login/). If your message is stuck there, it was accepted by the API but not dispatched. Common causes are emoji in the message, hidden characters from copy-pasting, or spam filter triggers. Delete it from the queue to recover your credits. Also verify that `test` mode is off (`KWTSMS_TEST_MODE=0`). Test messages are queued but never delivered.

**2. What is the difference between Test mode and Live mode?**

**Test mode** (`KWTSMS_TEST_MODE=1`) sends your message to the kwtSMS queue but does NOT deliver it to the handset. No SMS credits are consumed. Use during development. **Live mode** (`KWTSMS_TEST_MODE=0`) delivers the message for real and deducts credits. Always develop in test mode and switch to live only when ready for production.

**3. What is a Sender ID and why should I not use "KWT-SMS" in production?**

A **Sender ID** is the name that appears as the sender on the recipient's phone (e.g., "MY-APP" instead of a random number). `KWT-SMS` is a shared test sender. It causes delivery delays, is blocked on Virgin Kuwait, and should never be used in production. Register your own private Sender ID through your kwtSMS account. For OTP/authentication messages, you need a **Transactional** Sender ID to bypass DND (Do Not Disturb) filtering.

**4. I'm getting ERR003 "Authentication error". What's wrong?**

You are using the wrong credentials. The API requires your **API username and API password**, NOT your account mobile number. Log in to [kwtsms.com](https://www.kwtsms.com/login/), go to Account, and check your API credentials. Also make sure you are using POST (not GET) and `Content-Type: application/json`.

**5. Can I send to international numbers (outside Kuwait)?**

International sending is **disabled by default** on kwtSMS accounts. [Log in to your kwtSMS account](https://www.kwtsms.com/login/) and add coverage for the country prefixes you need. Use `coverage()` to check which countries are currently active on your account. Be aware that activating international coverage increases exposure to automated abuse. Implement rate limiting and CAPTCHA before enabling.

**6. Can I use this with Flutter?**

Yes. The library works in both pure Dart (server-side) and Flutter (mobile) contexts. Install with `flutter pub add kwtsms`.

**7. How do I check if a message was delivered?**

Save the `msg-id` from the send response, then call `sms.status(msgId)`. For international numbers, use `sms.deliveryReport(msgId)` (wait 5+ minutes). Kuwait numbers do not support delivery reports.

## Help & Support

- **[kwtSMS FAQ](https://www.kwtsms.com/faq/)**: Answers to common questions about credits, sender IDs, OTP, and delivery
- **[kwtSMS Support](https://www.kwtsms.com/support.html)**: Open a support ticket or browse help articles
- **[Contact kwtSMS](https://www.kwtsms.com/#contact)**: Reach the kwtSMS team directly for Sender ID registration and account issues
- **[API Documentation (PDF)](https://www.kwtsms.com/doc/KwtSMS.com_API_Documentation_v41.pdf)**: kwtSMS REST API v4.1 full reference
- **[Best Practices](https://www.kwtsms.com/articles/sms-api-implementation-best-practices.html)**: SMS API implementation best practices
- **[Integration Test Checklist](https://www.kwtsms.com/articles/sms-api-integration-test-checklist.html)**: Pre-launch testing checklist
- **[Sender ID Help](https://www.kwtsms.com/sender-id-help.html)**: Guide to registering and managing Sender IDs
- **[kwtSMS Dashboard](https://www.kwtsms.com/login/)**: Recharge credits, buy Sender IDs, view message logs, manage coverage
- **[Other Integrations](https://www.kwtsms.com/integrations.html)**: Plugins and integrations for other platforms and languages
- **[Library Issues](https://github.com/kwtsms/kwtsms-dart/issues)**: Report bugs or request features for this Dart client

## License

MIT
