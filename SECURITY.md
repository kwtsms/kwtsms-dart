# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 0.2.x   | Yes                |
| 0.1.x   | No                 |

## Reporting a Vulnerability

If you discover a security vulnerability in this package, please report it
responsibly:

1. **Do NOT open a public GitHub issue.**
2. Email **security@boxlink.net** with:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected version(s)
3. You will receive a response within 48 hours.
4. A fix will be released as a patch version once confirmed.

## Security Considerations

- **Never hardcode API credentials.** Use environment variables or `.env` files.
- **Always use HTTPS.** The client enforces HTTPS for all API calls.
- **Credentials are masked in logs.** The built-in logger replaces passwords with `***`.
- **Phone numbers are normalized locally.** No user input is passed to the API without sanitization.
