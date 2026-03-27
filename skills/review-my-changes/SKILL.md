---
name: review-my-changes
description: Review staged and unstaged changes before creating a PR
disable-model-invocation: true
---

Review my current changes for quality and correctness.

1. Run `git diff` to see all unstaged changes
2. Run `git diff --cached` to see staged changes
3. Check for:
   - Security issues (hardcoded secrets, injection vulnerabilities)
   - Missing error handling
   - Incomplete implementations or TODOs
   - Code that doesn't match existing patterns in the codebase
   - Missing or inadequate tests
4. Please leverage the code-simplifier plugin to aid in your review. If a PR exists for this branch, also use pr-review-toolkit.
5. Summarize findings with specific file:line references
6. Suggest fixes for any issues found. Wait for my approval to implement.
