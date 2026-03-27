# Scheduled Tasks & Remote Agents

Claude Code can run tasks on a schedule, operate as a background worker, and be controlled remotely.

---

## Scheduled Tasks with /loop

The quickest way to schedule a recurring prompt. Runs in the background while your session stays open.

```
/loop 5m /review-my-changes
/loop 30m check if any new Sentry errors have appeared in the last 30 minutes
/loop 1h check PR status and summarize any new review comments
```

**Supported intervals:** `s` (seconds), `m` (minutes), `h` (hours), `d` (days). Seconds are rounded to the nearest minute since cron has one-minute granularity.

**Constraints:**
- Up to 50 concurrent scheduled tasks per session
- Tasks auto-expire after 3 days to prevent unbounded operation
- Tasks only run while the Claude Code session is active

---

## Persistent Scheduled Tasks with /schedule

For tasks that survive restarts and run as long as the Claude Code desktop app is open:

```
/schedule
```

This opens the scheduling UI where you can:
- Select a repository
- Define a cron-style schedule
- Write your prompt
- Claude wakes up, executes, and goes back to sleep

### Cron Expressions

Standard 5-field cron: `minute hour day-of-month month day-of-week`

```
*/15 * * * *     # Every 15 minutes
0 9 * * 1-5      # 9 AM weekdays
0 */4 * * *      # Every 4 hours
0 0 * * 0        # Weekly on Sunday midnight
```

---

## Cloud-Based Scheduling

Schedule tasks that run in the cloud, even when your machine is off:

1. Select a repository (or multiple)
2. Define a cron schedule
3. Write your prompt
4. Claude wakes up at the designated time, executes against your codebase, and goes back to sleep

---

## Remote Control

Released February 2026 as a research preview. Bridges your local Claude Code terminal session with:
- **claude.ai/code** (web interface)
- **Claude iOS app**
- **Claude Android app**

Your full local environment stays available: filesystem, MCP servers, tools, and project configuration. Nothing moves to the cloud.

### Setup

```bash
# Start Claude Code with remote control enabled
claude --remote
```

Then connect from claude.ai/code or the mobile app to keep working after closing your laptop.

---

## Use Cases

### PR Monitoring

```
/loop 30m check all open PRs in unisonlabs/nori-backend for new review comments. Summarize any that need attention.
```

### Deployment Health Checks

```
/loop 15m check BetterStack for any new incidents or degraded services. Alert if anything is unhealthy.
```

### Dependency Monitoring

```
/schedule
# Cron: 0 9 * * 1 (every Monday at 9 AM)
# Prompt: Run npm audit on the repo and create a Linear ticket if any critical vulnerabilities are found.
```

### Sentry Error Triage

```
/loop 1h check Sentry for new unresolved errors in the last hour. For each, identify the likely root cause and affected code.
```

---

## Best Practices

1. **Start with `/loop` for experimentation.** It's session-scoped and easy to adjust.
2. **Graduate to `/schedule` for persistent tasks** that should survive restarts.
3. **Keep prompts specific.** Vague scheduled prompts waste compute and produce noisy results.
4. **Set appropriate intervals.** Don't poll every minute for things that change hourly.
5. **Use cloud scheduling for CI-like tasks** (weekly dependency audits, daily security scans).
