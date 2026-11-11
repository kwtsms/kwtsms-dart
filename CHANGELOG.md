# Changelog

## [Unreleased]

## [0.2.0] - 2026-11-07

### Added
- Client identifies itself with name and version; optional app name argument.

### Changed
- Package author and license holder are now kwtSMS.

## [0.1.12] - 2026-03-13

### Added
- Country-specific phone validation.
- Trunk prefix handling in phone normalization.
- Secrets scan workflow.

### Changed
- `validatePhoneInput()` uses country-specific rules.

## [0.1.11] - 2026-03-13

### Removed
- Built-in CLI. Use [kwtsms-cli](https://github.com/boxlinknet/kwtsms-cli) instead.

## [0.1.10] - 2026-03-07

### Added
- Auto-created GitHub Releases from tags.
- Dependabot tracking for Dart pub dependencies.

## [0.1.9] - 2026-03-07

### Added
- Raw API example.
- Bulk send integration test.
- Export `apiRequest` for direct API access.
- New README sections and links.

### Changed
- README rewritten to the kwtSMS client library standard.

## [0.1.8] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.7] - 2026-03-06

### Added
- Examples section in README.

## [0.1.6] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.5] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.4] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.3] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.2] - 2026-03-06

### Fixed
- Bug fixes.

## [0.1.1] - 2026-03-06

### Fixed
- Bug fixes.
- Automated pub.dev publishing.

## [0.1.0] - 2026-03-06

### Added
- Initial release
- KwtSMS client with all API endpoints
- Bulk send with automatic batching
- Phone number normalization and validation
- Message cleaning
- .env file loading
- JSONL logging
- CLI tool (kwtsms command)
- Error code mapping with developer-friendly messages
- Test mode support
