---
name: incident-response
description: Debug production incidents by correlating Sentry errors, logs, and recent deploys
disable-model-invocation: true
---

Help debug a production incident. Sentry issue or description: $ARGUMENTS

1. **Gather error context.** If a Sentry issue ID is provided, use the Sentry MCP to pull:
   - Error message and stack trace
   - Affected users and frequency
   - First/last seen timestamps
   - Release and environment
   - Seer AI analysis (if available)

2. **Check logs.** Use BetterStack MCP to:
   - Query logs around the time of the error
   - Look for related errors or warnings
   - Check for upstream service failures

3. **Check recent deploys:**
   ```
   git log --oneline -20
   gh release list --limit 5
   ```
   Identify any recent changes that could have caused the issue.

4. **Find the relevant code.** Based on the stack trace:
   - Read the files and functions involved
   - Identify the root cause
   - Check git blame for recent changes to those areas

5. **Check service health.** Use BetterStack MCP to:
   - Check uptime monitors for affected services
   - Look for correlated infrastructure issues

6. **Summarize:**
   - **Root cause** (confirmed or most likely)
   - **Impact** (affected users, error frequency, duration)
   - **Timeline** (when it started, what triggered it)
   - **Fix** (proposed code change with file:line references)
   - **Prevention** (what test or check would have caught this)

7. Wait for approval before implementing the fix.
