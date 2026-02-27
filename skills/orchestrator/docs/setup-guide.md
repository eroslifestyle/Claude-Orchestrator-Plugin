# Orchestrator Setup Guide V12.0

> Step-by-step setup for the multi-agent orchestrator system.

---

## Prerequisites

- Claude Code CLI installed and configured
- Git repository initialized
- CLAUDE.md with orchestrator mandate (see below)

## Verify Installation

Check these files exist:
```
~/.claude/
  CLAUDE.md                          # Must contain orchestrator mandate
  VERSION.json                       # System version info
  skills/orchestrator/SKILL.md       # Orchestrator definition
  agents/core/*.md                   # 6 core agent definitions
  agents/experts/*.md                # 23 L1 expert definitions
  agents/experts/L2/*.md             # 15 L2 specialist definitions
  rules/common/*.md                  # 6 common rule files
  rules/{python,typescript,go}/*.md  # 3 language rule files
  learnings/instincts.json           # Learning storage
  templates/*.md                     # Task templates
  workflows/*.md                     # Workflow definitions
```

## CLAUDE.md Configuration

Your CLAUDE.md MUST contain the orchestrator mandate:
```markdown
## MANDATORY: ORCHESTRATOR MODE ALWAYS ACTIVE
You MUST use the `/orchestrator` skill for EVERY user request.
```

## Settings Configuration

In `settings.local.json`, configure MCP servers:
```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["orchestrator"]
}
```

Optional: Enable additional MCP servers (slack, firebase) by adding to the array.

## First Run Verification

1. Start a Claude Code session
2. Type any request (e.g., "show system status")
3. Verify orchestrator activates automatically
4. Check task table appears with agent assignments
5. Verify subagents complete their work

## Common Setup Issues

| Issue | Solution |
|-------|----------|
| Orchestrator not activating | Check CLAUDE.md mandate exists |
| "Skill not found" error | Verify skills/orchestrator/SKILL.md exists |
| Agent routing fails | Check agents/ directory has all .md files |
| MCP tools fail | Verify settings.local.json MCP config |
| NUL files on Windows | Run /cleanup to clear Windows artifacts |

## Post-Setup

- Run `/status` to verify system health
- Run `/metrics` to see baseline metrics
- Review VERSION.json for component versions
