# Claude Code: Skills, Tips & Best Practices

A guide for setting up Claude Code and its ecosystem for Nori development. Covers MCP servers, plugins, hooks, skills, and best practices organized by domain.

> **This repo is the source of truth** for our team's Claude Code configuration and recommendations.

---

## Table of Contents

- [Quick Setup](#quick-setup)
- [MCP Servers](#mcp-servers)
- [Plugins](#plugins)
- [Hooks](#hooks)
- [Skills](#skills)
- [CLAUDE.md Best Practices](#claudemd-best-practices)
- [CLI Tips & Tricks](#cli-tips--tricks)
- [Workflow Patterns](#workflow-patterns)
- [Scheduled Tasks & Remote Agents](#scheduled-tasks--remote-agents)
- [Domain-Specific Guides](#domain-specific-guides)
  - [Backend (FastAPI / Python)](#backend-fastapi--python)
  - [Frontend / Mobile (React Native / Expo)](#frontend--mobile-react-native--expo)
  - [Infrastructure (Render / GitHub Actions)](#infrastructure-render--github-actions)
  - [Security](#security)

---

## Quick Setup

After installing [Claude Code](https://docs.anthropic.com/en/docs/claude-code), run these commands to configure the core integrations:

```bash
# MCP Servers
claude mcp add-json linear-server --scope user \
  '{"type":"http","url":"https://mcp.linear.app/mcp"}'

claude mcp add-json betterstack --scope user \
  '{"type":"http","url":"https://mcp.betterstack.com"}'

claude mcp add-json helpscout --scope user \
  '{"command":"npx","args":["help-scout-mcp-server"],"env":{"HELPSCOUT_APP_ID":"<your-app-id>","HELPSCOUT_APP_SECRET":"<your-app-secret>"}}'

claude mcp add-json langsmith --scope user \
  '{"command":"uvx","args":["langsmith-mcp-server"],"env":{"LANGSMITH_API_KEY":"<your-api-key>","LANGSMITH_WORKSPACE_ID":"<your-workspace-id>"}}'

claude mcp add-json github --scope user \
  '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer <your-github-pat>"}}'

claude mcp add --transport http --scope user sentry \
  https://mcp.sentry.dev/mcp

claude mcp add-json postgres --scope user \
  '{"command":"npx","args":["-y","@modelcontextprotocol/server-postgres","postgresql://localhost/nori_development"]}'

claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp

# Plugins (run inside Claude Code)
/plugin    # then enable: pr-review-toolkit, code-review, code-simplifier, figma, github
```

Then copy the [hooks configuration](#notification-hooks-recommended-for-everyone) into `~/.claude/settings.json`.

---

## MCP Servers

MCP (Model Context Protocol) servers give Claude direct access to external tools and data.

**Vetting criteria:** Each server below is either (1) officially maintained by the product owner or (2) actively maintained with strong community adoption. Apply the same bar when adding new ones.

**Scope:** All commands use `--scope user` (global). For project-specific MCPs, replace with `--scope project` (run from within that project directory).

### Linear

Read/create/update issues, projects, cycles, documents, and comments directly from Claude Code. No more context-switching to Linear — ask Claude to create issues, check sprint status, or update tickets as part of your workflow.

```bash
claude mcp add-json linear-server --scope user \
  '{"type":"http","url":"https://mcp.linear.app/mcp"}'
```

On first use, it will prompt you to authenticate via browser (OAuth).

### BetterStack

Query logs, analyze telemetry data, check uptime monitors, and browse dashboards. Debug production issues without leaving your terminal.

```bash
claude mcp add-json betterstack --scope user \
  '{"type":"http","url":"https://mcp.betterstack.com"}'
```

Authenticates via OAuth (browser prompt) or API token. See [BetterStack MCP docs](https://docs.betterstack.com/mcp) for token-based setup.

### Help Scout

Search customer conversations, read threads, list inboxes. When debugging user-reported issues, Claude can pull up the original support conversation for full context.

```bash
claude mcp add-json helpscout --scope user \
  '{"command":"npx","args":["help-scout-mcp-server"],"env":{"HELPSCOUT_APP_ID":"<your-app-id>","HELPSCOUT_APP_SECRET":"<your-app-secret>"}}'
```

Get credentials by creating a Private App in Help Scout (My Apps). Uses OAuth2 Client Credentials — personal access tokens are not supported.

### LangSmith

Fetch conversation traces, prompts, datasets, experiments, and billing info. Debug our AI agent pipeline — inspect traces, review prompt performance, and analyze experiment results without opening the LangSmith UI.

```bash
claude mcp add-json langsmith --scope user \
  '{"command":"uvx","args":["langsmith-mcp-server"],"env":{"LANGSMITH_API_KEY":"<your-api-key>","LANGSMITH_WORKSPACE_ID":"<your-workspace-id>"}}'
```

Get your API key and workspace ID from [LangSmith settings](https://smith.langchain.com/settings). The workspace ID is required since our key has access to multiple workspaces.

### GitHub

Search repos, manage PRs/issues, read code, and interact with GitHub's API. The MCP server gives Claude richer, structured access to GitHub data — especially useful for cross-repo searches and bulk operations.

```bash
claude mcp add-json github --scope user \
  '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer <your-github-pat>"}}'
```

Create a [Personal Access Token](https://github.com/settings/tokens) with `repo` scope. If you already have `gh` CLI authenticated, the GitHub MCP is optional — Claude uses `gh` effectively for most PR/issue workflows.

> **Note:** The deprecated `@modelcontextprotocol/server-github` npm package no longer works. Use the official remote server above.

### Sentry

Query error issues, stack traces, release health, and Seer AI analysis. When debugging production errors, Claude can pull up the exact stack trace, affected users, and error frequency — then fix the bug in the same session.

```bash
claude mcp add --transport http --scope user sentry \
  https://mcp.sentry.dev/mcp
```

Authenticates via OAuth (browser prompt). No API key needed.

### PostgreSQL

Read-only access to your local dev database — inspect schema, run queries, and explore data. Claude can check table structures, query test data, and verify migrations. You can also connect with read-only creds to production data for debugging. **Never connect with non-readonly creds.**

```bash
claude mcp add-json postgres --scope user \
  '{"command":"npx","args":["-y","@modelcontextprotocol/server-postgres","postgresql://localhost/nori_development"]}'
```

Update the connection string to match your local setup.

### Context7

Fetches up-to-date, version-specific documentation for libraries directly into Claude's context. Prevents Claude from hallucinating outdated APIs — especially useful for React Native, Expo, FastAPI, SQLAlchemy, and LangGraph.

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
```

Works without an API key for basic usage. For higher rate limits, get a free key at [context7.com/dashboard](https://context7.com/dashboard).

---

## Plugins

Plugins bundle skills, hooks, agents, and tools into installable packages. Enable them via `/plugin` in Claude Code.

### pr-review-toolkit

Comprehensive PR review with specialized sub-agents for code quality, test coverage, error handling, type design, comment accuracy, and silent failure detection.

**How to use:** Run `/pr-review-toolkit:review-pr` or just ask Claude to review a PR.

### code-review

Automated code review against project guidelines and best practices.

**How to use:** Run `/code-review:code-review` on a PR.

### code-simplifier

Simplifies and refines recently written code for clarity and maintainability while preserving functionality. Claude uses it automatically after writing code, or invoke manually.

### figma

Translates Figma designs into production-ready code:
- `/figma:implement-design` — implement a Figma design
- `/figma:code-connect-components` — map Figma components to code
- `/figma:create-design-system-rules` — generate design system rules

### github

Adds GitHub-aware skills and workflows to Claude Code.

### swift-lsp

Gives Claude precise symbol navigation and automatic error detection for Swift code via LSP. Helps Claude understand our Swift native modules and Expo plugins accurately.

### Other Plugins Worth Considering

Run `/plugin` and browse the Discover tab:
- **Playwright** — browser automation and E2E testing
- **Security Guidance** — security best practices and vulnerability detection

---

## Hooks

Hooks are shell commands that run automatically at specific points in Claude's lifecycle. Unlike CLAUDE.md instructions (which are advisory), hooks are **deterministic** — they always execute.

### Notification Hooks (recommended for everyone)

Send macOS notifications when Claude is waiting for input or has finished responding. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Awaiting your input\" with title \"Claude Code\"'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Response ready\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Auto-Format After Edits

Runs Prettier on every file Claude edits (project-level `.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

> **Note:** We have git pre-commit hooks, and those are generally preferable to Claude hooks for formatting. But this pattern is useful for other auto-corrections.

### Block Edits to Protected Files

Prevent Claude from modifying `.env`, lock files, or generated directories:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "file=$(jq -r '.tool_input.file_path // empty'); if echo \"$file\" | grep -qE '(\\.env|\\.lock|node_modules/|dist/)'; then echo 'BLOCK: Protected file' >&2; exit 1; fi"
          }
        ]
      }
    ]
  }
}
```

### All Available Hook Events

| Event | When it fires |
|-------|--------------|
| `SessionStart` | Session begins or resumes |
| `UserPromptSubmit` | You submit a prompt, before Claude processes it |
| `PreToolUse` | Before a tool call — can block it |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `Notification` | Claude sends a notification |
| `Stop` | Claude finishes responding |
| `SubagentStart` | A subagent is spawned |
| `SubagentStop` | A subagent finishes |
| `ConfigChange` | A config file changes during session |
| `PreCompact` | Before context compaction |
| `SessionEnd` | Session terminates |

---

## Skills

Skills are reusable workflows invoked via slash commands. They live in `.claude/skills/` (project-level, shared with team) or `~/.claude/skills/` (personal).

Ready-to-use skill files are in the [`skills/`](skills/) directory. Copy them to your project's `.claude/skills/` or personal `~/.claude/skills/`.

| Skill | Description |
|-------|-------------|
| [`/fix-issue`](skills/fix-issue/SKILL.md) | Fix a GitHub issue end-to-end |
| [`/review-my-changes`](skills/review-my-changes/SKILL.md) | Self-review staged/unstaged changes before PR |
| [`/security-audit`](skills/security-audit/SKILL.md) | OWASP Top 10 audit + secret scanning + dependency check |
| [`/deps-check`](skills/deps-check/SKILL.md) | Audit dependencies for vulnerabilities and staleness |
| [`/incident-response`](skills/incident-response/SKILL.md) | Correlate Sentry errors, BetterStack logs, and recent deploys |

### Writing Your Own Skills

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
```

**Tips:**
- Keep skills focused on one workflow
- Use numbered steps so Claude follows a predictable sequence
- Reference specific tools and commands Claude should use
- Put situational knowledge in skills instead of CLAUDE.md (keeps CLAUDE.md lean)

---

## CLAUDE.md Best Practices

### What to Include

- **Bash commands Claude can't guess** — build commands, test runners, env setup
- **Code style rules that differ from defaults** — your specific patterns
- **Architectural decisions** — e.g., Expo config, never edit `ios/` directly
- **Common gotchas** — message API patterns, health data sync quirks
- **Testing conventions** — how to run tests, what frameworks you use

### What NOT to Include

- Anything Claude can figure out by reading the code
- Standard language conventions Claude already knows
- Long explanations or tutorials (link to docs instead)
- Information that changes frequently

### Key Principles

1. **Keep it under 150 lines.** Bloated CLAUDE.md files cause Claude to ignore instructions. For each line: "Would removing this cause Claude to make mistakes?" If not, cut it.
2. **Use emphasis for critical rules.** `IMPORTANT:`, `CRITICAL:`, `NEVER` improve adherence.
3. **Put the most critical rules at the top.** "Never push/commit/merge without permission" should be first.
4. **Treat it like code.** Review when things go wrong, prune regularly.
5. **Use skills for situational knowledge.** If something only matters sometimes, make it a skill.
6. **Use conditional tags** for domain-specific rules: `<important if="...">` tags prevent Claude from ignoring rules as files grow.

### File Placement

| Location | Scope |
|----------|-------|
| `~/.claude/CLAUDE.md` | All your Claude sessions (personal) |
| `./CLAUDE.md` | Project root — committed and shared with team |
| `./CLAUDE.local.md` | Project root — gitignored, personal overrides |
| `./src/CLAUDE.md` | Subdirectory — loaded when Claude works in `src/` |

### Subdirectory CLAUDE.md Files

Adding CLAUDE.md files to sub-directories keeps the root concise and improves consistency for specific areas. Examples for our stack:

- `app/routers/CLAUDE.md` — API endpoint conventions, FastAPI patterns, auth middleware rules
- `app/workers/CLAUDE.md` — TaskIQ worker patterns, dedup middleware, queue routing
- `app/agents/CLAUDE.md` — LangGraph agent patterns, tool conventions, state management
- `components/CLAUDE.md` — React Native component patterns, Skia usage, animation conventions
- `services/CLAUDE.md` — Health data sync patterns, OAuth flow conventions

---

## CLI Tips & Tricks

### Essential Keybindings

| Shortcut | Action |
|----------|--------|
| `Esc` | Stop Claude mid-action |
| `Esc` + `Esc` | Rewind to previous state |
| `Shift+Tab` (x2) | Toggle Plan Mode |
| `Shift+Tab` (x1) | Toggle Fast Mode |
| `/clear` | Clear context for a fresh start |
| `/compact <focus>` | Summarize context with specific focus |

### Session Management

```bash
claude --continue          # Resume the most recent session
claude --resume            # Pick from recent sessions
/rename oauth-migration    # Name a session for easy retrieval
claude --cwd /path/to/project  # Start in a specific directory
```

### Context Management

The single most important productivity lever. Claude's context window fills up, and performance degrades.

- **Run `/clear` between unrelated tasks.** Don't do multiple unrelated tasks in one session.
- **Use `/compact <focus>`** to summarize (e.g., `/compact Focus on the API changes`).
- **Use subagents for research.** "Use subagents to investigate X" — they explore in a separate context.
- **Scope your requests.** "Look at the auth module" not "investigate how the app works."

### Parallel Worktrees

Spin up 3-5 worktrees, each running its own Claude session in parallel:

```bash
claude --worktree   # each gets its own branch, session, and file system state
```

### Plan Mode

For non-trivial tasks (`Shift+Tab` x2): describe what you want, iterate on the approach, then exit Plan Mode for Claude to execute. Prevents premature coding.

### Piping Input

```bash
cat error.log | claude "what's causing these errors?"
gh pr diff 1234 | claude "review this PR for security issues"
gh issue view 456 | claude "fix this issue"
```

### Prompting Tips

- **Be specific.** "Fix the login bug" → "Users report login fails after session timeout. Check the auth flow in `src/auth/`, especially token refresh."
- **Provide verification.** Give Claude tests, expected outputs, or screenshots.
- **Reference patterns.** "Look at how `UserService` is implemented and follow the same pattern."
- **Let Claude interview you.** "I want to build [X]. Interview me about requirements using AskUserQuestion."
- **Course-correct early.** Hit `Esc` to stop. Use `/rewind` or `Esc`+`Esc` to restore.

---

## Workflow Patterns

### Plan/Execute/Clear Loop

The most effective general-purpose workflow:
1. **Plan** — Enter Plan Mode, describe what you want, iterate
2. **Execute** — Exit Plan Mode, Claude implements
3. **Clear** — `/clear` before the next task

### Large Feature Development

1. **Write a strong spec.** Collaborate with Claude — provide lots of feedback and product direction (1-2 hours focused).
2. **Use Codepipe's plan phase** to ground the spec in the actual codebase.
3. **Create Linear tickets from the spec.** Keep tickets focused — PRs of a few hundred lines go much smoother.
4. **Set up a Codepipe pipeline.** Tell Claude to familiarize itself with Codepipe first. Branch dependencies when tickets depend on each other; parallelize when independent.
5. **Run the pipeline** on Mac Mini. Codepipe reads from Linear, runs Claude skills, goes through Greptile reviews, ensures CI passes.
6. **Review PRs thoroughly.** Leave comments, pull them into a Claude Code session to discuss and fix.
7. **Merge and manually test.** Manual e2e testing consistently catches things automated checks miss.

### Bug Fixing

```
"Users report [specific symptom]. Check [specific area].
Here's the Sentry issue: [link or ID]"
```

### The Interview Pattern

For large or ambiguous features:
```
"I want to build [X]. Interview me about requirements before we start."
```

### Multi-Agent Patterns

- **Subagents for research:** "Use subagents to investigate X" — keeps main context clean.
- **Background agents:** "Use a background subagent to research Y while I continue on X."
- **Parallel worktrees:** Run independent tickets simultaneously with `claude --worktree`.

---

## Scheduled Tasks & Remote Agents

### /loop — Session-Scoped Scheduling

```
/loop 5m /review-my-changes
/loop 30m check Sentry for new unresolved errors
/loop 1h check PR status and summarize new review comments
```

Supported intervals: `s`, `m`, `h`, `d`. Up to 50 tasks per session, auto-expire after 3 days.

### /schedule — Persistent Scheduled Tasks

Survives restarts, runs as long as the Claude Code desktop app is open. Select a repo, define a cron schedule, write a prompt.

### Cloud-Based Scheduling

Schedule tasks that run even when your machine is off — select a repo, define a cron, write the prompt.

### Remote Control

Bridges your local Claude Code terminal with claude.ai/code, iOS, and Android apps. Your full local environment stays available.

```bash
claude --remote
```

---

## Domain-Specific Guides

### Backend (FastAPI / Python)

**Relevant MCPs:** PostgreSQL, LangSmith, Sentry, BetterStack

**Useful prompts:**
```
# Debug a failing API endpoint
"This endpoint is returning 500. Check the Sentry error, trace the request through the router → service → model layers."

# Review a migration
"Review this Alembic migration. Check for: missing indexes, destructive operations, data loss risk, reversibility."

# Debug TaskIQ workers
"Workers in taskiq-worker-long-running are backing up. Check Redis stream length, consumer groups, and recent task durations via BetterStack."

# Debug LangGraph agent
"The MainAgent is looping on tool calls. Use LangSmith to pull the trace for conversation_id X and identify where it gets stuck."

# Review service code
"Review this service for our patterns: async/await, proper error handling, no Optional fields with defaults (per CLAUDE.md), RequestBaseModel/ResponseBaseModel usage."
```

**Skills for backend:**
- `/fix-issue` — reads the issue, finds code, implements fix, runs `pytest`
- `/review-my-changes` — checks for missing error handling, pattern violations
- `/security-audit` — checks for injection, auth bypass, PII exposure
- `/incident-response` — correlates Sentry + BetterStack + recent deploys

**Tips:**
- Connect the PostgreSQL MCP to your local dev DB for schema inspection and query testing
- Use LangSmith MCP to debug agent traces without leaving the terminal
- When writing new services, tell Claude to follow the pattern in an existing service
- For Alembic migrations, always ask Claude to check for the migration hash update

### Frontend / Mobile (React Native / Expo)

**Relevant MCPs:** Context7 (for up-to-date Expo/RN docs), Sentry, GitHub

**Useful prompts:**
```
# Implement a new screen
"Create a new screen at app/(tabs)/settings/notifications.tsx following the pattern in app/(tabs)/settings/index.tsx. Use our existing components from components/."

# Debug health data sync
"Apple HealthKit sync is failing silently. Check hooks/useHealthSync.ts, services/healthSyncService.ts, and the background fetch config."

# Review component
"Review this component for: proper use of react-native-reanimated, missing cleanup in useEffect, correct TypeScript types, flash-list vs FlatList usage."

# Expo config
"Add a new Expo config plugin for [feature]. Follow the pattern in plugins/withProguard.js. NEVER edit ios/ or android/ directly."
```

**Skills for frontend:**
- `/review-my-changes` — catches missing TypeScript types, pattern violations
- `/fix-issue` — reads issue, finds relevant components/hooks/services

**Tips:**
- Use Context7 MCP to get current Expo/React Native docs — prevents hallucinated APIs
- Never let Claude edit `ios/` or `android/` directly — always use Expo config plugins
- For Maestro E2E tests, reference existing flows in `maestro/`
- Use the figma plugin to translate designs to components

### Infrastructure (Render / GitHub Actions)

**Relevant MCPs:** BetterStack, Sentry, GitHub

**Useful prompts:**
```
# Debug a Render deploy
"The latest deploy to Render failed. Check the GitHub Actions run and Render deploy logs."

# Review render.yaml changes
"Review this render.yaml change. Check for: correct service types, proper env var references, worker scaling settings."

# Debug GitHub Actions
gh run view --log-failed | claude "why did this CI run fail?"

# Review CI pipeline
"Review .github/workflows/test-and-gate.yml for: missing test steps, incorrect env setup, proper PostgreSQL service config."

# Worker scaling
"TaskIQ workers are overloaded. Review render.yaml worker configs and suggest scaling changes based on BetterStack metrics."
```

**Tips:**
- Pipe CI failure output directly to Claude: `gh run view --log-failed | claude "fix this"`
- Use BetterStack MCP to check service health and worker heartbeats
- Never let Claude modify production env vars directly — review all render.yaml changes
- For deploy issues, check both GitHub Actions logs and Render deploy logs

### Security

**Relevant MCPs:** Sentry, PostgreSQL (read-only), GitHub

**Key skill:** [`/security-audit`](skills/security-audit/SKILL.md) — OWASP Top 10 audit with secret scanning and dependency check

**Useful prompts:**
```
# Audit an API endpoint
"Audit this endpoint for: SQL injection (SQLAlchemy), auth bypass, missing rate limiting, PII exposure in responses."

# Check for secrets
"Scan the codebase for hardcoded API keys, passwords, tokens, and secrets in source code, config files, and test fixtures."

# Dependency audit
"Run pip-audit and npm audit. Summarize critical/high vulnerabilities with CVE IDs and recommended fixes."

# Review auth flow
"Review the OAuth2 flow in app/routers/auth.py. Check token validation, session management, and credential storage."

# PII check
"Check if any PII (health data, email, phone) is being logged. We use Presidio for redaction — verify it's applied consistently."
```

**Tips:**
- Use the `/security-audit` skill before major releases
- Run `/deps-check` regularly — `pip-audit` for backend, `npm audit` for mobile
- Always connect to databases with read-only credentials
- Check that Presidio PII redaction is applied to all log outputs
- Use the [claude-code-security-review](https://github.com/anthropics/claude-code-security-review) GitHub Action for automated PR security scanning

---

## Contributing

When adding a new MCP, plugin, or skill:
1. **Official first** — prefer servers maintained by the product owner
2. **Community second** — only if actively maintained with strong adoption
3. **Document it** — add a section explaining what it does and why it matters
4. **Test it** — verify it works with our stack before recommending
