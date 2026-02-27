# Feature Workflow

> Version: V12.0 | Last Updated: 2026-02-27 | Orchestrator Alignment: V12.0.1

## Phases

### 1. Planning (Parallel)
- Requirements analysis (Analyzer)
- Architecture design (Architect Expert)
- Test plan creation (Tester Expert)

### 2. Development (Parallel where possible)
- Core implementation (Coder)
- Unit tests (Tester Expert)
- Documentation (Documenter)

### 3. Integration
- Merge feature components
- Integration testing
- Agent: Coder + Tester Expert

### 4. Review
- Code review (Reviewer)
- Security review if applicable (Security Unified Expert)
- Performance review if applicable (Architect Expert)

### 5. Delivery
- Final test suite run
- Documentation update
- Conventional commit: `feat(scope): description`
