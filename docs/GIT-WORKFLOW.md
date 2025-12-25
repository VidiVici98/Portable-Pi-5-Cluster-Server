# Git Workflow & Standards

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Define version control standards and branching strategy

## Overview

This document establishes how we use Git to manage the cluster server configuration and code. The goal is **reproducible, auditable, and safe** deployments.

## Core Principles

1. **Everything in git** - Except secrets, logs, and backups
2. **Meaningful commits** - Clear messages, logical grouping
3. **Protected main branch** - No direct commits, all via pull requests
4. **Audit trail** - Every change tracked and reversible
5. **Automation** - CI/CD validates before merging

## What Goes in Git

### ✅ DO Commit

```bash
config/templates/           # Configuration templates
config/overlays/           # Node-specific configs (non-sensitive)
config/security/           # Security policies & settings
config/boot/               # Boot configurations
config/network/            # Network settings
config/nfs/                # NFS configurations
config/ntp/                # NTP/time settings

deployments/               # Deployment procedures
operations/procedures/     # Operational procedures
scripts/                   # Utility scripts
docs/                      # Documentation
Makefile                   # Automation

.gitignore                 # Ignore rules
.git attributes            # Git attributes
SECURITY-BASELINE.md       # This security guide
GIT-WORKFLOW.md            # This file
```

### ❌ DO NOT Commit

```bash
config/secrets/            # Credentials, private keys
config/secrets/**/*.key    # Private SSL certificates
config/secrets/**/*.pem    # Private keys
config/secrets/**/api*     # API keys, tokens

operations/backups/        # Backup files
operations/logs/           # System logs

.env                       # Local environment variables
.env.local                 # Local overrides
local.conf                 # Local configuration
Makefile.local             # Local Makefile overrides

# System files
*.swp
*.swo
*~
.vscode/
.idea/
*.pyc
__pycache__/
node_modules/
```

## Enhanced .gitignore

Update your `.gitignore` to include:

```bash
# Secrets - NEVER commit
config/secrets/**
!config/secrets/README.md
!config/secrets/.gitkeep

# Operational data
operations/backups/**
!operations/backups/README.md
!operations/backups/.gitkeep

operations/logs/**
!operations/logs/README.md
!operations/logs/.gitkeep

# Local overrides
Makefile.local
.env
.env.local
local.conf
local/
private/

# System files
*.swp
*.swo
*~
.vscode/
.idea/
*.pyc
__pycache__/
.DS_Store
Thumbs.db

# Temporary files
/tmp/*
/temp/*
*.tmp
*.bak

# IDE & editors
.vscode/
.idea/
*.code-workspace
vim.swp
```

## Branching Strategy

Use **trunk-based development** with feature branches:

### Branch Types

```
main                       # Production-ready code only
  └── feature/*           # Features & improvements
  └── fix/*               # Bug fixes
  └── docs/*              # Documentation updates
  └── security/*          # Security patches
  └── ops/*               # Operational changes
```

### Branch Naming Convention

```bash
feature/node-overlay-system          # New feature
fix/dnsmasq-config-bug              # Bug fix
docs/deployment-guide               # Documentation
security/ssh-key-rotation           # Security improvement
ops/backup-procedure-update         # Operational change
```

### Branching Rules

1. **Always branch from `main`**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/my-feature
   ```

2. **Keep branches short-lived**
   - Merge within 3-5 days
   - Keep scope focused

3. **One logical change per branch**
   - Don't mix features + fixes + docs
   - Each branch solves one problem

4. **Sync with main frequently**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

## Commit Messages

### Format

```
<type>: <subject>

<body>

<footer>
```

### Type
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `security:` Security improvement
- `refactor:` Code restructuring
- `test:` Tests/validation
- `ops:` Operational change

### Subject Line
- Imperative mood: "add" not "added"
- Lowercase first letter
- No period at end
- Max 50 characters
- Clear and descriptive

### Body (Optional but Recommended)
- Explain WHAT and WHY, not HOW
- Wrap at 72 characters
- Separate from subject with blank line
- Reference issues: "Fixes #123"

### Examples

**Good:**
```
feat: add node-specific overlay system

Implements configuration overlays for boot, isr, mesh, and vhf nodes.
Allows per-node customization while maintaining base configuration
templates. Overlays are applied during deployment.

Relates to #42
```

**Good:**
```
fix: correct firewall rule ordering in ufw config

UFW rules must be added in correct order - most specific first.
Previous implementation allowed traffic that should be blocked.

Fixes #89
```

**Bad:**
```
update
fixed stuff
minor changes
```

## Pull Request Workflow

### Creating a Pull Request

1. **Create branch** from latest main
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/my-change
   ```

2. **Make changes**
   ```bash
   # Edit files
   git add .
   git commit -m "feat: clear description"
   ```

3. **Push to remote**
   ```bash
   git push origin feature/my-change
   ```

4. **Create PR on GitHub/GitLab**
   - Title: Same as commit message
   - Description: Explain what and why
   - Reference related issues
   - Link to documentation

### PR Template

```markdown
## Description
Brief explanation of what this PR does.

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Security improvement
- [ ] Documentation
- [ ] Configuration

## Related Issues
Fixes #123

## Testing
How was this tested? What should reviewers test?

## Security Considerations
Any security implications?

## Deployment Notes
Any special steps needed to deploy this?

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No secrets committed
- [ ] Tests pass (if applicable)
- [ ] Security baseline maintained
```

