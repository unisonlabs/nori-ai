# MCP Servers

MCP (Model Context Protocol) servers give Claude direct access to external tools and data.

**Vetting criteria:** Each server below is either (1) officially maintained by the company that owns the product (e.g., Linear, GitHub, Sentry, BetterStack) or (2) actively maintained with strong community adoption. If you want to add a new MCP, apply the same bar.

**Scope:** All commands use `--scope user` so they apply globally across all projects. For project-specific MCPs, replace with `--scope project` (run from within that project directory).

---

## Linear

**What it does:** Read/create/update issues, projects, cycles, documents, and comments directly from Claude Code.

**Why it matters:** No more context-switching to Linear. Ask Claude to create issues, check sprint status, or update tickets as part of your workflow.

```bash
claude mcp add-json linear-server --scope user \
  '{"type":"http","url":"https://mcp.linear.app/mcp"}'
```

On first use, it will prompt you to authenticate via browser (OAuth).

---

## BetterStack

**What it does:** Query logs, analyze telemetry data, check uptime monitors, and browse dashboards.

**Why it matters:** Debug production issues without leaving your terminal. Ask Claude to query recent error logs or check if a service is healthy.

```bash
claude mcp add-json betterstack --scope user \
  '{"type":"http","url":"https://mcp.betterstack.com"}'
```

Authenticates via OAuth (browser prompt) or API token. See [BetterStack MCP docs](https://docs.betterstack.com/mcp) for token-based setup.

---

## Help Scout

**What it does:** Search customer conversations, read threads, list inboxes.

**Why it matters:** When debugging user-reported issues, Claude can pull up the original support conversation for full context.

```bash
claude mcp add-json helpscout --scope user \
  '{"command":"npx","args":["help-scout-mcp-server"],"env":{"HELPSCOUT_APP_ID":"<your-app-id>","HELPSCOUT_APP_SECRET":"<your-app-secret>"}}'
```

Get credentials by creating a Private App in Help Scout (My Apps). Uses OAuth2 Client Credentials — personal access tokens are not supported. See the [help-scout-mcp-server repo](https://github.com/helpscout/help-scout-mcp-server) for details.

---

## LangSmith

**What it does:** Fetch conversation traces, prompts, datasets, experiments, and billing info from LangSmith.

**Why it matters:** Debug our AI agent pipeline — inspect traces, review prompt performance, and analyze experiment results without opening the LangSmith UI.

```bash
claude mcp add-json langsmith --scope user \
  '{"command":"uvx","args":["langsmith-mcp-server"],"env":{"LANGSMITH_API_KEY":"<your-api-key>","LANGSMITH_WORKSPACE_ID":"<your-workspace-id>"}}'
```

Get your API key and workspace ID from [LangSmith settings](https://smith.langchain.com/settings). The workspace ID is required if your key has access to multiple workspaces (which ours does). See the [langsmith-mcp-server repo](https://github.com/langchain-ai/langsmith-mcp-server) for details.

---

## GitHub

**What it does:** Search repos, manage PRs/issues, read code, and interact with GitHub's API.

**Why it matters:** Claude already uses the `gh` CLI, but the MCP server gives it richer, structured access to GitHub data — especially useful for cross-repo searches and bulk operations.

```bash
claude mcp add-json github --scope user \
  '{"type":"http","url":"https://api.githubcopilot.com/mcp","headers":{"Authorization":"Bearer <your-github-pat>"}}'
```

Create a [Personal Access Token](https://github.com/settings/tokens) with `repo` scope. This uses GitHub's hosted remote MCP server (no Docker required). See [GitHub's MCP server repo](https://github.com/github/github-mcp-server) for alternative setup options.

> **Note:** The deprecated `@modelcontextprotocol/server-github` npm package no longer works. Use the official remote server above. If you already have `gh` CLI authenticated, the GitHub MCP is optional — Claude uses `gh` effectively for most PR/issue workflows.

---

## Sentry

**What it does:** Query error issues, stack traces, release health, and Seer AI analysis from Sentry.

**Why it matters:** When debugging production errors, Claude can pull up the exact stack trace, affected users, and error frequency — then fix the bug in the same session.

```bash
claude mcp add --transport http --scope user sentry \
  https://mcp.sentry.dev/mcp
```

Authenticates via OAuth (browser prompt). During auth you can select which tool groups to enable. No API key needed. See [Sentry MCP docs](https://docs.sentry.io/product/integrations/mcp/) for details.

---

## PostgreSQL

**What it does:** Read-only access to your local dev database — inspect schema, run queries, and explore data.

**Why it matters:** Claude can check table structures, query test data, and verify migrations without you having to copy-paste SQL output. You can also connect with read-only creds to production data for debugging. **Never connect with non-readonly creds.**

```bash
claude mcp add-json postgres --scope user \
  '{"command":"npx","args":["-y","@modelcontextprotocol/server-postgres","postgresql://localhost/nori_development"]}'
```

Update the connection string to match your local setup. This is read-only by default. See the [postgres-mcp-server repo](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres) for options.

---

## Context7

**What it does:** Fetches up-to-date, version-specific documentation for libraries directly into Claude's context.

**Why it matters:** Prevents Claude from hallucinating outdated APIs. When working with React Native, Expo, or any library, Context7 pulls the current docs so Claude uses the right APIs for your actual dependency versions.

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
```

Works without an API key for basic usage. For higher rate limits, get a free key at [context7.com/dashboard](https://context7.com/dashboard). See the [Context7 repo](https://github.com/upstash/context7) for details.

---

## Other MCPs Worth Considering

| MCP | Purpose | Link |
|-----|---------|------|
| **Terraform** | Plan/apply infrastructure, query state files | [terraform-mcp-server](https://github.com/hashicorp/terraform-mcp-server) |
| **AWS** | Query CloudWatch, S3, IAM, and other AWS services | [aws-mcp-server](https://github.com/aws/aws-mcp-servers) |
| **Kubernetes** | Query cluster state, pods, logs, deployments | [kubernetes-mcp-server](https://github.com/strowk/mcp-k8s-go) |
| **Docker** | Manage containers, images, compose stacks | [docker-mcp-server](https://github.com/docker/docker-mcp) |
| **Playwright** | Browser automation and E2E testing | Available via `/plugin` |
| **Slack** | Read/send messages, search channels | [slack-mcp-server](https://github.com/modelcontextprotocol/servers/tree/main/src/slack) |
