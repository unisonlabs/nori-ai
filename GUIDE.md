# Guide

The full playbook for using Claude Code at Nori. Start with `make setup` in the repo root, then read the sections relevant to your work.

For background on Claude Code concepts, see the [official docs](https://docs.anthropic.com/en/docs/claude-code):
- **[MCP servers](https://docs.anthropic.com/en/docs/claude-code/mcp-servers)** connect Claude to external services (Linear, Sentry, databases, etc.)
- **[Skills](https://docs.anthropic.com/en/docs/claude-code/skills)** are reusable workflows you invoke as slash commands (e.g., `/fix-issue`)
- **[Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)** are shell commands that auto-run at specific points in Claude's lifecycle
- **[Plugins](https://code.claude.com/docs/en/discover-plugins)** extend Claude Code with skills, agents, hooks, and MCP servers. The other bullet points above are subsets of plugins. For example, the pr-review-toolkit plugin will utilize several skills.

---

## Tools

### MCP Servers

We only adopt MCPs that are (1) officially maintained by the product owner or (2) actively maintained with strong community adoption.

> **Tool access philosophy:** CLI over curl over MCP — in that order of preference. MCPs require browser-based OAuth re-auth which is painful on headless Mac mini setups. Use CLIs and direct API calls where possible. MCPs are a fallback for services with no good CLI or API.

**We prefer CLIs and direct API calls over MCPs.** The priority order is: CLI → curl → MCP. On the Mac mini remote dev environment, MCPs require periodic OAuth re-auth via browser which is disruptive for long-running agent sessions. `gh` for GitHub, `sentry-cli` for Sentry, and `psql` for databases are the primary tools. For services without a good CLI (Linear, BetterStack, Help Scout, LangSmith), use curl with API keys stored in environment variables.

| MCP | What it gives Claude | CLI/curl alternative | Auth |
|-----|---------------------|----------------------|------|
| **Linear** | Read/create/update issues, projects, cycles | curl to Linear GraphQL API | OAuth (browser prompt) |
| **BetterStack** | Query logs, uptime monitors, dashboards | curl to BetterStack API | OAuth (browser prompt) |
| **Sentry** | Error issues, stack traces, release health, Seer AI analysis | `sentry-cli` | OAuth (browser prompt) |
| **PostgreSQL** | Read-only access to dev and production DBs — schema, queries, data | `psql` with readonly connection string | `DATABASE_URL` env var |
| **Context7** | Up-to-date library docs (Expo, React Native, FastAPI, etc.) | curl | None (optional API key for rate limits) |
| **Help Scout** | Customer conversations, threads, inboxes | curl to Help Scout API | OAuth2 Client Credentials |
| **LangSmith** | Agent traces, prompts, datasets, experiments | curl to LangSmith API | API key + workspace ID |
| **GitHub** | Repos, PRs, issues, code search | `gh` CLI (preferred) | PAT with `repo` scope — optional if `gh` CLI is authenticated |

All servers are installed with `--scope user` (global). Run `make mcps` to install the OAuth-based ones automatically. For the credential-based ones (Help Scout, LangSmith, GitHub), `make setup` prints the exact commands — you just fill in your keys.

**Getting credentials:**
- **Help Scout:** Create a Private App in Help Scout → My Apps ([docs](https://developer.helpscout.com/mailbox-api/overview/authentication/)). Copy the App ID and App Secret.
- **LangSmith:** Get your API key and workspace ID from [LangSmith settings](https://smith.langchain.com/settings). The workspace ID is required since our key has access to multiple workspaces.
- **GitHub:** Create a [Personal Access Token](https://github.com/settings/tokens) with `repo` scope. Optional if you already have `gh` CLI authenticated — Claude uses `gh` effectively for most workflows.
- **PostgreSQL:** Set `DATABASE_URL` in your shell environment. The Makefile reads it automatically. **Pro tip:** Also add a read-only production connection string to your dotenv (e.g., `DATABASE_URL_PROD_READONLY`). Being able to query production data for debugging is a gamechanger — Claude can look up real user data, check migration state, and verify production behavior without you having to run queries manually. **Never use a non-readonly connection string.**

### Plugins

Enable via `/plugin` inside Claude Code (can't be automated):

| Plugin | What it does |
|--------|-------------|
| **pr-review-toolkit** | PR review with sub-agents for code quality, test coverage, error handling, type design, silent failures. Run `/pr-review-toolkit:review-pr`. |
| **code-simplifier** | Auto-simplifies code after Claude writes it. Also invokable manually. |
| **figma** | Translates Figma designs to code. `/figma:implement-design`, `/figma:code-connect-components`, `/figma:create-design-system-rules`. |
| **github** | GitHub-aware skills and workflows. |
| **swift-lsp** | LSP-powered symbol navigation and error detection for Swift native modules. |
| **codex** ([openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)) | Delegate tasks to OpenAI Codex from Claude Code. `/codex:rescue` for investigation/fixes, `/codex:review` for code review, `/codex:adversarial-review` for challenge reviews. Requires `npm install -g @openai/codex`. |

---

## Agent Infrastructure

Nori runs always-on autonomous agents on the Mac mini. Each agent is a dedicated macOS user running [Mom](https://github.com/badlogic/pi-mono/tree/main/packages/mom) (a Slack-connected wrapper around the Pi coding agent) with scoped credentials and an isolated workspace.

### Architecture

```
Slack channel (#nori-errors)
    ↓ @mention
Mom bot (running as nori-bug-agent macOS user)
    ↓
Pi agent (Read, Write, Edit, Bash tools)
    ↓ investigates using CLI tools and curl
GitHub, Sentry, Linear, BetterStack, LangSmith, Help Scout, PostgreSQL (readonly)
    ↓
Opens PR → posts link in Slack → waits for human review
```

Each agent:
- Runs as its own macOS user with a separate home directory
- Has only the credentials it needs (scoped readonly tokens where possible)
- Cannot access other users' home directories
- Has an AGENTS.md that defines its purpose, guardrails, and self-improvement instructions
- Learns over time by documenting findings and building reusable tools

### Current agents

| Agent | macOS user | Slack channel | Purpose |
|-------|-----------|---------------|---------|
| Bug agent | `nori-bug-agent` | `#nori-errors` | Investigate and fix bugs from Sentry |

### Adding a new agent

1. Create `agents/<agent-name>/` in nori-ai repo
2. Write `AGENTS.md` — purpose, tools, guardrails, self-improvement instructions
3. Write `setup.sh` — calls `scripts/setup-agent.sh` with agent config
4. Add `make setup-<agent-name>` to Makefile
5. Add to the agents table in README.md and this guide
6. Create the Slack channel and invite the bot

### Debugging agents

Check if the agent process is running:
```bash
launchctl list | grep nori-bug-agent
```

Check logs:
```bash
tail -f /Users/nori-bug-agent/nori/nori-agent/data/logs/mom.log
```

Restart the agent:
```bash
launchctl stop com.nori.nori-bug-agent
launchctl start com.nori.nori-bug-agent
```

SSH in as the agent user to inspect her workspace:
```bash
sudo su - nori-bug-agent
ls ~/nori/nori-agent/data/
cat ~/nori/nori-agent/data/learnings.md
```

### Process supervision

Agents run via launchd (macOS native process supervision) rather than tmux. launchd auto-restarts the agent if it crashes and starts it automatically on Mac mini reboot. Logs are written to the agent's data directory.

> **Note on Docker:** Docker was evaluated and deprioritized due to macOS/Linux mismatch friction (agents can't use brew, keychain, or native tools inside a Linux container). launchd + isolated macOS users provides equivalent isolation with less complexity. Docker may be revisited if the agent fleet grows significantly.

---

## Tips by Domain

**Navigation:** If you're working on the backend API, read [Backend](#backend-fastapi--python). Mobile app? [Frontend](#frontend--mobile-react-native--expo). Deploys or CI? [Infrastructure](#infrastructure-render--github-actions). Any of the above with a security lens? [Security](#security).

### Backend (FastAPI / Python)

**MCPs to use:** PostgreSQL, LangSmith, Sentry, BetterStack

**Our CLAUDE.md files:** [root](https://github.com/unisonlabs/nori-backend/blob/main/CLAUDE.md) · [agents](https://github.com/unisonlabs/nori-backend/blob/main/app/agents/nori_agent/v2/CLAUDE.md) · [conversation eval](https://github.com/unisonlabs/nori-backend/blob/main/app/services/conversation_eval/CLAUDE.md) · [workers](https://github.com/unisonlabs/nori-backend/blob/main/app/workers/taskiq/CLAUDE.md) · [tests](https://github.com/unisonlabs/nori-backend/blob/main/tests/CLAUDE.md) · [loinc data](https://github.com/unisonlabs/nori-backend/blob/main/data/loinc/CLAUDE.md)
We won't keep this list up-to-date as more are added. Please be mindful of adding CLAUDE.md's where they'd be useful (: Having one in most meaty subdirectories is helpful.

**Gotchas and patterns:**
- Connect the PostgreSQL MCP to your local dev DB — Claude can inspect schema and verify migrations without you copy-pasting SQL
- Use LangSmith MCP to debug agent traces inline. "Pull the LangSmith trace for conversation_id X" is faster than switching to the UI
- When writing new services, always tell Claude to follow an existing service as a reference pattern — our conventions (async/await, no Optional with defaults, RequestBaseModel/ResponseBaseModel) won't be obvious otherwise
- For Alembic migrations: ALWAYS auto-generate migration files (`alembic revision --autogenerate`), never write them by hand. Also always ask Claude to check for the migration hash update (`migrations/migration-hash.txt`) — the pre-commit hook handles this normally, but Claude bypasses hooks
- Our TaskIQ workers have specialized queues (short-running, long-running, metrics, backfill). When debugging worker issues, point Claude at the specific worker type and ask it to check Redis stream length and BetterStack heartbeats
- Claude tends to guess database column names and types. Force it to check via the PostgreSQL MCP or by reading the model files

### Frontend / Mobile (React Native / Expo)

**MCPs to use:** Context7, Sentry

**Our CLAUDE.md files:** [root](https://github.com/unisonlabs/nori-mobile/blob/main/CLAUDE.md) · [components/sections](https://github.com/unisonlabs/nori-mobile/blob/main/components/sections/CLAUDE.md)

**Gotchas and patterns:**
- **NEVER let Claude edit `ios/` or `android/` directly.** Always use Expo config plugins. Point it at `plugins/withProguard.js` as a reference
- Use Context7 MCP for all Expo/React Native work — Claude will otherwise hallucinate outdated APIs, especially for Expo SDK 54
- For new screens, always reference an existing screen in `app/(tabs)/` so Claude picks up our routing and layout patterns
- Our health data sync uses parallel uploads with gzip compression. When debugging sync issues, the chain is: `hooks/useHealthSync.ts` → `services/healthSyncService.ts` → background fetch config
- We use `react-native-reanimated` for animations and `@shopify/react-native-skia` for rendering. Claude defaults to Animated API — redirect it
- `flash-list` not `FlatList` for performant lists

### Infrastructure (Render / GitHub Actions)

**MCPs to use:** BetterStack, GitHub

**Gotchas and patterns:**
- We deploy on **Render**, not AWS/GCP directly. Infrastructure is defined in `render.yaml`
- Never let Claude modify production env vars directly — all changes go through `render.yaml` review
- For CI failures: `gh run view --log-failed | claude "why did this fail?"` is the fastest debug loop
- Our CI is two workflows: `test-and-gate.yml` (runs pytest with PostgreSQL 16 + pgvector + Redis) and `deploy.yml` (triggered on main after tests pass, deploys via `scripts/deploy.py` → Render API)
- We introduced auto-scaling for workers [here](https://github.com/unisonlabs/nori-backend/tree/main/autoscaler)
- BetterStack has heartbeat monitoring per worker (`BETTERSTACK_HEARTBEAT_URL_<WORKER>`) — use the MCP to check if workers are healthy

### Security

**MCPs to use:** Sentry, PostgreSQL (read-only)

**Gotchas and patterns:**
- Run `/security-audit` before major releases — it checks OWASP Top 10, scans for hardcoded secrets, and runs `poetry audit` + `npm audit`
- We use **Presidio** for PII redaction in logs. When reviewing logging code, verify redaction is applied — especially for health data
- Always connect Claude to databases with **read-only** credentials. The PostgreSQL MCP is read-only by default
- Our auth uses JWT (ES256) with email/phone verification codes (no passwords) — when reviewing auth code, check token validation, code expiry, and that secrets aren't logged
- For dependency audits: `poetry audit` (backend) and `npm audit` (mobile). Run `/deps-check` regularly

---

## Workflow Patterns

### Plan / Execute / Clear

The most effective general workflow:
1. **Plan** — `Shift+Tab` x2 to enter Plan Mode. Describe what you want, iterate on the approach
2. **Execute** — exit Plan Mode, Claude implements
3. **Clear** — `/clear` before the next unrelated task

Context pollution from mixing tasks in one session is the #1 cause of bad output. Sometimes, I'll even run a separate claude session and ask it to thoroughly review a PR before I push it to a draft. The better a PR is before we let Greptile review, the more positive signal we can get from Greptile.

### Large Feature Development (with Codepipe)

See the [Codepipe repo](https://github.com/unisonlabs/codepipe) for full docs and [examples/nori_defaults.py](https://github.com/unisonlabs/codepipe/blob/main/examples/nori_defaults.py) for our shared pipeline configuration.

1. **Write a strong spec.** Collaborate with Claude — provide heavy feedback and product direction. Takes 1-2 hours focused, sometimes more for larger tasks! It is _not_ worth rushing this part of the process...
2. **Create Linear tickets from the spec.** Keep tickets focused — PRs of a few hundred lines go smoother. Feed the spec into Claude and ask it to create the tickets. Direct it to split up work in an optimal way: what can be parallelized? how can we structure tickets so that they don't lead to huge diffs? Reduce merge conflicts, etc.
3. **Set up a Codepipe pipeline.** Tell Claude to familiarize itself with Codepipe first. Branch dependencies when tickets depend on each other; parallelize when independent
    - Ideally we'd have a persistent agent that is familiar with Codepipe that we can leverage for writing codepipe pipelines. I will look into this.
4. **Run the pipeline.** Codepipe reads from Linear, runs configured skills (e.g., `/simplify`, `/review-my-changes`), goes through Greptile reviews, ensures CI passes
5. **Review PRs.** Go through each, leave comments, pull them into a Claude Code session to discuss and fix
6. **Merge and manually test.** E2e manual testing consistently catches things automated checks miss — formatting, UX, integration quirks

All Codepipe best practices are in the project README.

### Context Management

- **`/clear` between unrelated tasks.** Most important habit
- **`/compact <focus>`** to summarize with focus (e.g., `/compact Focus on the API changes`)
- **`/btw` for side questions.** Ask Claude a quick question without interrupting your current task or polluting conversation context. The answer appears in an overlay and never enters the conversation history. Great for "what does this function do?" or "remind me what we decided about X" while Claude is mid-task
- **Subagents for research.** "Use subagents to investigate X" — explores in a separate context
- **Scope requests.** "Look at the auth module" not "investigate how the app works"
- **Name sessions** with `/rename` (e.g., "oauth-migration") for easy retrieval via `claude --resume`

### Parallel Work

- **Worktrees:** `claude --worktree` — each gets its own branch, session, and filesystem. Run 3-5 in parallel for independent tickets
- **Background agents:** "Use a background subagent to research Y while I continue on X"

### The Interview Pattern

For large or ambiguous features, let Claude drive requirements gathering:
```
"I want to build [X]. Interview me about requirements before we start."
```

### Prompting

- **Be specific.** Reference files, line numbers, and constraints. "Fix the login bug" → "Users report login fails after session timeout. Check `src/auth/`, especially token refresh."
- **Reference patterns.** "Follow the same pattern as `UserService`."
- **Provide verification.** Give Claude tests or expected outputs
- **Course-correct early.** `Esc` to stop, `Esc`+`Esc` to rewind

---

## Scheduled Tasks & Remote Agents

### /loop — Recurring Tasks (Session-Scoped)

```
/loop 5m /review-my-changes
/loop 30m check Sentry for new unresolved errors
/loop 1h check PR status and summarize new review comments
```

Up to 50 per session, auto-expire after 3 days. See [scheduled tasks docs](https://code.claude.com/docs/en/scheduled-tasks).

### /schedule — Persistent Tasks

Survives restarts, runs as long as the desktop app is open. See [scheduled tasks docs](https://code.claude.com/docs/en/scheduled-tasks).

### Remote Control

Connect your local Claude Code session to claude.ai/code or the mobile apps with `claude --remote`. Your full local environment stays available. See [remote control docs](https://code.claude.com/docs/en/remote-control).

---

## CLAUDE.md Best Practices

Our existing CLAUDE.md files: [nori-backend](https://github.com/unisonlabs/nori-backend/blob/main/CLAUDE.md) · [nori-mobile](https://github.com/unisonlabs/nori-mobile/blob/main/CLAUDE.md)

### Principles

1. **Under 150 lines.** Bloated files get ignored. "Would removing this cause Claude to make mistakes?" If not, cut it
2. **Critical rules at the top.** "Never push/commit/merge without permission" first
3. **`IMPORTANT:` / `NEVER` markers** improve adherence
4. **Skills for situational knowledge.** If it only matters sometimes, it's a skill, not a CLAUDE.md rule
5. **Subdirectory CLAUDE.md files** keep root concise. We already have them in [agents](https://github.com/unisonlabs/nori-backend/blob/main/app/agents/nori_agent/v2/CLAUDE.md), [workers](https://github.com/unisonlabs/nori-backend/blob/main/app/workers/taskiq/CLAUDE.md), [tests](https://github.com/unisonlabs/nori-backend/blob/main/tests/CLAUDE.md), and [components/sections](https://github.com/unisonlabs/nori-mobile/blob/main/components/sections/CLAUDE.md)

For the full reference on CLAUDE.md structure, see [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/claude-md).
