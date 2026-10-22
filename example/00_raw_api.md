# 00 - Raw API Calls

Direct kwtSMS API calls using only `dart:io` and `dart:convert`. No client library, no abstractions. Every endpoint demonstrated with copy-paste code.

## When to use this

- You want to understand exactly what the API expects and returns
- You are integrating kwtSMS into a project that cannot use the `kwtsms` package
- You want to debug API issues by seeing the raw request/response
- You are porting the integration to another language and need a reference

For production use, the `kwtsms` package handles phone normalization, message cleaning, error enrichment, batching, retries, and logging automatically. See [01_basic_usage.dart](01_basic_usage.dart) for the recommended approach.

## Prerequisites

1. A kwtSMS account ([sign up free](https://www.kwtsms.com/signup/))
2. Your API credentials (not your mobile number): [kwtsms.com](https://www.kwtsms.com/login/) > Account > API
3. Dart 3.0+ installed

## Configuration

Open `00_raw_api.dart` and replace the credentials at the top:

```dart
const username = 'your_api_username';
const password = 'your_api_password';
const senderId = 'KWT-SMS';       // or your registered Sender ID
const testMode = '1';              // '1' = test, '0' = live
```

## Running

```bash
dart run example/00_raw_api.dart
```

## API Endpoints

All endpoints use **POST** with `Content-Type: application/json`. Never use GET (it leaks credentials in server logs). Every request includes `username` and `password` in the JSON body.

Base URL: `https://www.kwtsms.com/API`

### 1. Balance

Check your SMS credit balance and verify credentials.

```
POST /API/balance/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password"
}
```

**Success response:**
```json
{
  "result": "OK",
  "available": 150.0,
  "purchased": 500.0
}
```

**Error response (wrong credentials):**
```json
{
  "result": "ERROR",
  "code": "ERR003",
  "description": "Authentication error, username or password are not correct."
}
```

### 2. Sender IDs

List all sender IDs registered on your account.

```
POST /API/senderid/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password"
}
```

**Success response:**
```json
{
  "result": "OK",
  "senderid": ["KWT-SMS", "MY-APP", "ALERTS"]
}
```

### 3. Coverage

List active country prefixes. International sending is disabled by default.

```
POST /API/coverage/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password"
}
```

**Success response:**
```json
{
  "result": "OK",
  "coverage": [
    { "prefix": "965" },
    { "prefix": "966" }
  ]
}
```

### 4. Validate

Check if phone numbers are valid and routable before sending.

```
POST /API/validate/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password",
  "mobile": "96598765432,123456789,44712345678"
}
```

**Success response:**
```json
{
  "result": "OK",
  "mobile": {
    "OK": ["96598765432"],
    "ER": ["123456789"],
    "NR": ["44712345678"]
  }
}
```

- **OK** = valid and routable
- **ER** = format error (invalid number)
- **NR** = no route (country not activated on your account)

### 5. Send SMS

Send a message to one or more phone numbers.

```
POST /API/send/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password",
  "sender": "KWT-SMS",
  "mobile": "96598765432",
  "message": "Your OTP is: 123456",
  "test": "1"
}
```

**Success response:**
```json
{
  "result": "OK",
  "msg-id": "f4c841adee210f31307633ceaebff2ec",
  "numbers": 1,
  "points-charged": 1,
  "balance-after": 149.0
}
```

**Key rules:**
- Phone numbers must include the country code (e.g., `96598765432` not `98765432`)
- Multiple numbers: comma-separated in the `mobile` field, max 200 per request
- `"test": "1"` queues the message but does NOT deliver it. Its credits are held until you delete it from the Sending Queue in your kwtsms.com account.
- **Always save the `msg-id`**: you need it for status checks and delivery reports
- Sender ID is case-sensitive: `Kuwait` is not the same as `KUWAIT`

### 6. Message Status

Check delivery status of a sent message using the `msg-id`.

```
POST /API/status/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password",
  "msgid": "f4c841adee210f31307633ceaebff2ec"
}
```

**Success response:**
```json
{
  "result": "OK",
  "status": "Delivered",
  "description": "Message delivered to handset"
}
```

**Test-mode response (ERR030):**
```json
{
  "result": "ERROR",
  "code": "ERR030",
  "description": "Message is stuck in the send queue with an error."
}
```

This is normal for test-mode messages. Delete the message from the Sending Queue at kwtsms.com to recover credits.

### 7. Delivery Report (DLR)

Get per-number delivery reports for international messages.

```
POST /API/dlr/
```

**Request body:**
```json
{
  "username": "your_api_username",
  "password": "your_api_password",
  "msgid": "f4c841adee210f31307633ceaebff2ec"
}
```

**Success response:**
```json
{
  "result": "OK",
  "report": [
    { "Number": "44712345678", "Status": "Delivered" }
  ]
}
```

**Note:** Kuwait numbers do not support DLR. Wait at least 5 minutes after sending before checking international DLR.

## Common Error Codes

| Code | Description | What to do |
|------|-------------|-----------|
| ERR001 | API disabled | Enable API at kwtsms.com > Account > API |
| ERR002 | Missing parameter | Check username, password, sender, mobile, message |
| ERR003 | Wrong credentials | Check API username/password (not your mobile number) |
| ERR006 | No valid numbers | Include country code (e.g., 96598765432) |
| ERR008 | Sender ID banned | Use a different registered sender ID |
| ERR009 | Empty message | Provide non-empty message text |
| ERR010 | Zero balance | Recharge credits at kwtsms.com |
| ERR013 | Queue full (max 1000) | Wait and retry |
| ERR024 | IP not whitelisted | Add IP at kwtsms.com > API > IP Lockdown |
| ERR025 | Invalid phone number | Include the country code |
| ERR026 | Country not activated | Contact kwtSMS support |
| ERR028 | Sent to the same number too soon. | Duplicate SMS protection is on for the account: wait for its window (10 seconds by default) before resending |
| ERR030 | Stuck in queue | Normal for test mode. Delete from queue at kwtsms.com |

## What the client library adds

The `kwtsms` Dart package wraps these raw API calls and adds:

- **Phone normalization**: strips `+`, `00`, spaces, dashes; converts Arabic digits
- **Phone validation**: rejects emails, too-short/too-long numbers before calling the API
- **Phone deduplication**: sends each number only once
- **Message cleaning**: strips emojis, HTML tags, invisible Unicode characters
- **Auto-batching**: >200 numbers split into batches of 200 with 0.5s delay
- **ERR013 retry**: queue-full errors retried 3x with 30s/60s/120s backoff
- **Error enrichment**: every error code mapped to a developer-friendly action message
- **Balance caching**: cached after verify/send for quick access
- **JSONL logging**: every API call logged with credential masking
- **.env support**: load credentials from environment variables or .env file
- **Typed results**: `VerifyResult`, `SendResult`, `ValidateResult`, etc.

See [01_basic_usage.dart](01_basic_usage.dart) for the same operations using the client library.
