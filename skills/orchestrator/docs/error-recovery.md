# Error Recovery Module V12.0

> **Orchestrator Extension** - Automatic error detection, recovery, and fallback system

---

## Recovery Matrix

| Error Type | Detection | Recovery Action | Retry Limit |
|------------|-----------|-----------------|-------------|
| Task timeout | >5 min no response | Restart with fresh context | 3 |
| Agent unavailable | Spawn failure | Route to fallback agent | 1 |
| MCP tool failure | Tool error response | Retry with fallback tool | 3 |
| File conflict | Simultaneous edits | Sequential retry with lock | 3 |
| Memory corruption | Parse error | Rebuild from recent backup | 1 |
| Circular dependency | Graph analysis | Split into intermediate steps | 1 |
| Rate limit | 429 response | Exponential backoff (1s→2s→4s→8s→16s) | 5 |
| Resource exhausted | OOM/disk full | Cleanup + retry | 2 |

---

## Recovery Protocol

When an error is detected:

### 1. Log Error
```
[ERROR] Task T3 failed: [error message]
Context: [relevant context]
Stack: [if available]
```

### 2. Run Diagnostic
```
HealthCheck(subsystem="failed_component")
```

### 3. Apply Recovery
- Look up recovery action in matrix
- Execute recovery protocol
- Log recovery attempt

### 4. Verify Recovery
- Re-run health check
- Confirm subsystem operational
- Resume task execution

### 5. Escalate if Needed
```
if retries >= retry_limit:
    mark_task_failed()
    notify_user()
    suggest_manual_intervention()
```

---

## Fallback Chains

When a primary agent fails, route to the fallback chain:

### Core Agents
| Primary | Fallback 1 | Fallback 2 |
|---------|------------|------------|
| Analyzer | Coder | Documenter |
| Coder | Languages Expert | - |
| Reviewer | Coder | - |
| Documenter | Coder | - |
| System Coordinator | Coder | - |

### L1 Expert Agents
| Primary | Fallback 1 | Fallback 2 |
|---------|------------|------------|
| GUI Super Expert | Languages Expert | Coder |
| Database Expert | Integration Expert | Coder |
| Security Unified Expert | Coder | Reviewer |
| MQL Expert | Trading Strategy Expert | Coder |
| Trading Strategy Expert | MQL Expert | Coder |
| Tester Expert | Coder | - |
| Architect Expert | Coder | Reviewer |
| Integration Expert | API Endpoint Builder L2 | Coder |
| DevOps Expert | Integration Expert | Coder |
| Languages Expert | Coder | - |
| AI Integration Expert | AI Model Specialist L2 | Coder |
| Claude Systems Expert | Claude Prompt Optimizer L2 | Coder |
| Mobile Expert | GUI Super Expert | Coder |
| N8N Expert | N8N Workflow Builder L2 | Coder |
| Social Identity Expert | Social OAuth Specialist L2 | Coder |
| Reverse Engineering Expert | Coder | - |
| Offensive Security Expert | Security Unified Expert | Coder |
| Notification Expert | Integration Expert | Coder |
| Browser Automation Expert | Integration Expert | Coder |
| MCP Integration Expert | Integration Expert | Coder |
| Payment Integration Expert | Integration Expert | Coder |
| MQL Decompilation Expert | MQL Expert | Coder |

### L2 Specialist Agents
All L2 specialists fall back to their L1 parent agent, then to Coder.

| Primary L2 | Fallback (L1 Parent) | Fallback 2 |
|------------|---------------------|------------|
| GUI Layout Specialist L2 | GUI Super Expert | Coder |
| DB Query Optimizer L2 | Database Expert | Coder |
| Security Auth Specialist L2 | Security Unified Expert | Coder |
| API Endpoint Builder L2 | Integration Expert | Coder |
| Test Unit Specialist L2 | Tester Expert | Coder |
| MQL Optimization L2 | MQL Expert | Coder |
| Trading Risk Calculator L2 | Trading Strategy Expert | Coder |
| Mobile UI Specialist L2 | Mobile Expert | Coder |
| N8N Workflow Builder L2 | N8N Expert | Coder |
| Claude Prompt Optimizer L2 | Claude Systems Expert | Coder |
| Architect Design Specialist L2 | Architect Expert | Coder |
| DevOps Pipeline Specialist L2 | DevOps Expert | Coder |
| Languages Refactor Specialist L2 | Languages Expert | Coder |
| AI Model Specialist L2 | AI Integration Expert | Coder |
| Social OAuth Specialist L2 | Social Identity Expert | Coder |

---

## Recovery Logging

All recovery attempts logged to:
```
~/.claude/logs/orchestrator/recovery.log
```

Format:
```
[2026-02-21 14:45:32] [RECOVERY] Task T3 error: agent_timeout
[2026-02-21 14:45:32] [RECOVERY] Action: restart_with_fresh_context
[2026-02-21 14:45:45] [RECOVERY] Task T3 recovered successfully
```

---

## Exponential Backoff Strategy

For rate-limited or transient failures:

| Attempt | Delay | Total Wait |
|---------|-------|------------|
| 1 | 1s | 1s |
| 2 | 2s | 3s |
| 3 | 4s | 7s |
| 4 | 8s | 15s |
| 5 | 16s | 31s |

After max retries, task is marked FAILED and user is notified.

---

*Error Recovery Module V12.0 - Orchestrator Extension*
