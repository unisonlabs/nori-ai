---
name: security-audit
description: Run a security audit against OWASP Top 10
disable-model-invocation: true
---

Run a comprehensive security audit on the codebase (or the specified path: $ARGUMENTS).

1. **Identify scope.** If a path is provided, focus there. Otherwise, audit the full project.

2. **OWASP Top 10 check.** For each category, inspect relevant code:
   - A01 Broken Access Control — check auth middleware, route protection, RBAC
   - A02 Cryptographic Failures — check TLS config, password hashing, key management
   - A03 Injection — check for SQL injection, XSS, command injection in user inputs
   - A04 Insecure Design — check for missing rate limiting, business logic flaws
   - A05 Security Misconfiguration — check for default creds, verbose errors, debug modes
   - A06 Vulnerable Components — run `pip-audit` (backend) and `npm audit` (mobile)
   - A07 Auth Failures — check session management, verification code handling, token expiry
   - A08 Data Integrity — check deserialization, CI/CD pipeline security
   - A09 Logging Failures — check for missing audit logs, PII in logs (verify Presidio redaction is applied)
   - A10 SSRF — check URL validation, internal network access controls

3. **Secret scanning.** Search for hardcoded API keys, passwords, tokens, and secrets in:
   - Source code
   - Config files and env templates
   - Test fixtures
   - Comments and TODOs

4. **Dependency audit.** Run the package manager's audit command and summarize critical/high findings.

5. **Report.** For each finding:
   - Severity (Critical / High / Medium / Low)
   - File and line reference
   - Description of the vulnerability
   - Recommended fix
   - Only report real, confirmed issues — not theoretical ones.

6. Wait for approval before implementing any fixes.
