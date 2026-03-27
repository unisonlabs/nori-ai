---
name: deps-check
description: Audit dependencies for vulnerabilities, updates, and unused packages
disable-model-invocation: true
---

Audit project dependencies for security, freshness, and cleanliness.

1. **Detect which project(s) to audit.** Check for `pyproject.toml` (backend, Poetry) and `package.json` (mobile, npm).

2. **Vulnerability scan.** Run:
   - `pip-audit` for the Python backend
   - `npm audit` for the React Native mobile app
   Summarize critical and high severity findings with CVE IDs and recommended fixes.

3. **Check for outdated packages:**
   - `poetry show --outdated` (backend) / `npm outdated` (mobile)
   - Flag major version bumps that may have breaking changes
   - Highlight packages more than 2 major versions behind

4. **Find unused dependencies:**
   - Check which packages in `pyproject.toml` / `package.json` are actually imported in the codebase
   - List any that appear unused (verify by searching for imports)

5. **Report:**
   - **Critical/High vulnerabilities** — must fix before next release
   - **Outdated packages** — prioritized by severity of being behind
   - **Unused packages** — candidates for removal
   - For each finding, include the package name, current version, recommended action, and any breaking change notes.

6. Wait for approval before making any changes.
