# Claude Orchestrator Plugin

![Version](https://img.shields.io/badge/version-12.0.0--DEEP--AUDIT-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Claude Code](https://img.shields.io/badge/Claude%20Code-Opus%204.6-orange)

> A fully integrated multi-agent orchestrator for Claude Code with 43 specialized agents, Agent Teams support, Memory integration, Health Check system, and Observability.

---

## Quick Start

### Windows (One-Liner)

```powershell
irm https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.ps1 | iex
```

### macOS/Linux (One-Liner)

```bash
curl -fsSL https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git

# Copy to Claude skills directory
# Windows
xcopy /E /I Claude-Orchestrator-Plugin "%USERPROFILE%\.claude\skills\orchestrator"

# macOS/Linux
cp -r Claude-Orchestrator-Plugin ~/.claude/skills/orchestrator
```

---

## Requirements

| Requirement | Description |
|-------------|-------------|
| Claude Code | Must be installed ([Download](https://claude.ai/code)) |
| PowerShell 5.1+ | Windows users |
| Bash | macOS/Linux users |
| Agent Teams (Optional) | Enable via environment variable |

### Enable Agent Teams (Optional)

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Restart Claude Code after modifying settings.

---

## Verify Installation

```bash
# Start Claude Code
claude

# Test orchestrator
/orchestrator help
```

Expected output:
```
ORCHESTRATOR V12.0 DEEP AUDIT | FULLY INTEGRATED EDITION
Ready to coordinate tasks across 43 specialized agents.
```

---

## Quick Example

```bash
# Simply type your request - orchestrator activates automatically
# Example: "Fix the bug in auth.py and add unit tests"

# Or invoke explicitly:
/orchestrator analyze the codebase structure and suggest improvements
```

The orchestrator will:
1. Analyze your request
2. Route to appropriate agents
3. Execute tasks in parallel when possible
4. Return consolidated results

---

## Plugin Contents

### Directory Structure

```
orchestrator/
├── SKILL.md                    # Main orchestrator skill (V12.0)
├── README.md                   # This file
├── docs/
│   ├── routing-table.md        # Agent routing rules (DEPRECATED)
│   ├── team-patterns.md        # Agent team patterns (DEPRECATED)
│   ├── skills-reference.md     # Skill creation guide
│   ├── examples.md             # Usage examples
│   ├── memory-integration.md   # Memory system docs
│   ├── health-check.md         # Diagnostic system
│   └── observability.md        # Metrics and monitoring
├── agents/
│   ├── core/                   # L0 Core agents (6)
│   ├── experts/                # L1 Expert agents (22)
│   │   └── L2/                 # L2 Specialists (15)
│   ├── system/                 # System protocols
│   ├── config/                 # Configuration files
│   ├── docs/                   # Agent documentation
│   ├── templates/              # Task templates
│   └── workflows/              # Workflow definitions
└── install.ps1                 # Windows installer
```

### Included Agents (43)

#### L0 - Core Agents (6)

| Agent | Role | Model |
|-------|------|-------|
| Orchestrator | Central coordinator | inherit |
| Analyzer | Code analysis, exploration | haiku |
| Coder | Implementation, fixes | inherit |
| Reviewer | Code review, quality | inherit |
| Documenter | Documentation updates | haiku |
| System Coordinator | Cleanup, maintenance | haiku |

#### L1 - Expert Agents (22)

| Agent | Specialization | Keywords |
|-------|----------------|----------|
| GUI Super Expert | PyQt5, Qt, NiceGUI, CSS, themes | GUI, UI, widget |
| Database Expert | SQL, schema, SQLite | database, SQL |
| Security Unified Expert | Encryption, validation | security, encryption |
| Offensive Security Expert | Pentesting, OWASP, exploits | pentest, red team |
| Reverse Engineering Expert | Binary analysis, IDA, Ghidra | disassemble, malware |
| Integration Expert | REST, webhooks, APIs | API, REST, webhook |
| Tester Expert | QA, test architecture | test, debug, QA |
| MQL Expert | MetaTrader, EA development | MQL, EA, MT5 |
| MQL Decompilation Expert | .ex4/.ex5 reverse engineering | decompile, EA protection |
| Trading Strategy Expert | Risk management, strategies | trading, strategy |
| Mobile Expert | iOS, Android, cross-platform | mobile, iOS, Android |
| N8N Expert | Workflow automation | n8n, automation |
| AI Integration Expert | LLM APIs, RAG, embeddings | AI, LLM, GPT |
| Claude Systems Expert | Model selection, tokens | Claude, prompt |
| Social Identity Expert | OAuth2, OIDC providers | OAuth, social login |
| Languages Expert | Python, JS, C#, syntax | Python, JS, coding |
| Architect Expert | System design, patterns | architecture, design |
| DevOps Expert | CI/CD, Kubernetes, monitoring | DevOps, deploy |
| Notification Expert | Messaging, alerts | notification, alert |
| Browser Automation Expert | Playwright, e2e, scraping | playwright, browser |
| MCP Integration Expert | MCP protocol, tool discovery | MCP, plugin |
| Payment Integration Expert | Stripe, PayPal, checkout | payment, checkout |

#### L2 - Specialist Agents (15)

| Agent | Parent | Specialization |
|-------|--------|----------------|
| GUI Layout Specialist | GUI Super Expert | Layout, sizing, splitters |
| DB Query Optimizer | Database Expert | Query optimization, indexes |
| Security Auth Specialist | Security Unified Expert | JWT, MFA, RBAC |
| API Endpoint Builder | Integration Expert | REST endpoints, CRUD |
| Test Unit Specialist | Tester Expert | pytest, mocking, TDD |
| MQL Optimization | MQL Expert | EA performance, memory |
| Trading Risk Calculator | Trading Strategy Expert | Position sizing, drawdown |
| Mobile UI Specialist | Mobile Expert | Responsive, SafeArea |
| N8N Workflow Builder | N8N Expert | Workflow design, error handling |
| AI Model Specialist | AI Integration Expert | Model selection, fine-tuning |
| Claude Prompt Optimizer | Claude Systems Expert | Token optimization, few-shot |
| Social OAuth Specialist | Social Identity Expert | OAuth2 flows, PKCE |
| Languages Refactor Specialist | Languages Expert | Clean code, code smells |
| Architect Design Specialist | Architect Expert | SOLID, DDD, microservices |
| DevOps Pipeline Specialist | DevOps Expert | GitHub Actions, Docker |

---

## Configuration

### Agent Teams Mode

Teammate mode is controlled via CLI flag:

```bash
# Windows default (no tmux)
claude --teammate-mode in-process

# Auto-detect tmux
claude --teammate-mode auto

# Force split panes (requires tmux/iTerm2)
claude --teammate-mode tmux
```

### MCP Plugin Compatibility

| Plugin | Purpose | Windows | macOS/Linux |
|--------|---------|---------|-------------|
| web-reader | Fetch web content | Supported | Supported |
| web-search-prime | Web search | Supported | Supported |
| canva | Design/graphics | Supported | Supported |
| slack | Slack messaging | Supported | Supported |
| orchestrator-mcp | Multi-agent coordination | Supported | Supported |
| zai-mcp-server | UI analysis | Supported | Supported |
| 4_5v_mcp | Image analysis | Supported | Supported |
| firebase | Real-time DB | Supported | Supported |

### LSP Plugins

| Plugin | Language | Features |
|--------|----------|----------|
| clangd-lsp | C/C++ | IntelliSense, go-to-def |
| jdtls-lsp | Java | Maven, Gradle, Spring |
| swift-lsp | Swift | iOS, SwiftUI, Xcode |

---

## Documentation

| Document | Description |
|----------|-------------|
| [SKILL.md](SKILL.md) | Main orchestrator instructions (V12.0) |
| [docs/routing-table.md](docs/routing-table.md) | DEPRECATED - see SKILL.md |
| [docs/team-patterns.md](docs/team-patterns.md) | DEPRECATED - see SKILL.md |
| [docs/skills-reference.md](docs/skills-reference.md) | Skill creation guide |
| [docs/examples.md](docs/examples.md) | Usage examples |
| [docs/memory-integration.md](docs/memory-integration.md) | Memory system |
| [docs/health-check.md](docs/health-check.md) | Diagnostic system |
| [docs/observability.md](docs/observability.md) | Metrics and monitoring |
| [agents/INDEX.md](agents/INDEX.md) | Agent hierarchy index |

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Command not found | Ensure Claude Code is in PATH |
| Agent Teams not working | Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json |
| MCP tools not loading | Run `ToolSearch(query="plugin_name")` before calling |
| Permission denied | Check file permissions on `~/.claude/skills/` |
| Session not resuming | Agent Teams require respawning after restart |
| `model: "sonnet"` causes 404 | Omit model parameter to inherit from parent |

### Health Check

Run diagnostics:

```bash
/orchestrator HealthCheck()
```

Output shows status of all subsystems:
- Agent Teams status
- MCP connections
- Memory loaded
- Routing table
- Filesystem space

### Log Location

Session logs stored at:
```
~/.claude/logs/orchestrator/session_{timestamp}.log
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| V12.0 DEEP AUDIT | 2026-02-26 | Agent count fix (43), circuit-breaker complete, version alignment, model consistency |
| V11.3 AUDIT FIX | 2026-02-26 | Step ordering, MCP section, skills catalog (26), 4 new L1 agents |
| V11.0 NEW GEN | 2026-02-26 | Learning, Rules Engine, Hooks, 24 skills, Slash Commands |
| V10.2 ULTRA | 2026-02-21 | Notification Expert, inter-teammate communication, fallback chains |
| V10.0 ULTRA | 2026-02-21 | Memory integration, health check, observability |
| V8.0 SLIM | 2026-02-15 | Agent Teams edition, 39 agents |
| V7.0 | 2026-02-10 | MCP integration, LSP support |
| V6.0 | 2026-02-05 | Parallel execution optimization |
| V5.0 | 2026-01-28 | Windows support, cleanup automation |

---

## Key Features

### Maximum Parallelism

Independent tasks execute simultaneously. The orchestrator routes N tasks to N agents in a single batch, dramatically reducing execution time.

### Agent Teams

For complex work requiring coordination, spawn multiple agents that can communicate, share findings, and challenge each other's conclusions.

### Memory Integration

Project memory persists across sessions. Agents learn from previous decisions and avoid repeating past mistakes.

### Health Check System

Automatic diagnostics detect issues before they impact work. Recovery protocols handle errors gracefully.

### Observability

Real-time metrics dashboard tracks:
- Task completion rates
- Agent usage patterns
- Parallel efficiency
- Error rates
- Session duration

### Error Recovery

Comprehensive fallback chains ensure tasks complete even when primary agents fail. Automatic retry with exponential backoff for rate limits.

---

## Support

- **GitHub Issues:** [https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/issues](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/issues)
- **Documentation:** See `docs/` directory

---

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

**ORCHESTRATOR V12.0 DEEP AUDIT | FULLY INTEGRATED EDITION**
*Score Target: 10/10 | All Systems Operational*
