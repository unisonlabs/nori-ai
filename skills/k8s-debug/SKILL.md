---
name: k8s-debug
description: Debug Kubernetes issues by inspecting pods, logs, and events
disable-model-invocation: true
---

Debug Kubernetes issues in: $ARGUMENTS (namespace, or namespace + pod name).

1. **Check pod status:**
   ```
   kubectl get pods -n <namespace> -o wide
   ```

2. **Check recent events** for errors or warnings:
   ```
   kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -30
   ```

3. **For unhealthy pods**, inspect:
   - `kubectl describe pod <pod> -n <namespace>` — look for scheduling failures, image pull errors, OOM kills
   - `kubectl logs <pod> -n <namespace> --tail=100` — check recent logs for errors
   - `kubectl logs <pod> -n <namespace> --previous` — check previous container logs if it's restarting

4. **Check resource usage:**
   ```
   kubectl top pods -n <namespace>
   ```

5. **Check deployments and replica sets:**
   ```
   kubectl get deployments -n <namespace>
   kubectl get rs -n <namespace>
   ```

6. **Summarize findings:**
   - Root cause (or most likely cause)
   - Affected pods and their current state
   - Recommended fix
   - Any related issues (resource limits, node capacity, config errors)

7. NEVER apply changes to the cluster without explicit user approval. Only suggest fixes.
