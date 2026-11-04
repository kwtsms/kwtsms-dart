# Contributing to kwtsms

Thank you for your interest in contributing to the kwtsms Dart client library. This document provides guidelines and instructions for contributing.

## Development Setup

1. Clone the repository:

```bash
git clone https://github.com/kwtsms/kwtsms-dart.git
cd kwtsms-dart
```

2. Install dependencies:

```bash
dart pub get
```

3. Run tests:

```bash
dart test
```

4. Run static analysis:

```bash
dart analyze
```

## Zero-Dependency Policy

This package maintains a strict zero-dependency policy for runtime dependencies. The only allowed dependencies are in `dev_dependencies` (for testing and development). Do not add any packages to `dependencies` in `pubspec.yaml`.

## Branch Naming

Use the following prefixes for branch names:

- `feat/` -- New features (e.g., `feat/add-retry-logic`)
- `fix/` -- Bug fixes (e.g., `fix/phone-normalization-edge-case`)
- `docs/` -- Documentation changes (e.g., `docs/update-api-examples`)
- `test/` -- Test additions or modifications (e.g., `test/bulk-send-batching`)
- `chore/` -- Maintenance tasks (e.g., `chore/update-ci-workflow`)

## Commit Messages

Follow the Conventional Commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types:

- `feat` -- A new feature
- `fix` -- A bug fix
- `docs` -- Documentation only changes
- `style` -- Changes that do not affect the meaning of the code (formatting, etc.)
- `refactor` -- A code change that neither fixes a bug nor adds a feature
- `test` -- Adding missing tests or correcting existing tests
- `chore` -- Changes to the build process or auxiliary tools

Examples:

```
feat(client): add retry logic with exponential backoff
fix(phone): handle numbers with leading plus sign
docs(readme): add usage examples for bulk send
test(validate): add edge cases for empty input
```

## Pull Request Checklist

Before submitting a pull request, ensure the following:

- [ ] All tests pass: `dart test`
- [ ] Static analysis passes with no issues: `dart analyze`
- [ ] No runtime dependencies added (zero-dependency policy)
- [ ] New features include corresponding unit tests
- [ ] Public API changes are documented
- [ ] Commit messages follow conventional commits style
- [ ] Branch name follows the naming convention
- [ ] CHANGELOG.md is updated for user-facing changes
- [ ] Code does not contain hardcoded credentials or secrets
- [ ] Logging uses credential masking for sensitive values

## Running Tests

Run all unit tests:

```bash
dart test
```

Run tests with a specific tag:

```bash
dart test --tags=unit
```

Skip integration tests (which require live API credentials):

```bash
dart test --exclude-tags=integration
```

## Code Style

Follow the official Dart style guide and the lints enforced by `dart analyze`. Key points:

- Use `dart format` to format code before committing
- Prefer single quotes for strings
- Document all public APIs with doc comments
- Keep functions focused and small
- Handle errors explicitly rather than silently ignoring them

## Reporting Issues

When reporting issues, please include:

- Dart SDK version (`dart --version`)
- Package version
- Minimal reproduction steps
- Expected vs actual behavior
- Any relevant error messages or logs (with credentials redacted)
