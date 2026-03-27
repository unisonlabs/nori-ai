# Hooks

Hooks are shell commands that run automatically at specific points in Claude's lifecycle. Unlike CLAUDE.md instructions (which are advisory), hooks are **deterministic** — they always execute.

---

## Notification Hooks (recommended for everyone)

These hooks send macOS notifications when Claude is waiting for your input or has finished responding. This lets you context-switch to other work and get notified when Claude needs you.

Add this to `~/.claude/settings.json`:

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

**What fires when:**
- `Notification` — Claude needs your attention (permission prompt, waiting for input)
- `Stop` — Claude has finished responding

---

## Auto-Format After Edits

Runs Prettier on every file Claude edits. Add to `.claude/settings.json` (project-level):

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

> **Note:** If you have git pre-commit hooks, those may be preferable to Claude hooks for formatting. But this pattern is useful for other auto-corrections.

---

## Block Edits to Protected Files

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

---

## Auto-Run Tests After Code Changes

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "file=$(jq -r '.tool_input.file_path'); if echo \"$file\" | grep -qE '\\.(ts|tsx|js|jsx)$'; then echo 'Consider running tests for changed file'; fi"
          }
        ]
      }
    ]
  }
}
```

---

## All Available Hook Events

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

See the [full hooks reference](https://docs.anthropic.com/en/docs/claude-code/hooks) for input/output schemas and advanced patterns.
