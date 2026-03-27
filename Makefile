.PHONY: setup mcps hooks plugins check

# ──────────────────────────────────────────────
# Full setup — run this on day one
# ──────────────────────────────────────────────

setup: mcps hooks plugins
	@echo ""
	@echo "Setup complete. Run 'make check' to verify."

# ──────────────────────────────────────────────
# MCP Servers
# ──────────────────────────────────────────────

mcps: mcp-linear mcp-betterstack mcp-sentry mcp-postgres mcp-context7 mcp-helpscout mcp-langsmith mcp-github

mcp-linear:
	@echo "→ Installing Linear MCP (OAuth — will prompt in browser on first use)..."
	@claude mcp add-json linear-server --scope user \
		'{"type":"http","url":"https://mcp.linear.app/mcp"}' 2>/dev/null || true

mcp-betterstack:
	@echo "→ Installing BetterStack MCP (OAuth — will prompt in browser on first use)..."
	@claude mcp add-json betterstack --scope user \
		'{"type":"http","url":"https://mcp.betterstack.com"}' 2>/dev/null || true

mcp-sentry:
	@echo "→ Installing Sentry MCP (OAuth — will prompt in browser on first use)..."
	@claude mcp add --transport http --scope user sentry \
		https://mcp.sentry.dev/mcp 2>/dev/null || true

mcp-postgres:
	@if [ -z "$$DATABASE_URL" ]; then \
		echo "→ Skipping PostgreSQL MCP — DATABASE_URL is not set."; \
		echo "  Set DATABASE_URL in your environment, then re-run 'make mcp-postgres'."; \
	else \
		echo "→ Installing PostgreSQL MCP (read-only, using DATABASE_URL)..."; \
		claude mcp add-json postgres --scope user \
			"{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-postgres\",\"$$DATABASE_URL\"]}" 2>/dev/null || true; \
	fi

mcp-context7:
	@echo "→ Installing Context7 MCP (library docs)..."
	@claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp 2>/dev/null || true

mcp-helpscout:
	@echo ""
	@echo "→ Help Scout MCP requires credentials."
	@echo "  Create a Private App in Help Scout → My Apps (OAuth2 Client Credentials)."
	@echo "  Then run:"
	@echo "    claude mcp add-json helpscout --scope user \\"
	@echo "      '{\"command\":\"npx\",\"args\":[\"help-scout-mcp-server\"],\"env\":{\"HELPSCOUT_APP_ID\":\"<id>\",\"HELPSCOUT_APP_SECRET\":\"<secret>\"}}'"
	@echo ""

mcp-langsmith:
	@echo ""
	@echo "→ LangSmith MCP requires credentials."
	@echo "  Get your API key and workspace ID from https://smith.langchain.com/settings"
	@echo "  Then run:"
	@echo "    claude mcp add-json langsmith --scope user \\"
	@echo "      '{\"command\":\"uvx\",\"args\":[\"langsmith-mcp-server\"],\"env\":{\"LANGSMITH_API_KEY\":\"<key>\",\"LANGSMITH_WORKSPACE_ID\":\"<id>\"}}'"
	@echo ""

mcp-github:
	@echo ""
	@echo "→ GitHub MCP requires a Personal Access Token with 'repo' scope."
	@echo "  Create one at https://github.com/settings/tokens"
	@echo "  Then run:"
	@echo "    claude mcp add-json github --scope user \\"
	@echo "      '{\"type\":\"http\",\"url\":\"https://api.githubcopilot.com/mcp\",\"headers\":{\"Authorization\":\"Bearer <pat>\"}}'"
	@echo "  (Optional if you already have 'gh' CLI authenticated.)"
	@echo ""

# ──────────────────────────────────────────────
# Hooks — notification hooks for macOS
# ──────────────────────────────────────────────

SETTINGS_FILE := $(HOME)/.claude/settings.json

hooks:
	@echo "→ Installing notification hooks into $(SETTINGS_FILE)..."
	@mkdir -p $(HOME)/.claude
	@if [ -f "$(SETTINGS_FILE)" ]; then \
		jq --slurpfile hooks hooks.json '.hooks = ((.hooks // {}) * $$hooks[0])' "$(SETTINGS_FILE)" > "$(SETTINGS_FILE).tmp" && \
		mv "$(SETTINGS_FILE).tmp" "$(SETTINGS_FILE)" && \
		echo "  ✓ Hooks merged into existing settings.json"; \
	else \
		jq -n --slurpfile hooks hooks.json '{hooks: $$hooks[0]}' > "$(SETTINGS_FILE)" && \
		echo "  ✓ Created settings.json with hooks"; \
	fi

# ──────────────────────────────────────────────
# Plugins — remind user to enable in Claude Code
# ──────────────────────────────────────────────

plugins:
	@echo ""
	@echo "→ Plugins must be enabled inside Claude Code."
	@echo "  Run /plugin and enable:"
	@echo "    • pr-review-toolkit"
	@echo "    • code-simplifier"
	@echo "    • figma"
	@echo "    • github"
	@echo "    • swift-lsp"
	@echo ""

# ──────────────────────────────────────────────
# Check — verify setup
# ──────────────────────────────────────────────

check:
	@echo "Checking setup..."
	@echo ""
	@echo "Prerequisites:"
	@which claude >/dev/null 2>&1 && echo "  ✓ claude" || echo "  ✗ claude — install from https://docs.anthropic.com/en/docs/claude-code"
	@which gh >/dev/null 2>&1 && echo "  ✓ gh" || echo "  ✗ gh — install from https://cli.github.com"
	@which jq >/dev/null 2>&1 && echo "  ✓ jq" || echo "  ✗ jq — install with: brew install jq"
	@which npx >/dev/null 2>&1 && echo "  ✓ npx" || echo "  ✗ npx — install Node.js from https://nodejs.org"
	@echo ""
	@echo "MCP Servers:"
	@claude mcp list --scope user 2>/dev/null || echo "  ⚠️  Could not list MCPs"
	@echo ""
	@echo "Hooks:"
	@if [ -f "$(SETTINGS_FILE)" ] && jq -e '.hooks.Notification' "$(SETTINGS_FILE)" >/dev/null 2>&1; then \
		echo "  ✓ Notification hooks installed"; \
	else \
		echo "  ✗ Notification hooks missing — run 'make hooks'"; \
	fi
