# Git Workflow Rules

> Consistent git practices across all projects.

---

## Commit Messages (Rules 1-6)

### Rule 1
Use **Conventional Commits** format:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Rule 2
Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`, `style`

### Rule 3
Description: imperative mood, lowercase, no period at end (e.g., "add user validation")

### Rule 4
Body: explain **WHY**, not what (the diff shows what)

### Rule 5
Max 72 chars for subject line, wrap body at 80 chars

### Rule 6
Examples:
```
feat(auth): add OAuth2 login with Google
fix(cart): prevent negative quantity on item update
refactor(api): extract validation middleware from controllers
test(user): add edge cases for email validation
```

## Commit Scope (Rules 7-10)

### Rule 7
**One logical change per commit** - don't mix features, fixes, and refactors

### Rule 8
Small, atomic commits that can be reverted independently

### Rule 9
If a commit message needs "and" - split it into two commits

### Rule 10
Squash WIP commits before merge if >5 commits on the branch

## Branch Naming (Rules 11-14)

### Rule 11
Format: `<type>/<ticket>-<short-description>`

### Rule 12
Types: `feature/`, `bugfix/`, `hotfix/`, `release/`, `chore/`

### Rule 13
Use kebab-case for descriptions

### Rule 14
Examples:
```
feature/AUTH-42-oauth-google-login
bugfix/CART-17-negative-quantity
hotfix/PROD-99-fix-payment-timeout
chore/upgrade-dependencies-feb-2026
```

## Branch Workflow (Rules 15-19)

### Rule 15
`main` (or `master`): always deployable, protected

### Rule 16
`develop` (if used): integration branch for features

### Rule 17
Feature branches: branch from `main`, merge back to `main`

### Rule 18
Hotfix branches: branch from `main`, merge to `main` (and `develop` if it exists)

### Rule 19
Delete branches after merge (keep the repo clean)

## What NEVER to Commit (Rules 20-25)

### Rule 20
**Secrets**: `.env`, credentials, API keys, private keys, tokens

### Rule 21
**Build artifacts**: `node_modules/`, `dist/`, `__pycache__/`, `.pyc`, `*.o`

### Rule 22
**IDE config**: `.idea/`, `.vscode/` (except shared settings), `*.swp`

### Rule 23
**OS files**: `.DS_Store`, `Thumbs.db`, `desktop.ini`

### Rule 24
**Large binaries**: images >1MB, videos, datasets (use Git LFS or external storage)

### Rule 25
Ensure `.gitignore` covers all of the above BEFORE first commit

## Pull Requests (Rules 26-30)

### Rule 26
**PR title**: follows same conventional commit format

### Rule 27
**PR description** must explain:
- WHY this change is needed (not just what changed)
- How to test it (steps or commands)
- Screenshots/recordings for UI changes
- Breaking changes or migration steps (if any)

### Rule 28
Keep PRs small: <400 lines changed (split larger changes)

### Rule 29
Request review from at least 1 person (2 for critical paths)

### Rule 30
Address all review comments before merge (resolve, don't ignore)

## Code Review Checklist (Rules 31-36)

### Rule 31
Does the code do what the PR says it does?

### Rule 32
Are there tests for the new behavior?

### Rule 33
Are error cases handled?

### Rule 34
Are there any security concerns?

### Rule 35
Is the code readable without the PR description as context?

### Rule 36
Performance: any N+1 queries, unbounded loops, missing indexes?

## Git Hygiene (Rules 37-42)

### Rule 37
Pull/rebase before pushing to avoid unnecessary merge commits

### Rule 38
Use `git rebase` for local branch updates (keep history linear)

### Rule 39
Use `git merge` for integrating feature branches to main

### Rule 40
Tag releases with semver: `v1.2.3`

### Rule 41
Write meaningful tag annotations for releases

### Rule 42
Never force-push to shared branches (`main`, `develop`)
