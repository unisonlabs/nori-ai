# CLAUDE.md Best Practices

The `CLAUDE.md` file is loaded into every Claude Code session. It's the most important tool for guiding Claude's behavior.

---

## What to Include

- **Bash commands Claude can't guess** — build commands, test runners, env setup
- **Code style rules that differ from defaults** — your specific patterns
- **Architectural decisions** — e.g., Expo config, never edit `ios/` directly
- **Common gotchas** — message API patterns, health data sync quirks
- **Testing conventions** — how to run tests, what frameworks you use

## What NOT to Include

- Anything Claude can figure out by reading the code
- Standard language conventions Claude already knows
- Long explanations or tutorials (link to docs instead)
- Information that changes frequently

---

## Key Principles

1. **Keep it under 150 lines.** Bloated CLAUDE.md files cause Claude to ignore instructions. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

2. **Use emphasis for critical rules.** Markers like `IMPORTANT:`, `CRITICAL:`, `NEVER` improve adherence.

3. **Put the most critical rules at the top.** Rules like "never push/commit/merge without permission" should be first.

4. **Treat it like code.** Review it when things go wrong, prune regularly, test changes by observing Claude's behavior.

5. **Use skills for situational knowledge.** If something only matters sometimes, make it a skill instead of putting it in CLAUDE.md.

6. **Use conditional tags for domain-specific rules.** Wrap rules in `<important if="...">` tags to prevent Claude from ignoring them as files grow longer.

---

## File Placement

| Location | Scope |
|----------|-------|
| `~/.claude/CLAUDE.md` | All your Claude sessions (personal) |
| `./CLAUDE.md` | Project root — committed and shared with team |
| `./CLAUDE.local.md` | Project root — gitignored, personal overrides |
| `./src/CLAUDE.md` | Subdirectory — loaded when Claude works in `src/` |

---

## Subdirectory CLAUDE.md Files

Adding `CLAUDE.md` files to sub-directories is a powerful pattern that lets you:
1. Keep your root CLAUDE.md concise
2. Improve consistency and reliability for specific areas of the codebase

**Examples:**
- `api/CLAUDE.md` — API conventions, endpoint patterns, middleware rules
- `mobile/CLAUDE.md` — React Native patterns, Expo config rules, platform-specific gotchas
- `infrastructure/CLAUDE.md` — Terraform conventions, never-apply-without-review rules
- `tests/CLAUDE.md` — testing frameworks, fixture patterns, mocking guidelines

---

## Example CLAUDE.md Structure

```markdown
IMPORTANT: Never push, commit, or merge without explicit permission.

## Build & Test
- `yarn dev` — start dev server
- `yarn test` — run test suite
- `yarn test:e2e` — run E2E tests (requires running server)

## Code Style
- Use named exports, not default exports
- Prefer `async/await` over `.then()` chains
- Error messages must be user-facing (no internal jargon)

## Architecture
- All API routes go through `src/api/routes/`
- Database migrations in `db/migrations/` — never edit existing ones
- NEVER edit files in `ios/` or `android/` directly — use Expo config plugins

## Common Gotchas
- The message API uses a polymorphic pattern — check MessageType enum
- Health data sync is eventually consistent — don't assert exact values in tests
```
