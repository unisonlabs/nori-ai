# Claude Code: Skills, Tips & Best Practices

Our team's setup and playbook for Claude Code. Run the setup, copy the skills, read the guide.

## Getting Started

```bash
# Install all MCPs, copy skills, and configure hooks
make setup
```

That's it. See the [Makefile](Makefile) for what it does, or run individual targets:

```bash
make mcps          # Install MCP servers only
make skills        # Copy skills to ~/.claude/skills/
make hooks         # Install notification hooks
make check         # Verify everything is configured
```

Some MCPs require credentials — the Makefile will prompt you or skip if already configured. See [GUIDE.md](GUIDE.md) for credential setup details.

## What's in this repo

| Path | What it is |
|------|-----------|
| [GUIDE.md](GUIDE.md) | The full playbook — tools, tips, workflows |
| [Makefile](Makefile) | Automated setup for MCPs, plugins, hooks, skills |
| [skills/](skills/) | Ready-to-use Claude Code skills (slash commands) |

## Skills

Copy to `.claude/skills/` (project, shared) or `~/.claude/skills/` (personal). Or just run `make skills`.

| Skill | What it does |
|-------|-------------|
| [`/fix-issue`](skills/fix-issue/SKILL.md) | Fix a GitHub issue end-to-end |
| [`/review-my-changes`](skills/review-my-changes/SKILL.md) | Self-review changes before PR |
| [`/security-audit`](skills/security-audit/SKILL.md) | OWASP Top 10 + secret scan + dependency audit |
| [`/deps-check`](skills/deps-check/SKILL.md) | Audit dependencies for vulnerabilities and staleness |
| [`/incident-response`](skills/incident-response/SKILL.md) | Correlate Sentry + BetterStack + deploys for incidents |

## External Resources

- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code) — official reference
- [Claude Code Best Practices](https://docs.anthropic.com/en/docs/claude-code/best-practices) — Anthropic's recommendations
- [Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) — all hook events, schemas, and patterns
- [Skills Reference](https://docs.anthropic.com/en/docs/claude-code/skills) — how to write and use skills
- [MCP Server Docs](https://docs.anthropic.com/en/docs/claude-code/mcp-servers) — MCP setup and configuration
- [Codepipe](https://github.com/unisonlabs/codepipe) — our pipeline orchestrator for multi-task Claude workflows
