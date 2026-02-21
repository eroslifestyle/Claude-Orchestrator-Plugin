# Changelog

All notable changes to Claude Orchestrator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [10.1.0] - 2026-02-21

### Added
- **SUBAGENT PROTOCOL**: Context isolation for all subagents - each task executes as if `/clear` was run first
- **Memory Integration System**: Automatic context loading from project memory files
- **Health Check System**: Automatic diagnostics at startup, pre-task, post-task, and on error
- **Observability Framework**: Real-time metrics collection and dashboard (`/orchestrator metrics`)
- **Session Logging**: All orchestrator actions logged to `~/.claude/logs/orchestrator/`
- **Performance Tracking**: Agent performance metrics stored in `performance.yaml`
- **MCP Plugin Integration**: 8 plugins ready (web-reader, web-search, canva, slack, orchestrator-mcp, zai-mcp, 4_5v_mcp, firebase)
- **LSP Plugins**: Language servers for C/C++, Java, and Swift
- **Skill Plugins**: HuggingFace skills and interactive playgrounds
- **Agent Teams Support**: Experimental teammate mode with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Cross-Platform Installers**: Full PowerShell and Bash installers
- **Auto-Update System**: GitHub releases integration with backup/rollback support
- **Dual Profile Management**: Switch between Anthropic (cca) and GLM5 (ccg) profiles

### Changed
- **V10.0 ULTRA**: Enhanced error recovery with automatic retry and fallback chains
- **Agent Routing**: Improved keyword-based routing with 39 specialized agents
- **Parallelism**: Maximum parallel execution enforced at all levels
- **Documentation**: Comprehensive rewrite of all agent and skill documentation

### Fixed
- **Windows NUL File Handling**: Proper Win32 API deletion for Windows reserved names
- **Process Cleanup**: Automatic termination of orphaned Python processes
- **Hash Verification**: SHA256 hash comparison for profile switching reliability
- **Rate Limiting**: Proper hourly rate limiting for update checks

### Security
- **API Key Protection**: Template placeholders for sensitive configuration
- **Token Sanitization**: GITHUB_TOKEN support for authenticated API calls
- **Backup Encryption**: Secure backup storage before updates

---

## [10.0.0] - 2026-02-21

### Added
- **Memory Integration**: Load project context from MEMORY.md files
- **Health Check**: Automatic system diagnostics
- **Observability**: Real-time metrics and session logging
- **Enhanced Error Recovery**: Automatic retry with exponential backoff

### Changed
- Major refactor of orchestrator core
- Improved agent routing table
- Enhanced parallel execution

---

## [8.0.0] - 2026-02-15

### Added
- **Agent Teams Edition**: Spawn coordinated teams for complex tasks
- **39 Specialized Agents**: Full roster of L0, L1, and L2 agents
- **Team Patterns**: Parallel Review, Multi-Module Feature, Competing Hypotheses

### Changed
- Optimized task decomposition
- Improved team coordination

---

## [7.0.0] - 2026-02-10

### Added
- **MCP Integration**: Model Context Protocol support
- **LSP Support**: Language Server Protocol for code intelligence
- **Web Search**: Integrated web search capabilities

---

## [6.0.0] - 2026-02-05

### Added
- **Parallel Execution Optimization**: All independent tasks run simultaneously
- **Task Dependency Graph**: Automatic dependency resolution

### Changed
- Improved task status tracking
- Enhanced error reporting

---

## [5.0.0] - 2026-01-28

### Added
- **Windows Support**: Full PowerShell installer and profile management
- **Cleanup Automation**: Automatic temp file removal
- **Cross-Platform Scripts**: Unified behavior across Windows/Mac/Linux

---

## Version History Summary

| Version | Date | Major Features |
|---------|------|----------------|
| 10.1.0 | 2026-02-21 | Subagent Protocol, Memory, Health Check, Observability |
| 10.0.0 | 2026-02-21 | Enhanced Error Recovery, Agent Teams |
| 8.0.0 | 2026-02-15 | 39 Agents, Team Patterns |
| 7.0.0 | 2026-02-10 | MCP Integration, LSP Support |
| 6.0.0 | 2026-02-05 | Parallel Execution |
| 5.0.0 | 2026-01-28 | Windows Support, Cross-Platform |

---

## Migration Guides

### Upgrading from 8.x to 10.x

1. Run the updater:
   ```powershell
   ./updater/do-update.ps1
   ```

2. Or manually:
   ```bash
   git pull origin main
   ./setup.ps1 -Force
   ```

3. New environment variable required for Agent Teams:
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }
   ```

### Upgrading from 5.x to 8.x

1. Backup your settings:
   ```powershell
   Copy-Item ~/.claude/settings.json ~/.claude/settings.json.bak
   ```

2. Run the new installer:
   ```powershell
   ./setup.ps1 -Force
   ```

3. Reload your profile:
   ```powershell
   . $PROFILE
   ```

---

[10.1.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v10.1.0
[10.0.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v10.0.0
[8.0.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v8.0.0
[7.0.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v7.0.0
[6.0.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v6.0.0
[5.0.0]: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/releases/tag/v5.0.0
