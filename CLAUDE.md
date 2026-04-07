# nori-ai

Central home for AI/LLM infrastructure at Nori — engineer setup, agent configs, and tooling.

## Repo purpose

This repo has two audiences:
- **Engineers** — setup scripts and Claude Code playbook
- **Agents** — AGENTS.md files loaded at agent startup

README.md is engineer-facing. AGENTS.md files are agent-facing. Never mix the two.

## File layout

| Path | What it is |
|------|-----------|
| `scripts/setup-engineer.sh` | Interactive Mac mini setup for engineers |
| `scripts/setup-agent.sh` | Shared agent setup logic (called by agent setup scripts) |
| `agents/<name>/AGENTS.md` | Agent instructions and guardrails |
| `agents/<name>/setup.sh` | Agent user creation and environment setup |
| `agents/<name>/tools/` | Wrapper scripts the agent builds for itself |
| `GUIDE.md` | Claude Code tips and workflows for engineers |
| `hooks.json` | Claude Code notification hooks |

## Conventions

- **Scripts must be idempotent** — safe to run multiple times without side effects
- **Scripts are interactive** — prompt for each value, show existing values masked, ask to confirm
- **CLI over curl over MCP** — always prefer CLI tools, fall back to curl with API keys, use MCPs only as last resort
- **AGENTS.md files are for agents, not engineers** — write them in second person ("You are...", "Your job is...")
- **One macOS user per agent** — each agent runs in isolation with its own home directory and scoped credentials
- **Secrets go in `.env` files with `chmod 600`**, not in `.zshrc`

## Adding a new agent

1. Create `agents/<agent-name>/` directory
2. Write `AGENTS.md` — who the agent is, what it can access, hard guardrails, self-improvement instructions
3. Write `setup.sh` — calls `scripts/setup-agent.sh` with agent-specific config
4. Add `make setup-<agent-name>` target to Makefile
5. Add the agent to the table in README.md

## Important

- Never commit API keys or tokens
- Never move skills out of the product repos — they stay in nori-backend and nori-mobile under `.claude/skills/`
- Run `make check` to verify engineer setup is working
