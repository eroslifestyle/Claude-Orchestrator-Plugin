# Claude Orchestrator Plugin

[![Version](https://img.shields.io/badge/version-12.0.3-blue.svg)](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-orange.svg)](https://claude.ai/code)

> Transform Claude Code into a team of 43 specialized AI agents working in parallel.

---

## Overview

The **Claude Orchestrator Plugin** is a multi-agent orchestration system that transforms Claude Code from a single assistant into a coordinated team of specialized experts. It automatically routes tasks to the right agent, enforces parallelism, and manages complex workflows.

### Key Features

- **43 Specialized Agents**: 6 core agents, 22 L1 experts, 15 L2 specialists
- **26 Skills**: Core, utility, workflow, language, and learning skills
- **Intelligent Routing**: Automatic task-to-agent matching via keyword detection
- **Maximum Parallelism**: Independent tasks execute simultaneously in a single message
- **Context-Aware Rules Engine**: Token-efficient rule loading based on task type
- **Continuous Learning**: Captures patterns and promotes them over time
- **Cross-Platform**: Native support for Windows, macOS, and Linux

### Architecture Diagram

```
+------------------------------------------------------------------+
|                        USER REQUEST                               |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                      ORCHESTRATOR                                 |
|                    (Commander - Never Works)                      |
+------------------------------------------------------------------+
         |                    |                    |
         v                    v                    v
+----------------+  +------------------+  +------------------+
|  CORE AGENTS   |  |   L1 EXPERTS    |  |   L2 SPECIALISTS |
|      (6)       |  |      (22)       |  |       (15)       |
+----------------+  +------------------+  +------------------+
| - Analyzer     |  | - Database      |  | - Query Optimizer|
| - Coder        |  | - Security      |  | - Auth Specialist|
| - Reviewer     |  | - DevOps        |  | - Pipeline Spec. |
| - Documenter   |  | - GUI Super     |  | - Layout Spec.   |
| - System Coord |  | - MQL/Trading   |  | - Risk Calculator|
| - Orchestrator |  | - ...18 more    |  | - ...11 more     |
+----------------+  +------------------+  +------------------+
         |                    |                    |
         v                    v                    v
+------------------------------------------------------------------+
|              PARALLEL EXECUTION (Single Message)                  |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|                      VERIFICATION LOOP                           |
|              Reviewer validates all code changes                  |
+------------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------------+
|              DOCUMENTATION + LEARNING CAPTURE                     |
+------------------------------------------------------------------+
```

---

## Quick Start

### One-Line Install

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.ps1 | iex
```

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.sh | bash
```

**What the installer does:**
1. Creates backup of existing `~/.claude` directory
2. Downloads and extracts the plugin to `~/.claude/skills/orchestrator`
3. Copies agent definitions to `~/.claude/agents/`
4. Optionally configures settings for Agent Teams

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Claude Code CLI** | Latest | [Download here](https://claude.ai/code) |
| **Python** | 3.10+ | Required for MCP integration |
| **Git** | Any | Optional, for clone-based installation |

---

## Installation

### Option A: One-Liner (Recommended)

See [Quick Start](#quick-start) above.

### Option B: Git Clone

**Windows (PowerShell):**
```powershell
# Backup existing configuration
if (Test-Path "$env:USERPROFILE\.claude") {
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Rename-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude.backup.$timestamp"
}

# Clone directly
Set-Location $env:USERPROFILE
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git .claude
```

**Linux / macOS:**
```bash
# Backup existing configuration
[ -d ~/.claude ] && mv ~/.claude ~/.claude.backup.$(date +%Y%m%d%H%M%S)

# Clone directly
cd ~ && git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git .claude
```

### Option C: Manual Copy

Clone to a temporary directory and copy what you need:

```bash
# Clone to temp
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git /tmp/orchestrator

# Copy skill only
mkdir -p ~/.claude/skills
cp -r /tmp/orchestrator ~/.claude/skills/orchestrator

# Copy agents (optional)
cp -r /tmp/orchestrator/agents ~/.claude/agents

# Cleanup
rm -rf /tmp/orchestrator
```

---

## Post-Installation

### 1. Enable Agent Teams (Recommended)

Create or edit `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 2. Restart Claude Code

Close and reopen Claude Code to pick up the new skill.

### 3. Verify Installation

```bash
# Check file structure
ls ~/.claude/skills/orchestrator/

# Expected output:
# SKILL.md  README.md  CHANGELOG.md  agents/  docs/  VERSION.json
```

### 4. Test the Orchestrator

In Claude Code, type:
```
/orchestrator
```

You should see the orchestrator activate and confirm it's ready.

---

## Architecture

### Directory Structure

```
~/.claude/
|-- CLAUDE.md                    # Global instructions (auto-activates orchestrator)
|-- settings.json                # Claude Code settings
|
|-- skills/
|   |-- orchestrator/            # Main orchestrator skill
|       |-- SKILL.md             # Skill definition (560 lines)
|       |-- README.md            # Documentation
|       |-- QUICKSTART.md        # Quick start guide
|       |-- CHANGELOG.md         # Version history
|       |-- docs/                # Detailed documentation
|       |   |-- architecture.md
|       |   |-- routing-table.md
|       |   |-- error-recovery.md
|       |   |-- mcp-integration.md
|       |   |-- memory-integration.md
|       |   |-- health-check.md
|       |   |-- observability.md
|       |   |-- windows-support.md
|       |   |-- skills-reference.md
|       |   |-- examples.md
|       |   |-- test-suite.md
|       |   |-- troubleshooting.md
|       |   |-- setup-guide.md
|       |   |-- INDEX.md
|       |
|       |-- learn/               # Learning skill
|       |-- code-review/         # Code review skill
|       |-- ... (26 skills total)
|
|-- agents/
|   |-- core/                    # 6 core agents
|   |   |-- orchestrator.md
|   |   |-- analyzer.md
|   |   |-- coder.md
|   |   |-- reviewer.md
|   |   |-- documenter.md
|   |   |-- system_coordinator.md
|   |
|   |-- experts/                 # 22 L1 experts
|   |   |-- database_expert.md
|   |   |-- security_unified_expert.md
|   |   |-- devops_expert.md
|   |   |-- gui-super-expert.md
|   |   |-- ... (18 more)
|   |
|   |-- experts/L2/              # 15 L2 specialists
|   |   |-- db-query-optimizer.md
|   |   |-- security-auth-specialist.md
|   |   |-- devops-pipeline-specialist.md
|   |   |-- ... (12 more)
|   |
|   |-- system/                  # System components
|   |   |-- PROTOCOL.md
|   |   |-- AGENT_REGISTRY.md
|   |   |-- COMMUNICATION_HUB.md
|   |
|   |-- config/                  # Configuration
|   |   |-- routing.md
|   |   |-- standards.md
|   |
|   |-- workflows/               # 4 workflow templates
|   |-- templates/               # 3 task templates
|
|-- rules/                       # Context-aware rules engine
|   |-- common/
|   |   |-- coding-style.md      # 47 rules
|   |   |-- security.md          # 100 rules
|   |   |-- testing.md           # 49 rules
|   |   |-- database.md          # 50 rules
|   |   |-- api-design.md        # 50 rules
|   |   |-- git-workflow.md      # 42 rules
|   |
|   |-- python/patterns.md       # Python-specific rules
|   |-- typescript/patterns.md   # TypeScript-specific rules
|   |-- go/patterns.md           # Go-specific rules
|
|-- learnings/                   # Continuous learning
|   |-- instincts.json           # Learned patterns
|
|-- memory/                      # Project memory
    |-- MEMORY.md
```

---

## Components

### Core Agents (6)

| Agent | Role | Model | Description |
|-------|------|-------|-------------|
| **Orchestrator** | Commander | opus | Delegates ALL work, never executes directly |
| **Analyzer** | Explorer | haiku | Structure exploration, dependency mapping, issue detection |
| **Coder** | Implementer | inherit | Writes and modifies code with tests |
| **Reviewer** | Validator | inherit | Code review, best practices, security checks |
| **Documenter** | Scribe | haiku | Manages docs, changelogs, captures learnings |
| **System Coordinator** | Manager | haiku | Token tracking, metrics, cleanup |

### L1 Experts (22)

| Expert | Domain | Keywords |
|--------|--------|----------|
| Database Expert | Data Architecture | SQL, NoSQL, schema design, performance |
| Security Unified Expert | AppSec | Encryption, IAM, cyber defense |
| DevOps Expert | Infrastructure | CI/CD, Kubernetes, IaC, monitoring |
| GUI Super Expert | User Interfaces | PyQt5, NiceGUI, design systems |
| Integration Expert | APIs | REST, webhooks, Telegram, WhatsApp |
| Architect Expert | System Design | Distributed systems, blueprints |
| Languages Expert | Multi-Language | Python, JavaScript, C#, idioms |
| AI Integration Expert | AI/ML | LLM, GPT, RAG, embeddings |
| MQL Expert | Trading | MetaTrader, EA architecture |
| Trading Strategy Expert | Finance | Risk management, position sizing |
| Mobile Expert | Apps | iOS, Android, Flutter |
| N8N Expert | Automation | Workflow design, low-code |
| Claude Systems Expert | Optimization | Haiku/Sonnet/Opus, cost efficiency |
| Tester Expert | QA | Test architecture, debugging |
| Social Identity Expert | Auth | OAuth, OIDC, social login |
| MCP Integration Expert | Plugins | Tool discovery, deferred loading |
| Notification Expert | Messaging | Slack, Discord, push notifications |
| Payment Integration Expert | Commerce | Stripe, PayPal, subscriptions |
| Browser Automation Expert | E2E | Playwright, web scraping |
| Reverse Engineering Expert | Binary | IDA Pro, Ghidra, firmware |
| Offensive Security Expert | Pentest | Red team, exploit development |
| MQL Decompilation Expert | Reverse | .ex4/.ex5 analysis |

### L2 Specialists (15)

Specialists are sub-experts that handle specific tasks within their parent's domain:

| L2 Specialist | Parent | Specialty |
|---------------|--------|-----------|
| DB Query Optimizer | Database Expert | Query optimization, indexing, N+1 fixes |
| Security Auth Specialist | Security Expert | JWT, MFA, session security |
| DevOps Pipeline Specialist | DevOps Expert | CI/CD pipelines, GitHub Actions |
| GUI Layout Specialist | GUI Super Expert | Qt layouts, sidebars, dashboards |
| API Endpoint Builder | Integration Expert | REST endpoints, CRUD, versioning |
| Test Unit Specialist | Tester Expert | pytest, mocking, fixtures, TDD |
| MQL Optimization | MQL Expert | EA performance, memory, tick processing |
| Trading Risk Calculator | Trading Expert | Position sizing, Kelly criterion |
| Mobile UI Specialist | Mobile Expert | Flutter/React Native layouts |
| N8N Workflow Builder | N8N Expert | Workflow design, error handling |
| Claude Prompt Optimizer | Claude Systems Expert | Prompt engineering, token optimization |
| Architect Design Specialist | Architect Expert | Design patterns, SOLID, DDD |
| Languages Refactor Specialist | Languages Expert | Refactoring patterns, clean code |
| AI Model Specialist | AI Integration Expert | Model selection, fine-tuning, RAG |
| Social OAuth Specialist | Social Identity Expert | OAuth2 flows, provider integration |

---

### Skills (26)

| Category | Skills | Count |
|----------|--------|-------|
| **Core** | orchestrator, code-review, git-workflow, testing-strategy, debugging, api-design, remotion-best-practices | 7 |
| **Utility** | strategic-compact, verification-loop, checkpoint, sessions, status, metrics | 6 |
| **Workflow** | plan, tdd-workflow, security-scan, refactor-clean, build-fix, multi-plan, fix, cleanup | 8 |
| **Language** | python-patterns, typescript-patterns, go-patterns | 3 |
| **Learning** | learn, evolve | 2 |

---

### Rules Engine

Context-aware rule loading for token efficiency:

| Rules File | Rules | Loads When |
|------------|-------|------------|
| `common/coding-style.md` | 47 | Always (code tasks) |
| `common/security.md` | 100 | Auth, API, data handling |
| `common/testing.md` | 49 | Writing/reviewing tests |
| `common/database.md` | 50 | SQL, ORM, schema work |
| `common/api-design.md` | 50 | REST, GraphQL, endpoints |
| `common/git-workflow.md` | 42 | Git operations |
| `python/patterns.md` | 20+ | .py files detected |
| `typescript/patterns.md` | 20+ | .ts/.tsx files detected |
| `go/patterns.md` | 15+ | .go files detected |

**Token Budget:** Max 500 tokens per subagent for rules injection.

---

### MCP Integration

#### Configured MCP Servers

| Server | Type | Status |
|--------|------|--------|
| orchestrator | stdio (Python) | Active |

#### Native Tools (Built into Claude Code)

| Tool | Function |
|------|----------|
| Canva | Design generation, editing, export |
| Web Reader | URL content extraction |
| Web Search Prime | Web search with filters |
| ZAI MCP Server | Image/video analysis, UI processing |

---

## Usage Examples

### Basic Commands

```
"Analyze this codebase and suggest improvements"
"Create a REST API with authentication"
"Fix the bug in auth.py and add tests"
"Review my database schema for security issues"
"Build a dashboard with charts"
```

### With Orchestrator Invocation

```
/orchestrator analyze the codebase
/orchestrator implement user authentication
/orchestrator review and fix all TODOs
```

### Slash Commands Reference

| Command | Description | Example |
|---------|-------------|---------|
| `/plan` | Create implementation plan | `/plan Add OAuth login` |
| `/review` | Code review | `/review src/auth.py` |
| `/test` | Run tests | `/test --coverage` |
| `/tdd` | TDD workflow | `/tdd User validation` |
| `/fix` | Fix bug | `/fix TypeError in login` |
| `/build-fix` | Fix build errors | `/build-fix` |
| `/debug` | Debug investigation | `/debug Why is session null?` |
| `/refactor` | Clean code | `/refactor auth module` |
| `/security-scan` | Security audit | `/security-scan API endpoints` |
| `/learn` | Capture learnings | `/learn` |
| `/evolve` | Promote patterns | `/evolve` |
| `/checkpoint` | Save checkpoint | `/checkpoint before-refactor` |
| `/compact` | Strategic compact | `/compact` |
| `/status` | System health | `/status` |
| `/metrics` | Session metrics | `/metrics` |
| `/cleanup` | Session cleanup | `/cleanup` |
| `/multi-plan` | Multi-approach plan | `/multi-plan Database migration` |

### Parallel Execution Examples

**Fix 3 bugs in different areas:**
```
"Fix the auth timeout, the database connection leak, and the UI flickering"
```
Orchestrator routes to Security Expert, Database Expert, and GUI Expert - all in parallel.

**Analyze then implement:**
```
"Analyze the codebase structure and then implement user profiles"
```
T1: Analyzer (haiku) -> T2: Coder (depends on T1)

**Full security audit:**
```
"Run a complete security audit"
```
Creates agent team with Security Expert, Reviewer, and Tester Expert.

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **"Skill not found"** | Verify path: `~/.claude/skills/orchestrator/SKILL.md` and restart Claude Code |
| **"Agent Teams not working"** | Check `settings.json` has `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` |
| **"Permission denied"** | Ensure write permissions to `~/.claude/` |
| **"Git clone fails"** | Install git: `winget install Git.Git` (Win) or `brew install git` (Mac) |
| **"model: sonnet causes 404"** | Use `model: "haiku"` or `model: "opus"`, or omit to inherit |

### Windows-Specific

| Issue | Solution |
|-------|----------|
| **NUL file created** | Run cleanup via `/cleanup` or use Win32 API deletion |
| **Process won't terminate** | Use `taskkill /F /IM python.exe` (kills ALL Python) |
| **Teammate mode** | Use `in-process` mode (default) |

### Check Installation

```bash
# Verify skill exists
cat ~/.claude/skills/orchestrator/SKILL.md | head -5

# Verify agents
ls ~/.claude/agents/core/
ls ~/.claude/agents/experts/

# Verify settings
cat ~/.claude/settings.json
```

---

## Contributing

We welcome contributions! Here's how to get started:

### Development Setup

1. **Fork the repository**
2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Claude-Orchestrator-Plugin.git
   cd Claude-Orchestrator-Plugin
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes**
5. **Test locally:**
   ```bash
   cp -r . ~/.claude/skills/orchestrator
   # Restart Claude Code and test
   ```
6. **Submit a pull request**

### Contribution Guidelines

- Follow existing code style and documentation format
- Update CHANGELOG.md with your changes
- Add tests for new functionality
- Keep agent definitions under 300 lines
- Update routing table if adding new agents

### Areas for Contribution

- New agent definitions for specialized domains
- Additional workflow templates
- More comprehensive test coverage
- Documentation improvements
- Bug fixes and performance optimizations

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 eroslifestyle

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
```

---

## Credits

### Author

**eroslifestyle** - [GitHub](https://github.com/eroslifestyle)

### Acknowledgments

- Anthropic for Claude Code and the amazing Claude models
- The open-source community for inspiration and tools
- All contributors who help improve this project

### Version History

| Version | Date | Highlights |
|---------|------|------------|
| **V12.0.3** | 2026-02-27 | Full coherence achieved, all verification checks passed |
| **V12.0** | 2026-02-26 | Deep audit complete, 43 agents, 26 skills, rules engine |
| **V11.0** | 2026-02-26 | Learning system, slash commands, hooks integration |
| **V10.0** | 2026-02-21 | Memory, health check, observability, error recovery |
| **V8.0** | 2026-02-15 | Agent Teams, 39 agents |
| **V7.0** | 2026-02-10 | MCP Integration, LSP support |
| **V5.0-6.0** | 2026-01-28 | Windows support, parallel execution |

---

## Support

- **GitHub Issues:** [Report bugs or request features](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/issues)
- **Documentation:** See `docs/` folder for detailed guides
- **Version:** Check `VERSION.json` for current version

---

<p align="center">
  <strong>Orchestrator V12.0.3 Full Coherence</strong><br>
  <em>Shorter prompts. Better compliance. Continuous learning.</em>
</p>
