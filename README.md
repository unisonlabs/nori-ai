# Claude Code Skills, Tips & Best Practices

A guide for setting up Claude Code and its ecosystem for maximum developer productivity. Covers MCP servers, plugins, hooks, skills, CLI tips, infrastructure patterns, security workflows, and best practices for full-stack engineering.

> **NOTE:** This repo is the source of truth for our team's Claude Code configuration and recommendations.

## Table of Contents

- [Quick Setup](#quick-setup)
- [MCP Servers](docs/mcp-servers.md)
- [Plugins](docs/plugins.md)
- [Hooks](docs/hooks.md)
- [Skills](docs/skills.md) (reusable slash-command workflows)
- [CLAUDE.md Best Practices](docs/claude-md-best-practices.md)
- [CLI Tips & Tricks](docs/cli-tips.md)
- [Infrastructure & DevOps](docs/infrastructure-devops.md)
- [Security Workflows](docs/security.md)
- [Workflow Patterns](docs/workflow-patterns.md)
- [Scheduled Tasks & Remote Agents](docs/scheduled-tasks.md)

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

Then copy the [hooks configuration](docs/hooks.md) into `~/.claude/settings.json`.

## Repo Structure

```
skills/               # Ready-to-use SKILL.md files (copy to .claude/skills/)
docs/                 # Detailed guides for each topic
```

## Contributing

When adding a new MCP, plugin, or skill, apply the same vetting bar:
1. **Official first** — prefer servers maintained by the product owner (Linear, GitHub, Sentry, etc.)
2. **Community second** — only if actively maintained with strong adoption
3. **Document it** — add a section explaining what it does and why it matters
