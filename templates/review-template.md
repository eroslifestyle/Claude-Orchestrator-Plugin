# Code Review Template

## Review Scope
- **Files**: {list of files}
- **PR/Branch**: {reference}
- **Author**: {who wrote the code}
- **Reviewer**: {assigned agent}

## Checklist
### Correctness
- [ ] Logic is correct and handles edge cases
- [ ] Error handling is appropriate
- [ ] No off-by-one errors or boundary issues

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] No injection vulnerabilities

### Quality
- [ ] Code is readable and well-named
- [ ] No unnecessary complexity
- [ ] Tests cover new behavior

### Performance
- [ ] No N+1 queries
- [ ] No unbounded loops or memory leaks
- [ ] Appropriate caching

## Issues Found
| # | Severity | File:Line | Description | Suggestion |
|---|----------|-----------|-------------|------------|

## Decision
- [ ] APPROVE
- [ ] REQUEST CHANGES
- [ ] REJECT
