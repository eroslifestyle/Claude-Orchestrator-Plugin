# Agent Team Patterns & Lifecycle

> **DEPRECATED - This content is now integrated in SKILL.md V10.0**
>
> See these sections in SKILL.md:
> - [AGENT TEAM LIFECYCLE](SKILL.md#agent-team-lifecycle) - Phases 1-5: Create, Plan Approval, Coordinate, Quality Gates, Shutdown
> - [AGENT TEAM PATTERNS](SKILL.md#agent-team-patterns) - Pattern 1-4 examples
>
> For quick reference, the team patterns cover:
>
> ## Lifecycle Phases
> - PHASE 1: CREATE TEAM - Spawn teammates with file ownership
> - PHASE 2: PLAN APPROVAL - Require approval for risky changes
> - PHASE 3: COORDINATE - Monitor progress, steer teammates
> - PHASE 4: QUALITY GATES - Verify outputs before acceptance
> - PHASE 5: SHUTDOWN & CLEANUP - Graceful termination
>
> ## Team Patterns
> - Pattern 1: Parallel Review (3+ reviewers)
> - Pattern 2: Multi-Module Feature (frontend + backend + tests)
> - Pattern 3: Competing Hypotheses (debugging)
> - Pattern 4: Research + Implement
>
> ## Error Recovery
> - Teammate not responding -> Message directly, spawn replacement
> - File conflict -> Stop both, reassign ownership
> - Plan rejected -> Teammate revises in plan mode
> - Task stuck -> Check blocker, update status
>
> ## Windows Notes
> - Agent Teams use `in-process` mode on Windows (no tmux/iTerm2)
> - Storage: ~/.claude/teams/ and ~/.claude/tasks/
>
> This file is retained for backward compatibility only.
