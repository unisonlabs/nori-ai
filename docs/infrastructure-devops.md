# Infrastructure & DevOps

Patterns for using Claude Code effectively with infrastructure-as-code, CI/CD, and cloud services.

---

## Terraform

### MCP Server

```bash
claude mcp add-json terraform --scope user \
  '{"command":"npx","args":["-y","@hashicorp/terraform-mcp-server"]}'
```

### Key Skill: /terraform-plan

See [`skills/terraform-plan/SKILL.md`](../skills/terraform-plan/SKILL.md) — validates changes, checks for drift, ensures least-privilege IAM.

### Best Practices

- **Always query live state.** Claude can hallucinate subnet IDs, KMS key ARNs, and other resource identifiers. Force it to use `terraform state show` or MCP tools rather than guessing.
- **Never `terraform apply` without human review.** Use Claude for `plan` only, review the plan yourself, then apply manually or with explicit approval.
- **Least-privilege IAM by default.** Ask Claude to generate IAM policies with minimal permissions and human-readable justification for each action.
- **Store state in S3 with encryption.** Never local state in production.
- **Separate environments.** Dev, staging, and production should be in separate accounts/projects.

### Example Prompts

```
"Review this Terraform module for security issues. Check for:
 - Wildcard (*) IAM actions
 - Public S3 buckets
 - Unencrypted resources
 - Missing tags"

"Generate a least-privilege IAM policy for a Lambda that reads from S3 bucket X and writes to DynamoDB table Y"
```

---

## Kubernetes

### MCP Server

```bash
claude mcp add-json kubernetes --scope user \
  '{"command":"npx","args":["-y","@strowk/mcp-k8s"]}'
```

### Key Skill: /k8s-debug

See [`skills/k8s-debug/SKILL.md`](../skills/k8s-debug/SKILL.md) — inspects pods, logs, events, and resource usage.

### Best Practices

- **Use Claude for debugging, not deploying.** Let Claude inspect cluster state and suggest fixes, but apply changes through your CD pipeline.
- **Security hardening.** Ask Claude to review your manifests for:
  - Missing NetworkPolicies
  - Containers running as root
  - Missing resource limits
  - Missing Pod Security Standards
  - RBAC over-permissions

### Example Prompts

```
"Debug why pods in namespace X are crash-looping. Check events, logs, and resource limits."

"Review this Helm chart for Kubernetes security best practices"

"Generate a NetworkPolicy that only allows ingress from the frontend namespace on port 8080"
```

---

## Docker

### Best Practices

- **Multi-stage builds.** Ask Claude to optimize Dockerfiles with multi-stage builds to reduce image size.
- **Security scanning.** "Scan this Dockerfile for security issues — check for running as root, unnecessary packages, secrets in build args."
- **Compose validation.** "Review this docker-compose.yml for production readiness."

---

## CI/CD

### GitHub Actions

Claude can read, write, and debug GitHub Actions workflows effectively:

```
"This GitHub Actions workflow is failing on the deploy step. Here's the error: [paste error]. Fix it."

"Create a GitHub Actions workflow that runs tests on PR, builds on merge to main, and deploys to staging"

"Add a security scanning step to our CI pipeline using Trivy for container scanning and npm audit for dependencies"
```

### Best Practices

- **Review generated workflows carefully.** Claude is good at writing workflows but may not know your specific deployment targets.
- **Use Claude for debugging CI failures.** Pipe the failure output: `gh run view --log-failed | claude "why did this CI run fail?"`
- **Secret management.** Never let Claude hardcode secrets. Always use GitHub Secrets or your vault solution.

---

## AWS

### Useful MCP Servers

```bash
# AWS MCP servers for specific services
claude mcp add-json aws-cloudwatch --scope user \
  '{"command":"npx","args":["-y","@aws/cloudwatch-mcp-server"]}'
```

### Example Prompts

```
"Query CloudWatch logs for errors in the API service in the last hour"

"Review this IAM policy and suggest least-privilege improvements"

"Generate a CloudFormation template for an ALB -> ECS Fargate -> RDS architecture with private subnets"
```

---

## General Infrastructure Tips

1. **Always verify resource IDs.** Don't trust Claude's memory of infrastructure identifiers — make it query live state.
2. **Use read-only access by default.** Connect Claude to infrastructure with read-only credentials. Only escalate for specific approved operations.
3. **Pipe real output.** `kubectl get pods -n prod | claude "which pods look unhealthy and why?"` is better than describing the problem.
4. **Version-pin everything.** When Claude generates IaC, ensure it pins provider versions, module versions, and image tags.
