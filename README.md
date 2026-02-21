# Claude Orchestrator V10.1 ULTRA

[![Version](https://img.shields.io/badge/version-10.1.0-blue.svg)](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-2.0%2B-purple.svg)]()

**Multi-Agent Orchestration System for Claude Code**

A powerful multi-agent system that transforms Claude Code into a coordinated team of 39 specialized AI agents, each an expert in their domain.

---

## Features

- **39 Specialized Agents** - From GUI development to reverse engineering, trading strategies to cloud deployment
- **Intelligent Routing** - Automatic task-to-agent matching based on context and keywords
- **Cross-Platform Support** - Works on Windows, macOS, and Linux
- **Auto-Update System** - Built-in version checking and automatic updates via GitHub releases
- **Dual Profile Support** - Seamlessly switch between Anthropic (cca) and GLM5 (ccg) API providers
- **Parallel Execution** - Run multiple independent tasks simultaneously for maximum efficiency
- **Agent Teams** - Spawn coordinated teams for complex multi-component features
- **Memory Integration** - Context persistence across sessions with intelligent pattern matching
- **Observability** - Real-time metrics, health checks, and session logging

---

## Quick Start

### Windows (PowerShell)

```powershell
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
cd Claude-Orchestrator-Plugin
./setup.ps1
```

### Mac/Linux (Bash)

```bash
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
cd Claude-Orchestrator-Plugin
chmod +x setup.sh
./setup.sh
```

---

## Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Claude Code** | 2.0.0+ | Latest |
| **PowerShell** (Windows) | 5.1 | 7.x |
| **Bash/Zsh** (Unix) | 4.0+ / 5.0+ | Latest |
| **Disk Space** | 50 MB | 100 MB |
| **Git** | Optional | Latest |

---

## Installation

### Windows Installation

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
   cd Claude-Orchestrator-Plugin
   ```

2. **Run the installer:**
   ```powershell
   ./setup.ps1
   ```

3. **Select components** (interactive mode):
   - `[1]` Core (skills + agents) - **REQUIRED**
   - `[2]` PowerShell Profile Integration (cca/ccg commands)
   - `[3]` Settings Templates
   - `[4]` MCP Plugin (if available)

4. **Restart your terminal** or run:
   ```powershell
   . $PROFILE
   ```

### Silent Installation (Windows)

```powershell
./setup.ps1 -Silent -Components "1,2,3"
```

### Mac/Linux Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
   cd Claude-Orchestrator-Plugin
   ```

2. **Make executable and run:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Silent Installation (Unix)

```bash
./setup.sh --silent --components 1,2,3
```

---

## Available Commands

After installation with profile integration (Component 2):

| Command | Description |
|---------|-------------|
| `cca` | Switch to Anthropic profile |
| `ccg` | Switch to GLM5 (Z.AI) profile |
| `claude` | Run Claude Code with active profile |
| `Test-ClaudeProfile` | Verify current profile configuration |
| `/orchestrator` | Activate the orchestrator skill in Claude Code |

---

## Usage

### Basic Orchestrator Invocation

Simply type `/orchestrator` followed by your request:

```
/orchestrator Analyze the codebase and implement a REST API with authentication
```

The orchestrator will:
1. Decompose your request into tasks
2. Route each task to the appropriate specialist agent
3. Execute tasks in parallel where possible
4. Coordinate results and provide a final report

### Available Agent Categories

| Level | Agents |
|-------|--------|
| **L0 Core** | Analyzer, Coder, Reviewer, Documenter, System Coordinator, Orchestrator |
| **L1 Experts** | GUI Super Expert, Database Expert, Security Expert, MQL Expert, Trading Strategy Expert, Tester Expert, Architect Expert, Integration Expert, DevOps Expert, Languages Expert, AI Integration Expert, Claude Systems Expert, Mobile Expert, N8N Expert, Social Identity Expert, Reverse Engineering Expert, Offensive Security Expert |
| **L2 Specialists** | GUI Layout, DB Query Optimizer, Security Auth, API Endpoint Builder, Test Unit, MQL Optimization, Trading Risk Calculator, Mobile UI, N8N Workflow Builder, Claude Prompt Optimizer, Architect Design, DevOps Pipeline, Languages Refactor, AI Model, Social OAuth |

### Example Workflows

**Feature Implementation:**
```
/orchestrator Create a user authentication system with JWT tokens, refresh tokens, and password reset functionality
```

**Code Review:**
```
/orchestrator Review the auth module for security vulnerabilities and suggest improvements
```

**Bug Investigation:**
```
/orchestrator Debug why the database connection is timing out under high load
```

**Multi-Platform Feature:**
```
/orchestrator Build a responsive dashboard with PyQt5 for desktop and Flutter for mobile
```

---

## Auto-Update System

Check for updates:
```powershell
# Windows
./updater/check-update.ps1

# Unix
./updater/check-update.sh
```

Perform update:
```powershell
# Windows
./updater/do-update.ps1

# Unix
./updater/do-update.sh
```

The update system:
- Creates automatic backups before updating
- Supports rollback on failure
- Can update via git pull or GitHub release download
- Respects rate limiting (1 check per hour)

---

## Project Structure

```
Claude-Orchestrator-Plugin/
├── core/
│   ├── skills/
│   │   └── orchestrator/        # Orchestrator skill definition
│   │       ├── SKILL.md         # Main skill file
│   │       ├── routing-table.md # Agent routing rules
│   │       ├── examples.md      # Usage examples
│   │       └── ...
│   └── agents/
│       ├── core/                # Core agents (Analyzer, Coder, etc.)
│       ├── experts/             # Expert-level agents
│       │   └── L2/              # Specialist agents
│       ├── system/              # System coordination files
│       └── config/              # Agent configuration
├── templates/
│   └── profiles/                # Shell profile templates
├── updater/                     # Auto-update scripts
│   ├── check-update.ps1
│   ├── check-update.sh
│   ├── do-update.ps1
│   └── do-update.sh
├── migrations/                  # Version migration scripts
├── docs/                        # Documentation
├── setup.ps1                    # Windows installer
├── setup.sh                     # Unix installer
├── VERSION.json                 # Version tracking
└── README.md                    # This file
```

---

## Configuration

### Settings Files

| File | Purpose |
|------|---------|
| `~/.claude/settings.json` | Active settings (auto-generated) |
| `~/.claude/settings-anthropic.json` | Anthropic OAuth settings |
| `~/.claude/settings-glm.json` | GLM5 (Z.AI) settings |

### Profile Switching

The system uses hash verification to ensure settings are copied correctly:

```powershell
# Switch to Anthropic
cca

# Switch to GLM5
ccg

# Verify current profile
Test-ClaudeProfile
```

---

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Update documentation for new features
- Add tests where applicable
- Update VERSION.json for version changes

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Credits

- **Claude Code** by Anthropic - The foundation AI assistant
- **Orchestrator V10.1 ULTRA** - Multi-agent coordination system
- **Community Contributors** - Bug reports, features, and improvements

---

## Support

- **Issues:** [GitHub Issues](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/issues)
- **Discussions:** [GitHub Discussions](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/discussions)
- **Releases:** [GitHub Releases](https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases)

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
