# Orchestrator Documentation Index V12.0

> **Version:** 12.0 | **Last Updated:** 2026-02-27
> **Total Documents:** 17 | **Total Lines:** ~7,700

---

## Overview

| # | Document | Description | Lines |
|---|----------|-------------|-------|
| 1 | [changelog.md](./changelog.md) | Version history and release notes | 180 |
| 2 | [AUDIT-REPORT-V12.0.md](./AUDIT-REPORT-V12.0.md) | Deep audit findings and resolutions | 413 |
| 3 | [setup-guide.md](./setup-guide.md) | Step-by-step installation and configuration | 74 |
| 4 | [architecture.md](./architecture.md) | System architecture and component overview | 124 |
| 5 | [troubleshooting.md](./troubleshooting.md) | Common issues and solutions | 139 |
| 6 | [memory-integration.md](./memory-integration.md) | Persistent context across sessions | 735 |
| 7 | [health-check.md](./health-check.md) | System health monitoring and diagnostics | 819 |
| 8 | [observability.md](./observability.md) | Metrics, logging, tracing, alerting | 1,164 |
| 9 | [test-suite.md](./test-suite.md) | Comprehensive validation tests (58 tests) | ~1,500 |
| 10 | [examples.md](./examples.md) | End-to-end workflow examples | 248 |
| 11 | [error-recovery.md](./error-recovery.md) | Automatic error detection and fallback | 149 |
| 12 | [windows-support.md](./windows-support.md) | Windows-specific configuration | 112 |
| 13 | [routing-table.md](./routing-table.md) | Agent routing configuration (DEPRECATED) | 18 |
| 14 | [skills-reference.md](./skills-reference.md) | Claude Code skills system reference | 219 |
| 15 | [team-patterns.md](./team-patterns.md) | Agent team patterns (DEPRECATED) | 35 |
| 16 | [mcp-integration.md](./mcp-integration.md) | MCP server management and routing | 171 |

---

## Quick Links

### Getting Started
- [Setup Guide](./setup-guide.md) - Start here for installation
- [Architecture](./architecture.md) - Understand the system design
- [Examples](./examples.md) - Learn by example workflows

### Troubleshooting
- [Troubleshooting Guide](./troubleshooting.md) - Fix common issues
- [Error Recovery](./error-recovery.md) - Automatic recovery system
- [Windows Support](./windows-support.md) - Platform-specific notes

### Reference
- [Health Check](./health-check.md) - System diagnostics
- [Observability](./observability.md) - Monitoring and alerting
- [Memory Integration](./memory-integration.md) - Context persistence
- [Test Suite](./test-suite.md) - Validation tests

---

## Detailed Documentation

### Core Documentation

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **setup-guide.md** | Installation and first-time setup | New installations, verifying configuration |
| **architecture.md** | System design, data flow, component map | Understanding how parts connect |
| **troubleshooting.md** | Diagnostics and problem resolution | When things go wrong |
| **examples.md** | 7 end-to-end workflow examples | Learning orchestrator patterns |
| **format-standard.md** | Rules format standardization | When creating/migrating rules files |

### System Modules

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **memory-integration.md** | Cross-session context persistence | Implementing memory features |
| **health-check.md** | 6 diagnostic check types | Running system diagnostics |
| **observability.md** | Metrics, logs, traces, alerts | Setting up monitoring |
| **error-recovery.md** | Recovery matrix, fallback chains | Handling failures gracefully |

### Platform & Integration

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **windows-support.md** | Windows-specific commands and issues | On Windows platforms |
| **mcp-integration.md** | MCP servers, native tools, marketplace | Configuring external tools |
| **skills-reference.md** | Claude Code skills system | Creating or using skills |

### Testing & Quality

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **test-suite.md** | 58 tests across 11 categories | Validating system health |

### Legacy (Deprecated)
| Document | Status | Replacement |
|----------|--------|-------------|
| **routing-table.md** | DEPRECATED | Integrated in SKILL.md V10.0+ |
| **team-patterns.md** | DEPRECATED | Integrated in SKILL.md V10.0+ |

### Standards
| Document | Status | Purpose |
|----------|--------|---------|
| **format-standard.md** | NEW | Rules format standardization |

---

## Document Categories

### By Function

```
CORE SYSTEM
  setup-guide.md
  architecture.md
  examples.md

OPERATIONS
  health-check.md
  observability.md
  error-recovery.md
  troubleshooting.md

DATA & CONTEXT
  memory-integration.md

INTEGRATION
  mcp-integration.md
  skills-reference.md

PLATFORM
  windows-support.md

QUALITY
  test-suite.md

LEGACY
  routing-table.md (deprecated)
  team-patterns.md (deprecated)
```

### By Priority

| Priority | Documents |
|----------|-----------|
| **CRITICAL** | setup-guide.md, architecture.md, troubleshooting.md |
| **HIGH** | memory-integration.md, health-check.md, observability.md, error-recovery.md |
| **MEDIUM** | mcp-integration.md, skills-reference.md, test-suite.md, examples.md |
| **LOW** | windows-support.md, routing-table.md, team-patterns.md |

---

## External References

### Main Files
- **Main SKILL.md:** [../SKILL.md](../SKILL.md)
- **Version Info:** [../../../VERSION.json](../../../VERSION.json)

### Related Directories
- **Agents:** [../../../agents/](../../../agents/) - 43 agent definitions (6 core + 22 L1 + 15 L2)
- **Skills:** [../../../skills/](../../../skills/) - 26 skills
- **Rules:** [../../../rules/](../../../rules/) - 10 rule files
- **Learnings:** [../../../learnings/](../../../learnings/) - instincts.json
- **Templates:** [../../../templates/](../../../templates/) - 3 templates
- **Workflows:** [../../../workflows/](../../../workflows/) - 4 workflows

### Configuration
- **Settings:** [../../../settings.json](../../../settings.json)
- **Agent Registry:** [../../../plugins/orchestrator-plugin/config/agent-registry.json](../../../plugins/orchestrator-plugin/config/agent-registry.json)

---

## Document Stats

| Metric | Value |
|--------|-------|
| Total Documents | 17 |
| Active Documents | 15 |
| Deprecated Documents | 2 |
| Total Lines | ~7,300 |
| Largest Document | test-suite.md (~1,500 lines) |
| Smallest Document | routing-table.md (18 lines) |

---

## Maintenance Notes

### Last Updated
- **V12.0:** 2026-02-26 - Comprehensive audit (56 issues fixed), changelog.md created
- **V11.3.1:** 2026-02-26 - Deep audit fixes, INDEX.md created
- **V11.3:** 2026-02-26 - Version bump, documentation alignment
- **V11.2:** 2026-02-26 - Audit fixes, added setup-guide, troubleshooting, architecture

### Deprecated Files
The following files are retained for backward compatibility but content has been migrated to SKILL.md:
- `routing-table.md` - Agent routing now in SKILL.md
- `team-patterns.md` - Team patterns now in SKILL.md

---

*Orchestrator Documentation Index V12.0 - Generated 2026-02-26*
