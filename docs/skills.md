# Skills

Skills are reusable workflows invoked via slash commands. They live in `.claude/skills/` (project-level, shared with team) or `~/.claude/skills/` (personal).

Each skill is a `SKILL.md` file with frontmatter and a prompt template. Use `$ARGUMENTS` to pass arguments from the slash command.

---

## Recommended Team Skills

Ready-to-use skills are in the [`skills/`](../skills/) directory. Copy them to your project's `.claude/skills/` or personal `~/.claude/skills/`.

### /fix-issue — Fix a GitHub issue end-to-end

Reads the issue, finds relevant code, implements a fix, writes tests, and creates a PR.

```
Usage: /fix-issue 1234
```

[View skill file](../skills/fix-issue/SKILL.md)

### /review-my-changes — Self-review before PR

Reviews staged and unstaged changes for security issues, missing error handling, incomplete implementations, and pattern violations.

```
Usage: /review-my-changes
```

[View skill file](../skills/review-my-changes/SKILL.md)

### /security-audit — Run a security audit

Scans the codebase against OWASP Top 10, checks for hardcoded secrets, vulnerable dependencies, and injection risks.

```
Usage: /security-audit
Usage: /security-audit src/api/
```

[View skill file](../skills/security-audit/SKILL.md)

### /terraform-plan — Safe Terraform planning

Validates Terraform changes, checks for drift, ensures least-privilege IAM, and prevents dangerous operations.

```
Usage: /terraform-plan infrastructure/production
```

[View skill file](../skills/terraform-plan/SKILL.md)

### /k8s-debug — Debug Kubernetes issues

Inspects pod status, logs, events, and resource usage to diagnose cluster issues.

```
Usage: /k8s-debug my-namespace
Usage: /k8s-debug my-namespace my-pod
```

[View skill file](../skills/k8s-debug/SKILL.md)

### /deps-check — Dependency audit

Checks for outdated, vulnerable, or unused dependencies across the project.

```
Usage: /deps-check
```

[View skill file](../skills/deps-check/SKILL.md)

### /incident-response — Production incident helper

Pulls together Sentry errors, BetterStack logs, recent deploys, and relevant code changes to help debug production incidents.

```
Usage: /incident-response SENTRY-ISSUE-ID
```

[View skill file](../skills/incident-response/SKILL.md)

---

## Writing Your Own Skills

Create a file at `.claude/skills/<skill-name>/SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does (shown in /help)
disable-model-invocation: true
---

Your prompt template here. Use $ARGUMENTS for user input.

1. Step one
2. Step two
3. Step three
```

**Key frontmatter options:**
- `name` — the slash command name
- `description` — shown when browsing skills
- `disable-model-invocation: true` — only invoke manually (not auto-triggered by Claude)
- `model` — override the model for this skill (e.g., `haiku` for fast tasks)

**Tips:**
- Keep skills focused on one workflow
- Use numbered steps so Claude follows a predictable sequence
- Reference specific tools and commands Claude should use
- Put situational knowledge in skills instead of CLAUDE.md (keeps CLAUDE.md lean)
