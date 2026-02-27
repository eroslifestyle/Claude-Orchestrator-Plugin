# Refactoring Workflow

> Version: V12.0 | Last Updated: 2026-02-27 | Orchestrator Alignment: V12.0.1

## Stages

### 1. Assessment
- Identify code smells and improvement areas
- Measure current metrics (complexity, duplication)
- Agent: Analyzer + Reviewer

### 2. Safety Net
- Ensure tests exist for code being refactored
- Add missing tests BEFORE refactoring
- Agent: Tester Expert

### 3. Incremental Refactoring
- Small, focused changes (one refactoring at a time)
- Run tests after EACH change
- Commit after each successful step
- Agent: Languages Refactor Specialist L2

### 4. Validation
- All tests still pass
- No behavior changes (same inputs = same outputs)
- Metrics improved (reduced complexity, less duplication)
- Agent: Reviewer
