---
paths:
  - .github/workflows/*.yml
---

# GitHub Actions rules

## Purpose

- GitHub Actions is the backbone of modern CI/CD
- Adhering to these best practices ensures your workflows are efficient, secure, and maintainable
- This guide is your definitive reference for building high-quality pipelines

## Overall rules

- The workflow structure must be clear and modular (single responsibility rule)
- Optimize your workflows for speed and cost-efficiency
- Enforce high standards and ensure supply chain integrity
- Avoid duplicating tasks, create "reusable workflows" for repetitive tasks
- Define rules blocking multiple workflow executions at the same time (explicit `concurrency groups`)
- Always do tests first (`linters`, etc.)
- Always use specific versions for actions (@v4, not @latest)
- Always set specific, granular permissions (minimum required)
- Never write sensitive data in your code, use `variables` and `secrets`
- Implement approval mechanisms for production deployments
- Pin actions to SHA hashes with version comments: `actions/checkout@<full-sha>  # vX.Y.Z` (use `persist-credentials: false`)
- Implement mechanisms for communicating about failed implementations
- Test across multiple OSes, Python, Ansible versions, or other configurations efficiently

## Security

- Mask sensitive data in logs, use `::add-mask::` for any non-GitHub secret sensitive values that might appear in logs
- Set default `GITHUB_TOKEN` permissions to read-only, then elevate only when necessary for specific jobs
- Always pass external data (e.g., from `github.event.pull_request.title`) as environment variables, not direct interpolation:

```yaml
- name: Check PR Title
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: |
    if [[ "$PR_TITLE" =~ ^feat ]]; then
      echo "Feature PR"
    fi
```

## Naming

- Always create consistent and unambiguous job and task names (`jobs`, `steps`)
- Always use the following naming schema:

| Prefix     | Usage                                      |
|------------|--------------------------------------------|
| `test-`    | Tests                                      |
| `ci-`      | CICD automation                            |
| `util-`    | Additional functionalities (notifications) |
| `build-`   | Main code builds                           |
| `release-` | Semantic release versioning                |
| `sec-`     | Security scans                             |

## Documenting

- Document workflows in `docs/workflows/*`
- Workflow documentation structure:
  - Flow diagrams
  - Workflow triggers
  - Description of triggers, jobs and tasks
  - Description of the runners used
  - Description of the variables and secrets used
