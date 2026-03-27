---
name: terraform-plan
description: Safely validate and review Terraform changes
disable-model-invocation: true
---

Validate and review Terraform changes in: $ARGUMENTS

1. **Read the Terraform files** in the specified directory. Understand what resources are being created, modified, or destroyed.

2. **Check for security issues:**
   - Wildcard (*) IAM actions or resources
   - Security groups with 0.0.0.0/0 ingress (unless explicitly intended)
   - Unencrypted storage (S3, EBS, RDS)
   - Public subnets for private resources
   - Missing CloudTrail or logging
   - Hardcoded secrets or credentials

3. **Check for best practices:**
   - Provider and module versions are pinned
   - Resources are properly tagged
   - State backend is configured with encryption
   - Variables have descriptions and validation rules
   - Outputs are documented

4. **Verify resource identifiers.** Do NOT guess subnet IDs, KMS key ARNs, AMI IDs, or other infrastructure identifiers. If you need them, use `terraform state show` or ask the user.

5. **Run `terraform validate`** to check syntax.

6. **Run `terraform plan`** and analyze the output:
   - List all resources being created, modified, or destroyed
   - Flag any destructive changes (destroys, replacements)
   - Highlight changes to IAM policies or security groups

7. **Summarize** with a clear report of findings and risks. NEVER run `terraform apply` without explicit user approval.
