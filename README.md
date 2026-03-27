# Claude Code: Skills, Tips & Best Practices

Our team's setup and playbook for Claude Code. Run the setup, read the guide, ship faster.

## Getting Started

```bash
git clone git@github.com:unisonlabs/claude-skills-tips.git
cd claude-skills-tips
make setup
```

`make setup` installs MCP servers and configures notification hooks. Some MCPs require credentials — the Makefile will prompt you with instructions for those. After setup, **open Claude Code and run `/plugin`** to enable plugins (this step can't be automated):

- pr-review-toolkit
- code-simplifier
- figma
- github
- swift-lsp

Run `make check` at any time to verify your setup.

## What's in this repo

| Path | What it is |
|------|-----------|
| [GUIDE.md](GUIDE.md) | The full playbook — tools, tips, workflows |
| [Makefile](Makefile) | Automated setup for MCPs, hooks, plugins |
| [hooks.json](hooks.json) | Notification hook definitions |

## Skills

Skills are committed in each project repo under `.claude/skills/` — they're shared with the team via git, not installed separately.

| Skill | What it does | Repos |
|-------|-------------|-------|
| `/fix-issue` | Fix a Linear ticket end-to-end | [backend](https://github.com/unisonlabs/nori-backend/blob/main/.claude/skills/fix-issue/SKILL.md) · [mobile](https://github.com/unisonlabs/nori-mobile/blob/main/.claude/skills/fix-issue/SKILL.md) |
| `/review-my-changes` | Self-review changes before PR | [backend](https://github.com/unisonlabs/nori-backend/blob/main/.claude/skills/review-my-changes/SKILL.md) · [mobile](https://github.com/unisonlabs/nori-mobile/blob/main/.claude/skills/review-my-changes/SKILL.md) |
| `/security-audit` | OWASP Top 10 + secret scan + dependency audit | [backend](https://github.com/unisonlabs/nori-backend/blob/main/.claude/skills/security-audit/SKILL.md) · [mobile](https://github.com/unisonlabs/nori-mobile/blob/main/.claude/skills/security-audit/SKILL.md) |
| `/deps-check` | Audit dependencies for vulnerabilities and staleness | [backend](https://github.com/unisonlabs/nori-backend/blob/main/.claude/skills/deps-check/SKILL.md) · [mobile](https://github.com/unisonlabs/nori-mobile/blob/main/.claude/skills/deps-check/SKILL.md) |
| `/incident-response` | Correlate Sentry + BetterStack + deploys for incidents | [backend](https://github.com/unisonlabs/nori-backend/blob/main/.claude/skills/incident-response/SKILL.md) |

## Related Repos

| Repo | What it is |
|------|-----------|
| [nori-backend](https://github.com/unisonlabs/nori-backend) | FastAPI backend — see its [CLAUDE.md](https://github.com/unisonlabs/nori-backend/blob/main/CLAUDE.md) and subdirectory CLAUDE.md files for conventions |
| [nori-mobile](https://github.com/unisonlabs/nori-mobile) | React Native / Expo mobile app — see its [CLAUDE.md](https://github.com/unisonlabs/nori-mobile/blob/main/CLAUDE.md) |
| [codepipe](https://github.com/unisonlabs/codepipe) | Pipeline orchestrator for multi-task Claude workflows — see [examples/nori_defaults.py](https://github.com/unisonlabs/codepipe/blob/main/examples/nori_defaults.py) for our shared pipeline config |

## External Resources

- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code) — official reference
- [Claude Code Best Practices](https://docs.anthropic.com/en/docs/claude-code/best-practices) — Anthropic's recommendations
- [Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) — all hook events, schemas, and patterns
- [Skills Reference](https://docs.anthropic.com/en/docs/claude-code/skills) — how to write and use skills
- [MCP Server Docs](https://docs.anthropic.com/en/docs/claude-code/mcp-servers) — MCP setup and configuration
