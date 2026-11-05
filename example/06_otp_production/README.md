# Production OTP Example

A self-contained OTP service implementation using the kwtSMS Dart client. Drop this into your project and adapt the storage and attestation layers for your stack.

## What this demonstrates

Complete OTP flow with security best practices: phone validation, device attestation (iOS/Android), two-tier rate limiting, secure code hashing, cooldown timers, and framework integration patterns.

## Architecture

```
otp_service.dart              Core OTP service (sendOtp, verifyOtp)
adapters/
  memory_store.dart           In-memory store (dev/testing only)
attestation/
  app_attest_verifier.dart    iOS App Attest (placeholder)
  play_integrity_verifier.dart Android Play Integrity (placeholder)
usage/
  shelf_usage.dart            Shelf framework wiring
  dart_frog_usage.dart        Dart Frog framework wiring
```

## Send OTP Flow

1. **Sanitize phone input**: normalize and validate the phone number
2. **Verify device attestation**: confirm request comes from a genuine app (iOS App Attest / Android Play Integrity)
3. **Validate auth token** (optional): for 2FA flows where user is partially authenticated
4. **Check IP rate limit**: max 20 requests per IP per hour (configurable)
5. **Check phone rate limit**: max 5 requests per phone per hour (configurable)
6. **Check resend cooldown**: 4-minute minimum between sends to same number
7. **Generate code**: 6-digit cryptographically secure random code
8. **Hash with salt**: SHA-256 with per-code unique salt (use package:crypto in production)
9. **Store record**: save hashed code, salt, expiry, cooldown, attempt counter
10. **Send SMS**: send via kwtSMS to single number (never batch OTP)
11. **Rollback on failure**: delete record if SMS send fails (rate limit counters are NOT rolled back)

## Verify OTP Flow

1. **Sanitize inputs**: validate phone and code format
2. **Check verify rate limit**: max 10 verification attempts per hour
3. **Load record**: find active OTP for this phone
4. **Check state**: reject if already used, expired, or max attempts reached
5. **Constant-time comparison**: compare hashed input against stored hash (timing-attack safe)
6. **Update state**: increment attempt count on wrong code, mark as used on correct code

## Configuration

```dart
final config = OtpServiceConfig(
  codeLength: 6,                                    // OTP code length
  codeExpiry: Duration(minutes: 5),                 // code valid for 5 minutes
  resendCooldown: Duration(minutes: 4),             // wait 4 min between sends
  maxAttempts: 5,                                   // lock after 5 wrong attempts
  ipLimitPerHour: 20,                               // max SMS per IP per hour
  phoneLimitPerHour: 5,                             // max SMS per phone per hour
  verifyLimitPerHour: 10,                           // max verify attempts per hour
  appName: 'MYAPP',                                 // included in SMS message
);
```

## Environment Variables

```ini
KWTSMS_USERNAME=dart_username
KWTSMS_PASSWORD=dart_password
KWTSMS_SENDER_ID=YOUR-TRANSACTIONAL-ID
KWTSMS_TEST_MODE=1
KWTSMS_LOG_FILE=kwtsms.log
```

## Storage Adapters

| Adapter | Use case | Persistence |
|---------|----------|-------------|
| MemoryOtpStore | Development, testing | Lost on restart |

For production, implement the `OtpStore` interface with your database (PostgreSQL, Redis, SQLite, etc.).

## Bot Protection

Mobile apps use device attestation instead of CAPTCHA:

| Platform | Mechanism | What it proves |
|----------|-----------|---------------|
| iOS | Apple App Attest | Request from genuine app on real Apple device |
| Android | Play Integrity API | Request from genuine app on real Android device |

Implement the `DeviceAttestVerifier` interface for your platform.

## Security Checklist

```
[ ] Use Transactional Sender ID (not KWT-SMS or Promotional)
[ ] Device attestation enabled (App Attest for iOS, Play Integrity for Android)
[ ] Rate limit per phone number (max 5/hour)
[ ] Rate limit per IP address (max 20/hour)
[ ] Rate limit on verify attempts (max 10/hour)
[ ] Resend cooldown enforced (4-minute minimum)
[ ] OTP codes hashed with salt before storage (SHA-256 via package:crypto)
[ ] Constant-time comparison for hash verification
[ ] Rate limit counters not rolled back on send failure
[ ] OTP expires after 5 minutes
[ ] Old code invalidated on resend
[ ] App name included in OTP message (telecom compliance)
```

## Common Mistakes

**Wrong: storing plain OTP codes**
```dart
// BAD: plain code in database
record.code = '123456';
```
```dart
// GOOD: hash with unique salt
record.codeHash = sha256(salt + ':' + code);
record.salt = randomSalt;
```

**Wrong: rolling back rate limit on failure**
```dart
// BAD: attacker can bypass by triggering failures
if (sendFailed) rollbackRateLimit();
```
```dart
// GOOD: rate limit always counts, even on failure
await incrementRateLimit(key); // before send attempt
```

**Wrong: batching OTP sends**
```dart
// BAD: ERR028 rejects entire batch if any number was sent to recently
sms.send('num1,num2,num3', 'Your OTP: 123456');
```
```dart
// GOOD: one number per OTP request
sms.send('965XXXXXXXX', 'Your OTP for MYAPP is: 123456');
```

**Wrong: using Promotional Sender ID for OTP**
```dart
// BAD: DND numbers silently blocked, credits deducted
sms.send(phone, otpMessage, sender: 'PROMO-ID');
```
```dart
// GOOD: Transactional ID bypasses DND
sms.send(phone, otpMessage, sender: 'TRANS-ID');
```
