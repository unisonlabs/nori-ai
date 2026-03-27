.PHONY: setup mcps skills hooks plugins check clean

# ──────────────────────────────────────────────
# Full setup — run this on day one
# ──────────────────────────────────────────────

setup: mcps skills hooks plugins
	@echo ""
	@echo "✅ Setup complete. Run 'make check' to verify."

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
	@echo "→ Installing PostgreSQL MCP (read-only, local dev DB)..."
	@claude mcp add-json postgres --scope user \
		'{"command":"npx","args":["-y","@modelcontextprotocol/server-postgres","postgresql://localhost/nori_development"]}' 2>/dev/null || true

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
# Skills — copy to personal ~/.claude/skills/
# ──────────────────────────────────────────────

SKILL_DIRS := fix-issue review-my-changes security-audit deps-check incident-response

skills:
	@echo "→ Copying skills to ~/.claude/skills/..."
	@mkdir -p $(addprefix ~/.claude/skills/,$(SKILL_DIRS))
	@$(foreach dir,$(SKILL_DIRS),cp skills/$(dir)/SKILL.md ~/.claude/skills/$(dir)/SKILL.md;)
	@echo "  Installed: $(SKILL_DIRS)"

# ──────────────────────────────────────────────
# Hooks — notification hooks for macOS
# ──────────────────────────────────────────────

hooks:
	@echo "→ Installing notification hooks..."
	@claude config set hooks.Notification '[{"hooks":[{"type":"command","command":"osascript -e '\''display notification \"Awaiting your input\" with title \"Claude Code\"'\''"}]}]' 2>/dev/null || \
		(echo "  ⚠️  Auto-install failed. Copy hooks manually from GUIDE.md")

	@claude config set hooks.Stop '[{"hooks":[{"type":"command","command":"osascript -e '\''display notification \"Response ready\" with title \"Claude Code\"'\''"}]}]' 2>/dev/null || true

# ──────────────────────────────────────────────
# Plugins — remind user to enable in Claude Code
# ──────────────────────────────────────────────

plugins:
	@echo ""
	@echo "→ Plugins must be enabled inside Claude Code."
	@echo "  Run /plugin and enable:"
	@echo "    • pr-review-toolkit"
	@echo "    • code-review"
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
	@echo "MCP Servers:"
	@claude mcp list --scope user 2>/dev/null || echo "  ⚠️  Could not list MCPs"
	@echo ""
	@echo "Skills:"
	@$(foreach dir,$(SKILL_DIRS),\
		if [ -f ~/.claude/skills/$(dir)/SKILL.md ]; then \
			echo "  ✓ /$(dir)"; \
		else \
			echo "  ✗ /$(dir) — run 'make skills'"; \
		fi;)
	@echo ""
	@echo "CLI tools:"
	@which claude >/dev/null 2>&1 && echo "  ✓ claude" || echo "  ✗ claude — install from https://docs.anthropic.com/en/docs/claude-code"
	@which gh >/dev/null 2>&1 && echo "  ✓ gh" || echo "  ✗ gh — install from https://cli.github.com"

# ──────────────────────────────────────────────
# Clean — remove installed skills
# ──────────────────────────────────────────────

clean:
	@echo "→ Removing skills from ~/.claude/skills/..."
	@$(foreach dir,$(SKILL_DIRS),rm -rf ~/.claude/skills/$(dir);)
	@echo "  Done. MCPs and hooks are left in place."
