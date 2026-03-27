# Security Workflows

Using Claude Code for security audits, vulnerability scanning, dependency checking, and secure coding practices.

---

## Built-in Security Review

Claude Code has a built-in security review capability:

```
/security-review
```

This scans your codebase for vulnerabilities, validates findings, and recommends patches you can review and approve.

---

## Security Audit Skill

See [`skills/security-audit/SKILL.md`](../skills/security-audit/SKILL.md) for a comprehensive security audit workflow that checks against OWASP Top 10.

```
/security-audit
/security-audit src/api/
```

---

## GitHub Actions Integration

Anthropic maintains an official [security review GitHub Action](https://github.com/anthropics/claude-code-security-review) that automatically reviews every PR for security vulnerabilities:

- Posts inline comments on PRs with identified concerns
- Recommends specific fixes
- Catches injection flaws, auth bypasses, and insecure data handling

---

## Dependency Auditing

### /deps-check Skill

See [`skills/deps-check/SKILL.md`](../skills/deps-check/SKILL.md) — checks for outdated, vulnerable, or unused dependencies.

### Manual Checks

```
"Run npm audit and summarize critical/high vulnerabilities with recommended fixes"

"Check our Gemfile.lock for known CVEs"

"Find unused dependencies in package.json by checking which are actually imported"
```

---

## OWASP Top 10 Checklist

Ask Claude to audit against specific OWASP categories:

| Category | What to check |
|----------|--------------|
| **A01: Broken Access Control** | Auth middleware, route protection, RBAC |
| **A02: Cryptographic Failures** | TLS config, password hashing, key management |
| **A03: Injection** | SQL injection, XSS, command injection, LDAP injection |
| **A04: Insecure Design** | Business logic flaws, missing rate limiting |
| **A05: Security Misconfiguration** | Default creds, verbose errors, unnecessary features |
| **A06: Vulnerable Components** | Outdated deps, known CVEs |
| **A07: Auth Failures** | Session management, credential stuffing protection |
| **A08: Data Integrity Failures** | Deserialization, CI/CD pipeline security |
| **A09: Logging Failures** | Missing audit logs, PII in logs |
| **A10: SSRF** | URL validation, internal network access |

### Example Prompt

```
"Audit src/api/ against OWASP Top 10. For each category, list:
 1. What you checked
 2. Any issues found (with file:line references)
 3. Recommended fixes
 Only report real issues, not theoretical ones."
```

---

## Secret Scanning

```
"Scan the entire codebase for hardcoded secrets, API keys, passwords, and tokens.
Check:
- Source code files
- Config files
- Environment file templates
- Test fixtures
- Comments and TODOs
Report findings with file:line references."
```

### Hook: Block Secrets in Commits

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "content=$(jq -r '.tool_input.content // .tool_input.new_string // empty'); if echo \"$content\" | grep -qEi '(api[_-]?key|secret|password|token)\\s*[=:]\\s*[\"'\\''][A-Za-z0-9]'; then echo 'BLOCK: Possible hardcoded secret detected' >&2; exit 1; fi"
          }
        ]
      }
    ]
  }
}
```

---

## Infrastructure Security

### Terraform Security Review

```
"Review all Terraform files for:
- Overly permissive IAM policies (wildcard actions or resources)
- Security groups with 0.0.0.0/0 ingress
- Unencrypted S3 buckets, EBS volumes, or RDS instances
- Missing CloudTrail or VPC flow logs
- Public subnets for resources that should be private"
```

### Kubernetes Security Review

```
"Review Kubernetes manifests for:
- Containers running as root
- Missing securityContext
- Missing resource limits and requests
- Missing NetworkPolicies
- Secrets stored in plain ConfigMaps
- Images using :latest tag"
```

### Docker Security Review

```
"Review Dockerfiles for:
- Running as root user
- Secrets passed as build args
- Using untrusted base images
- Not pinning package versions
- Unnecessary packages installed"
```

---

## Incident Response

See [`skills/incident-response/SKILL.md`](../skills/incident-response/SKILL.md) — pulls together Sentry errors, BetterStack logs, recent deploys, and relevant code changes to help debug production incidents.

---

## Security Plugins

Enable via `/plugin`:

- **Security Guidance** — security best practices and vulnerability detection
- **security-scanner-plugin** — scans code using GitHub's official vulnerability data

---

## Best Practices

1. **Automate in CI.** Don't rely solely on manual Claude audits — add the [security review GitHub Action](https://github.com/anthropics/claude-code-security-review) to your pipeline.
2. **Use read-only DB access.** Always connect Claude to databases with read-only credentials.
3. **Never commit secrets.** Use hooks to block, and `.gitignore` for `.env` files.
4. **Audit dependencies regularly.** Run `/deps-check` before major releases.
5. **Review Claude's security fixes.** Claude catches real vulnerabilities, but verify its fixes don't break functionality or introduce new issues.
