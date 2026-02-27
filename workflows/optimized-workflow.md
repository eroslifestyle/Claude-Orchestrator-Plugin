# Optimized Workflow

> Version: V12.0 | Last Updated: 2026-02-27 | Orchestrator Alignment: V12.0.1

## By Task Duration

### Fast Tasks (<1 hour)
- Skip formal planning
- Single agent execution
- Quick verification
- Pattern: Analyze -> Fix -> Verify

### Standard Tasks (1-8 hours)
- Brief planning phase
- 2-3 parallel agents max
- Standard verification loop
- Pattern: Plan -> Parallel Execute -> Verify -> Document

### Full Tasks (>1 day)
- Formal planning with architect review
- Agent teams with 3-5 teammates
- Multiple verification iterations
- Pattern: Plan -> Approve -> Parallel Execute -> Integrate -> Verify -> Document -> Review

## Parallelization Rules
- Independent file edits: ALWAYS parallel
- Tests + Implementation: parallel (TDD)
- Review + Documentation: parallel (after implementation)
- Integration: ALWAYS sequential
