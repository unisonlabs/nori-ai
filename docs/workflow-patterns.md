# Workflow Patterns

Proven patterns for getting the most out of Claude Code across different types of engineering work.

---

## The Plan/Execute/Clear Loop

The most effective general-purpose workflow:

1. **Plan** — Enter Plan Mode (`Shift+Tab` x2), describe what you want, iterate on the approach
2. **Execute** — Exit Plan Mode, Claude implements the plan
3. **Clear** — Run `/clear` before starting the next task

This prevents context pollution and keeps Claude in its "smart zone."

---

## Large Feature Development

1. **Write a strong spec.** Collaborate with Claude on the tech + product spec. This is hands-on — provide lots of feedback and product direction. Typically takes 1-2 hours of focused work.
2. **Use Codepipe's plan phase** to ground the spec in the actual codebase — referencing existing patterns, schemas, and services rather than designing in a vacuum.
3. **Create Linear tickets from the spec.** At the bottom of the spec, define the tickets. Feed the spec into a new Claude session and ask it to create them. Keep tickets focused — PRs of a few hundred lines go much smoother.
4. **Set up a Codepipe pipeline.** Tell Claude to familiarize itself with Codepipe first. Use branch dependencies when tickets depend on each other; parallelize when they don't.
5. **Run the pipeline.** Codepipe reads ticket context from Linear, runs Claude skills before pushing, goes through Greptile reviews, and ensures CI passes.
6. **Review PRs thoroughly.** Go through each PR, leave comments, pull those comments into a Claude Code session to discuss and implement fixes.
7. **Merge and manually test.** End-to-end manual testing consistently catches things automated checks miss — formatting issues, UX problems, integration quirks.

---

## Bug Fixing

```
"Users report [specific symptom]. Check [specific area] for [specific issue type].
Here's the error/stack trace: [paste]
Here's the Sentry issue: [link or ID]"
```

1. Give Claude the specific symptom and error
2. Point it at the relevant code area
3. Let it investigate and propose a fix
4. Ask for tests that verify the fix
5. Review the diff before committing

---

## PR Review

```
# Quick review
gh pr diff 1234 | claude "review this PR for issues"

# Thorough review with the plugin
/pr-review-toolkit:review-pr 1234
```

---

## Code Exploration

```
# Understand unfamiliar code
"Use subagents to investigate how the auth flow works in this codebase. Check middleware, token handling, and session management."

# Find patterns
"Find all places where we handle webhook events and show me the common pattern"

# Trace a request
"Trace the lifecycle of an API request to POST /api/messages from route handler to database write"
```

---

## Refactoring

```
# Pattern-based refactoring
"Refactor all API route handlers to use the new error handling middleware. Look at src/api/routes/users.ts as the reference implementation."

# Migration
"Migrate all class components in src/components/ to functional components with hooks. Do them one at a time, running tests after each."
```

---

## Multi-Agent Patterns

### Subagents for Research

```
"Use subagents to investigate X"
```

Subagents explore in a separate context, keeping your main conversation clean. Great for:
- Exploring large codebases
- Investigating how existing code works
- Finding all instances of a pattern

### Background Agents

```
"Use a background subagent to research Y while I continue working on X"
```

You keep working while the agent researches. Claude notifies you when it finishes.

### Parallel Worktrees

```bash
# Terminal 1
claude --worktree  # working on feature A

# Terminal 2
claude --worktree  # working on feature B

# Terminal 3
claude --worktree  # working on feature C
```

Each worktree gets its own branch, session, and file system state. Best for independent tickets.

---

## The Interview Pattern

For large or ambiguous features, let Claude interview you first:

```
"I want to build [X]. Interview me about requirements before we start.
Use AskUserQuestion to ask about:
- Scope and constraints
- Edge cases
- Integration points
- Testing strategy"
```

This front-loads decision-making and produces better results than diving straight into code.

---

## Context Recovery

When you come back to a previous task:

```bash
# Resume the exact session
claude --resume
# Then pick from the list

# Or if you named it
claude --continue  # resumes most recent
```

Name sessions with `/rename` for easy retrieval (e.g., "oauth-migration", "billing-refactor").
