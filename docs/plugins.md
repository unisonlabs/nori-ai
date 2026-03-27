# Plugins

Plugins bundle skills, hooks, agents, and tools into installable packages. Enable them via `/plugin` in Claude Code.

---

## pr-review-toolkit

**What it does:** Comprehensive PR review with specialized sub-agents for code quality, test coverage, error handling, type design, comment accuracy, and silent failure detection.

**How to use:** Run `/pr-review-toolkit:review-pr` or just ask Claude to review a PR.

**Sub-agents included:**
- `code-reviewer` — checks adherence to project guidelines and style
- `silent-failure-hunter` — finds inadequate error handling and swallowed exceptions
- `code-simplifier` — simplifies code for clarity while preserving functionality
- `comment-analyzer` — checks comment accuracy and maintainability
- `pr-test-analyzer` — reviews test coverage quality and completeness
- `type-design-analyzer` — analyzes type design for encapsulation and invariants

---

## code-review

**What it does:** Automated code review against project guidelines and best practices.

**How to use:** Run `/code-review:code-review` on a PR.

---

## code-simplifier

**What it does:** Simplifies and refines recently written code for clarity and maintainability while preserving functionality.

**How to use:** Claude uses it automatically after writing code, or invoke manually.

---

## figma

**What it does:** Translates Figma designs into production-ready code. Also supports Code Connect for mapping Figma components to code components.

**How to use:**
- `/figma:implement-design` — implement a Figma design
- `/figma:code-connect-components` — map Figma components to code
- `/figma:create-design-system-rules` — generate design system rules for your project

Requires the Figma MCP server connection (configured automatically by the plugin).

---

## github

**What it does:** Adds GitHub-aware skills and workflows to Claude Code.

---

## swift-lsp

**What it does:** Gives Claude precise symbol navigation and automatic error detection for Swift code via the Language Server Protocol.

**Why it matters:** For iOS/React Native projects, this helps Claude understand Swift native modules and Expo plugins accurately.

---

## Other Plugins Worth Considering

Run `/plugin` and browse the Discover tab. Popular ones:

- **Playwright** — browser automation and E2E testing
- **Security Guidance** — security best practices and vulnerability detection
- **Memory** — persistent memory across sessions
