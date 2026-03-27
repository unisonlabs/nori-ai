# CLI Tips & Tricks

Power-user features and patterns for getting the most out of Claude Code.

---

## Essential Keybindings

| Shortcut | Action |
|----------|--------|
| `Esc` | Stop Claude mid-action |
| `Esc` + `Esc` | Rewind to previous state |
| `Shift+Tab` (x2) | Toggle Plan Mode |
| `Shift+Tab` (x1) | Toggle Fast Mode |
| `/clear` | Clear context for a fresh start |
| `/compact <focus>` | Summarize context with specific focus |

---

## Session Management

```bash
# Resume the most recent session
claude --continue

# Pick from recent sessions
claude --resume

# Name a session for easy retrieval
/rename oauth-migration

# Start Claude in a specific directory
claude --cwd /path/to/project
```

---

## Context Management

This is the single most important productivity lever. Claude's context window fills up, and performance degrades as it fills.

- **Run `/clear` between unrelated tasks.** The "kitchen sink session" is the most common mistake — doing multiple unrelated tasks in one session.
- **Use `/compact <focus>`** to summarize with specific focus (e.g., `/compact Focus on the API changes`).
- **Use subagents for research.** Say "use subagents to investigate X" — they explore in a separate context, keeping your main conversation clean.
- **Scope your requests.** "Look at the auth module" not "investigate how the app works."

---

## Parallel Worktrees

One of the biggest productivity unlocks. Spin up 3-5 worktrees, each running its own Claude session in parallel:

```bash
# Start Claude in an isolated worktree
claude --worktree

# Each worktree gets its own session, branch, and file system state
# Great for parallelizing independent tickets
```

---

## Plan Mode

For non-trivial tasks, use Plan Mode (Shift+Tab twice) to research and design before implementing:

1. Enter Plan Mode
2. Describe what you want to build
3. Claude researches the codebase and proposes an approach
4. You iterate on the plan
5. Exit Plan Mode — Claude executes the plan

This prevents Claude from diving into code prematurely and producing throw-away work.

---

## Fast Mode

Toggle with `Shift+Tab` (once) or `/fast`. Uses the same model but optimized for faster output. Good for:
- Simple edits and refactors
- File searches and exploration
- Quick questions about the codebase

---

## Piping Input

```bash
# Feed a file as context
cat error.log | claude "what's causing these errors?"

# Use with other CLI tools
gh pr diff 1234 | claude "review this PR for security issues"

# Pass a GitHub issue
gh issue view 456 | claude "fix this issue"
```

---

## Background Tasks

```bash
# Run a subagent in the background
"Use a background subagent to investigate the auth flow"

# You keep working while it researches
# Claude notifies you when the subagent finishes
```

---

## Useful CLI Flags

| Flag | Purpose |
|------|---------|
| `--continue` | Resume last session |
| `--resume` | Pick from recent sessions |
| `--worktree` | Run in an isolated git worktree |
| `--verbose` | Show detailed tool call info (debugging) |
| `--cwd <path>` | Start in a specific directory |
| `--model <model>` | Use a specific model |

---

## Prompting Tips

- **Be specific.** Reference files, line numbers, and constraints. "Fix the login bug" -> "Users report login fails after session timeout. Check the auth flow in `src/auth/`, especially token refresh."
- **Provide verification.** Give Claude tests, expected outputs, or screenshots so it can check its own work.
- **Reference patterns.** "Look at how `HotDogWidget.php` is implemented and follow the same pattern."
- **Let Claude interview you.** For large features: "I want to build [X]. Interview me about requirements using AskUserQuestion."
- **Course-correct early.** Hit `Esc` to stop Claude mid-action. Use `/rewind` (or `Esc`+`Esc`) to restore previous state.
