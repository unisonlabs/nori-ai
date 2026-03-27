---
name: fix-issue
description: Fix a Linear ticket end-to-end
disable-model-invocation: true
---

Analyze and fix the Linear ticket: $ARGUMENTS.

1. Use the Linear MCP to get the ticket details (title, description, comments, labels)
2. Understand the problem described in the ticket
3. Search the codebase for relevant files
4. Implement the necessary changes
5. Write and run tests to verify the fix
6. Ensure code passes linting and type checking
7. Create a descriptive commit message referencing the ticket ID
8. Push and create a PR linking the ticket
