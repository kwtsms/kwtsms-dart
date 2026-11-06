# Changelog

## [Unreleased]

## [0.2.0] - 2026-11-07

### Added
- The client sends a User-Agent `kwtsms-dart/<version>` (name and version only, no personal data) so kwtSMS can see which integrations are in use. An optional `appName` constructor argument puts your app's token in front, e.g. `my-shop/2.1.0 kwtsms-dart/0.1.12`. New `KwtSMS.version`, `userAgent`, `kwtsmsVersion` and `buildUserAgent()`.

### Changed
- ERR006 and ERR025 action text, docs and examples use the placeholder `965XXXXXXXX` instead of a sample mobile number; tests read the phone number from `KWTSMS_TEST_NUMBER` and skip the tests that need it when it is unset.
- The live 250-number bulk test is replaced by an offline mocked test of the 200 + 50 batching; live tests send only to `KWTSMS_TEST_NUMBER`.
- Package author and license holder are now kwtSMS.

### Docs
- ERR028 action text: "Sent to the same number too soon." ERR028 is opt-in per account (Duplicate SMS protection) with a per-account window (10 seconds by default), not a fixed 15 seconds.
- Test mode: test messages are queued but not delivered, and their credits are held until you delete them from the Sending Queue. Earlier text said no credits were consumed.

## [0.1.12] - 2026-03-13

### Added
- Country-specific phone validation for 80+ countries (local length + mobile prefix rules)
- `findCountryCode()`, `validatePhoneFormat()`, `phoneRules`, `countryNames`, `PhoneRule` exports
- Trunk prefix stripping in `normalizePhone()`: 9660559... becomes 966559..., 97105x becomes 9715x
- `deduplicatePhones()` documented in README
- GitGuardian secrets scan workflow

### Changed
- `validatePhoneInput()` now validates against country-specific rules (length + mobile prefix)
- README "Utility Functions" expanded to document all 13 public exports
- Fixed em-dash usage in examples, tests, and docs (replaced with colons/commas)

## [0.1.11] - 2026-03-13

### Removed
- CLI tool (`bin/kwtsms.dart`) and CLI tests. Use [kwtsms-cli](https://github.com/boxlinknet/kwtsms-cli) instead (standalone binary, no Dart SDK required).

## [0.1.10] - 2026-03-07

### Added
- Auto-create GitHub Release from tag with changelog notes
- Auto-approve and squash-merge Dependabot PRs after CI passes
- Auto-close stale issues/PRs after 30+7 days of inactivity
- Dependabot tracking for Dart pub dependencies

## [0.1.9] - 2026-03-07

### Added
- Interactive setup wizard for CLI (hidden password, sender ID selection, test/live mode menu)
- Raw API example (`example/00_raw_api.dart`) with step-by-step documentation
- CLI tests (`test/cli_test.dart`) covering help, version, argument validation, and bulk send
- Bulk send integration test (250 numbers, 2-batch verification, balance tracking)
- Pre-test balance check with credit budget assertion in integration tests
- Export `apiRequest` for direct API access
- Input Sanitization, Best Practices, Implementation Checklist, Timestamps sections in README
- User-facing error mapping table in README
- Three new Help & Support links (Best Practices, Integration Test Checklist, Sender ID Help)

### Changed
- README rewritten to match kwtSMS client library standard (title, sections, structure)
- Phone Number Formats table expanded with Persian digits, parentheses, Arabic prefix combos
- FAQ consolidated with Rust/Java client libraries (7 questions)
- Help & Support section updated with full link descriptions
- Integration tests now track exact credit consumption per test

## [0.1.8] - 2026-03-06

### Fixed
- Add `dart_` prefix to test credentials in integration tests (`dart_wrong_user` / `dart_wrong_pass`)

## [0.1.7] - 2026-03-06

### Added
- Add Examples section to README with linked table of all runnable examples

## [0.1.6] - 2026-03-06

### Fixed
- Rewrite FAQ section with numbered questions, spacing, and comprehensive answers matching other kwtSMS client libraries

## [0.1.5] - 2026-03-06

### Fixed
- Use `dart_username` / `dart_password` as placeholder credentials across all docs and examples

## [0.1.4] - 2026-03-06

### Fixed
- pub.dev links now match GitHub repo (homepage, issue_tracker, documentation)

## [0.1.3] - 2026-03-06

### Fixed
- Remove `doc/` from git tracking (internal PRD, not part of published package)
- Fix README title to proper brand casing: "kwtSMS for Dart"
- Fix FAQ link (was pointing to deprecated faq_all.php)
- Remove WhatsApp number from Help & Support section

## [0.1.2] - 2026-03-06

### Fixed
- Remove internal tool files from git tracking
- Fix clone URL in CONTRIBUTING.md (underscore to dash)
- Sync CLI version string with pubspec.yaml
- Update .gitignore

## [0.1.1] - 2026-03-06

### Fixed
- CI: relax static analysis to warnings-only (info-level file_names lint on numbered examples)
- CI: bump actions/checkout to v6
- Rename `docs/` to `doc/` per pub.dev layout convention
- Add SECURITY.md
- Configure GitHub Actions OIDC for automated pub.dev publishing

## [0.1.0] - 2026-03-06

### Added
- Initial release
- KwtSMS client with all API endpoints: send, balance, verify, validate, senderIds, coverage, status, deliveryReport
- Bulk send with automatic batching (>200 numbers)
- Phone number normalization and validation utilities
- Message cleaning (emoji, HTML, control character removal)
- .env file loading
- JSONL logging with credential masking
- CLI tool (kwtsms command)
- Full error code mapping with developer-friendly action messages
- Test mode support
