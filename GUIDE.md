# Guide

The full playbook for using Claude Code at Nori. Start with `make setup` in the repo root, then read the sections relevant to your work.

---

## Tools

### MCP Servers

MCP servers give Claude direct access to external tools and data. We only adopt MCPs that are (1) officially maintained by the product owner or (2) actively maintained with strong community adoption.

| MCP | What it gives Claude | Auth |
|-----|---------------------|------|
| **Linear** | Read/create/update issues, projects, cycles | OAuth (browser prompt) |
| **BetterStack** | Query logs, uptime monitors, dashboards | OAuth (browser prompt) |
| **Sentry** | Error issues, stack traces, release health, Seer AI analysis | OAuth (browser prompt) |
| **PostgreSQL** | Read-only access to local dev DB — schema, queries, data | Connection string |
| **Context7** | Up-to-date library docs (Expo, React Native, FastAPI, etc.) | None (optional API key for rate limits) |
| **Help Scout** | Customer conversations, threads, inboxes | OAuth2 Client Credentials ([create a Private App](https://developer.helpscout.com/mailbox-api/overview/authentication/)) |
| **LangSmith** | Agent traces, prompts, datasets, experiments | API key + workspace ID ([settings](https://smith.langchain.com/settings)) |
| **GitHub** | Repos, PRs, issues, code search | PAT with `repo` scope ([create one](https://github.com/settings/tokens)) — optional if `gh` CLI is authenticated |

All servers are installed with `--scope user` (global). Run `make mcps` to install, or see the [Makefile](Makefile) for individual commands.

### Plugins

Enable via `/plugin` inside Claude Code:

| Plugin | What it does |
|--------|-------------|
| **pr-review-toolkit** | PR review with sub-agents for code quality, test coverage, error handling, type design, silent failures. Run `/pr-review-toolkit:review-pr`. |
| **code-simplifier** | Auto-simplifies code after Claude writes it. Also invokable manually. |
| **figma** | Translates Figma designs to code. `/figma:implement-design`, `/figma:code-connect-components`, `/figma:create-design-system-rules`. |
| **github** | GitHub-aware skills and workflows. |
| **swift-lsp** | LSP-powered symbol navigation and error detection for Swift native modules. |
| **Playwright** | Browser automation and E2E testing. Worth considering. |

---

## Tips by Domain

### Backend (FastAPI / Python)

**MCPs to use:** PostgreSQL, LangSmith, Sentry, BetterStack

**Gotchas and patterns:**
- Connect the PostgreSQL MCP to your local dev DB — Claude can inspect schema and verify migrations without you copy-pasting SQL
- Use LangSmith MCP to debug agent traces inline. "Pull the LangSmith trace for conversation_id X" is faster than switching to the UI
- When writing new services, always tell Claude to follow an existing service as a reference pattern — our conventions (async/await, no Optional with defaults, RequestBaseModel/ResponseBaseModel) won't be obvious otherwise
- For Alembic migrations: always ask Claude to check for the migration hash update (`migrations/migration-hash.txt`). The pre-commit hook handles this normally, but Claude bypasses hooks
- Our TaskIQ workers have specialized queues (short-running, long-running, metrics, backfill). When debugging worker issues, point Claude at the specific worker type and ask it to check Redis stream length and BetterStack heartbeats
- Claude tends to guess database column names and types. Force it to check via the PostgreSQL MCP or by reading the model files

### Frontend / Mobile (React Native / Expo)

**MCPs to use:** Context7, Sentry

**Gotchas and patterns:**
- **NEVER let Claude edit `ios/` or `android/` directly.** Always use Expo config plugins. Point it at `plugins/withProguard.js` as a reference
- Use Context7 MCP for all Expo/React Native work — Claude will otherwise hallucinate outdated APIs, especially for Expo SDK 54
- For new screens, always reference an existing screen in `app/(tabs)/` so Claude picks up our routing and layout patterns
- Our health data sync uses parallel uploads with gzip compression. When debugging sync issues, the chain is: `hooks/useHealthSync.ts` → `services/healthSyncService.ts` → background fetch config
- We use `react-native-reanimated` for animations and `@shopify/react-native-skia` for rendering. Claude defaults to Animated API — redirect it
- For Maestro E2E tests, reference existing flows in `maestro/`
- `flash-list` not `FlatList` for performant lists

### Infrastructure (Render / GitHub Actions)

**MCPs to use:** BetterStack, GitHub

**Gotchas and patterns:**
- We deploy on **Render**, not AWS/GCP directly. Infrastructure is defined in `render.yaml`
- Never let Claude modify production env vars directly — all changes go through `render.yaml` review
- For CI failures: `gh run view --log-failed | claude "why did this fail?"` is the fastest debug loop
- Our CI is two workflows: `test-and-gate.yml` (runs pytest with PostgreSQL 16 + pgvector + Redis) and `deploy.yml` (triggered on main after tests pass, deploys via Render API)
- Worker scaling changes go through `render.yaml`. Claude can suggest changes but always review — worker configs affect our TaskIQ queue routing
- BetterStack has heartbeat monitoring per worker (`BETTERSTACK_HEARTBEAT_URL_<WORKER>`) — use the MCP to check if workers are healthy

### Security

**MCPs to use:** Sentry, PostgreSQL (read-only)

**Gotchas and patterns:**
- Run `/security-audit` before major releases — it checks OWASP Top 10, scans for hardcoded secrets, and runs `pip-audit` + `npm audit`
- We use **Presidio** for PII redaction in logs. When reviewing logging code, verify redaction is applied — especially for health data
- Always connect Claude to databases with **read-only** credentials. The PostgreSQL MCP is read-only by default
- Our auth uses JWT (ES256) — when reviewing auth code, check token validation, session management, and that secrets aren't logged
- For dependency audits: `pip-audit` (backend) and `npm audit` (mobile). Run `/deps-check` regularly
- Consider adding the [claude-code-security-review](https://github.com/anthropics/claude-code-security-review) GitHub Action for automated PR security scanning

---

## Workflow Patterns

### Plan / Execute / Clear

The most effective general workflow:
1. **Plan** — `Shift+Tab` x2 to enter Plan Mode. Describe what you want, iterate on the approach
2. **Execute** — exit Plan Mode, Claude implements
3. **Clear** — `/clear` before the next unrelated task

Context pollution from mixing tasks in one session is the #1 cause of bad output.

### Large Feature Development (with Codepipe)

1. **Write a strong spec.** Collaborate with Claude — provide heavy feedback and product direction. Takes 1-2 hours focused. Use [Codepipe's](https://github.com/unisonlabs/codepipe) plan phase to ground the spec in the actual codebase
2. **Create Linear tickets from the spec.** Keep tickets focused — PRs of a few hundred lines go smoother. Feed the spec into Claude and ask it to create the tickets
3. **Set up a Codepipe pipeline.** Tell Claude to familiarize itself with Codepipe first. Branch dependencies when tickets depend on each other; parallelize when independent
4. **Run the pipeline** on Mac Mini. Codepipe reads from Linear, runs configured skills, goes through Greptile reviews, ensures CI passes
5. **Review PRs.** Go through each, leave comments, pull them into a Claude Code session to discuss and fix
6. **Merge and manually test.** E2e manual testing consistently catches things automated checks miss — formatting, UX, integration quirks

### Context Management

- **`/clear` between unrelated tasks.** Most important habit
- **`/compact <focus>`** to summarize with focus (e.g., `/compact Focus on the API changes`)
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

### Principles

1. **Under 150 lines.** Bloated files get ignored. "Would removing this cause Claude to make mistakes?" If not, cut it
2. **Critical rules at the top.** "Never push/commit/merge without permission" first
3. **`IMPORTANT:` / `NEVER` markers** improve adherence
4. **Skills for situational knowledge.** If it only matters sometimes, it's a skill, not a CLAUDE.md rule
5. **Subdirectory CLAUDE.md files** keep root concise. Examples: `app/routers/CLAUDE.md`, `app/workers/CLAUDE.md`, `components/CLAUDE.md`

For the full reference on CLAUDE.md file placement and structure, see [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/claude-md).