### PR Review Checklist

Reviewers verify:
- ✅ No secrets in code
- ✅ No breaking changes
- ✅ Configuration is valid syntax
- ✅ Security baseline maintained
- ✅ Documentation is clear
- ✅ Tests pass (if applicable)
- ✅ Follows commit message standards

### Merging Rules

**Before merging:**
1. ✅ All CI/CD checks pass
2. ✅ At least 1 code review approval
3. ✅ No unresolved conversations
4. ✅ Branch is up to date with main
5. ✅ No conflicts

**Merge options:**
```bash
# Prefer: Squash and merge (clean history)
git merge --squash feature/my-change

# Or: Regular merge (preserves history)
git merge feature/my-change

# Avoid: Rebase and merge (confusing history)
```

## Continuous Integration (Future)

When ready, implement:

```yaml
# .github/workflows/validate.yml
name: Validate

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate configuration files
        run: ./scripts/validate-config.sh
      - name: Check for secrets
        run: ./scripts/check-no-secrets.sh
      - name: Shellcheck
        run: shellcheck scripts/*.sh
```

## Common Git Workflows

### Updating Your Branch

```bash
# Sync with main
git fetch origin
git rebase origin/main

# Or, if public branch:
git merge origin/main
```

### Fixing Last Commit

```bash
# Amend message
git commit --amend -m "new message"

# Amend changes (before push)
git add .
git commit --amend --no-edit
git push origin feature/branch -f  # Force (only if not public)
```

### Reverting a Commit

```bash
# Undo last commit, keep changes
git reset --soft HEAD~1

# Undo last commit, discard changes
git reset --hard HEAD~1

# Revert (if already pushed)
git revert HEAD
```

### Cherry-Picking

```bash
# Apply specific commit to current branch
git cherry-pick <commit-hash>

# Useful for applying fix to multiple branches
```

## Tags & Releases

### Version Format

Use semantic versioning: `v0.1.0`

```
v{major}.{minor}.{patch}
v0.1.0      # Initial release
v0.1.1      # Bug fix (patch)
v0.2.0      # New feature (minor)
v1.0.0      # Breaking change (major)
```

### Creating Release Tags

```bash
# Create tag
git tag -a v0.1.0 -m "Release version 0.1.0"

# Push tag
git push origin v0.1.0

# Or all tags
git push origin --tags
```

## Security Practices

### Secrets Management

**Never commit secrets:**
```bash
# ✅ Good: Secrets in separate directory
config/secrets/ssh-keys/
config/secrets/.gitignore  # Ignores everything

# ❌ Bad: Secrets in config files
config/dnsmasq.conf  # Contains API keys
```

**How to manage secrets:**
1. Store in `config/secrets/` (git-ignored)
2. Document HOW to add them in `config/secrets/README.md`
3. Use environment variables or `.env` files (also ignored)
4. Never commit `.env` files

### Preventing Accidental Commits

```bash
# Check before committing
git diff --cached | grep -i password
git diff --cached | grep -i secret
git diff --cached | grep -i api

# Or use git hooks (future)
.git/hooks/pre-commit  # Automatic check
```

## Backup & Recovery via Git

### Backup Code to Git

```bash
# Already done - just push
git push origin main

# Verify backups
git log --oneline | head -20
```

### Recover from Git

```bash
# See all commits
git log --oneline

# Go back to specific commit
git checkout <commit-hash>

# Or reset branch to specific commit
git reset --hard <commit-hash>

# Restore deleted file
git checkout HEAD -- filename
```

## Advanced Usage

### Stashing

```bash
# Save work temporarily
git stash

# Switch branches
git checkout other-branch

# Resume work
git stash pop
```

### Interactive Rebase

```bash
# Clean up last 3 commits
git rebase -i HEAD~3

# Interactive menu to squash, reword, etc.
```

### Bisecting (Find Breaking Commit)

```bash
# Start bisect
git bisect start

# Mark bad/good commits
git bisect bad HEAD
git bisect good v0.1.0

# Git checks commits automatically
git bisect reset  # Return to normal
```

## Team Collaboration

### Code Review Guidelines

**For reviewers:**
- ✅ Ask questions (don't just approve)
- ✅ Suggest improvements
- ✅ Check security implications
- ✅ Verify nothing breaks

**For authors:**
- ✅ Respond to comments
- ✅ Don't take feedback personally
- ✅ Update PR based on feedback
- ✅ Request re-review when ready

### Resolving Conflicts

```bash
# Conflicts show in editor:
<<<<<<< HEAD
your changes
=======
their changes
>>>>>>> branch-name

# Fix manually, then:
git add conflicted-file
git commit -m "resolve merge conflict"
git push origin feature/branch
```

## Quick Reference

```bash
# Create and work on feature
git checkout main && git pull origin main
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "feat: clear description"
git push origin feature/my-feature

# Create PR, get review, then merge to main
git checkout main && git pull origin main
git merge --squash feature/my-feature
git push origin main

# Delete branch
git branch -d feature/my-feature
git push origin -d feature/my-feature
```

## Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

## Questions?

- How do I create a branch? → See "Branching Rules"
- Did I commit secrets? → See "Preventing Accidental Commits"
- How do I write a good commit? → See "Commit Messages"
- Can I undo a commit? → See "Common Git Workflows"
