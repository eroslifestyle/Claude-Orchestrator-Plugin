# Bugfix Workflow

> Version: V12.0 | Last Updated: 2026-02-27 | Orchestrator Alignment: V12.0.1

## Stages

### 1. Analysis
- Reproduce the bug
- Identify root cause (not just symptoms)
- Document: expected vs actual behavior
- Agent: Analyzer or Tester Expert

### 2. Fix Implementation
- Create minimal fix targeting root cause
- Avoid unrelated changes
- Agent: Coder

### 3. Testing
- Add regression test for the specific bug
- Run existing test suite (no regressions)
- Agent: Tester Expert

### 4. Review
- Code review of fix
- Verify fix addresses root cause
- Agent: Reviewer

### 5. Commit
- Conventional commit: `fix(scope): description`
- Reference issue/ticket number
