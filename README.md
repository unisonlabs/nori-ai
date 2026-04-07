# nori-ai

Central home for AI/LLM infrastructure at Nori. This covers engineer setup on the Mac mini remote dev environment and the always-on agent infrastructure (Mom/Pi).

## For Engineers

All Nori engineers work on a shared Mac mini remote dev environment. On a fresh user account, first set up your SSH key for GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/unisonlabs/nori-ai/main/scripts/bootstrap-ssh.sh | bash
```

Then clone and run setup:

```bash
git clone git@github.com:unisonlabs/nori-ai.git ~/nori/nori-ai
cd ~/nori/nori-ai
./scripts/setup-engineer.sh
```

This installs everything you need: Homebrew, Python, Node, PostgreSQL, Redis, Claude Code, Pi, GitHub CLI, Sentry CLI, Tailscale, MCP servers, hooks, and clones the Nori repos. Run it on a fresh Mac mini user account. It's interactive and idempotent — safe to re-run.

After setup, open Claude Code and run `/plugin` to enable plugins (this can't be automated):
- pr-review-toolkit
- code-simplifier
- figma
- github
- swift-lsp
- codex

Run `make check` at any time to verify your setup.

## For Agents

Agent configs and guardrails live in `agents/`. Each agent runs as its own isolated macOS user on the Mac mini with scoped credentials and its own workspace.

| Agent | User | Slack channel | Setup |
|-------|------|---------------|-------|
| Bug agent | `nori-bug-agent` | `#nori-errors` | `make setup-bug-agent` |

## What's in this repo

| Path | What it is |
|------|-----------|
| `GUIDE.md` | Full Claude Code playbook — tools, tips, workflows |
| `Makefile` | Automated setup targets |
| `hooks.json` | Notification hook definitions |
| `scripts/setup-engineer.sh` | Engineer setup script |
| `agents/nori-bug-agent/` | Bug agent config and setup |

## Related Repos

| Repo | What it is |
|------|-----------|
| [nori-backend](https://github.com/unisonlabs/nori-backend) | FastAPI backend |
| [nori-mobile](https://github.com/unisonlabs/nori-mobile) | React Native / Expo mobile app |
| [codepipe](https://github.com/unisonlabs/codepipe) | Pipeline orchestrator for multi-task Claude workflows |
