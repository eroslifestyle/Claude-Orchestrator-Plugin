# Claude Orchestrator Plugin V6.0 ULTRA

A powerful multi-agent orchestration system for Claude Code with hierarchical command structure, parallel execution, and 100% guaranteed fallback.

```
+==============================================================================+
|                                                                              |
|     OOOO   RRRR    CCCC  H   H  EEEEE   SSSS  TTTTT  RRRR    AAAA           |
|    O    O  R   R  C      H   H  E      S        T    R   R  A    A          |
|    O    O  RRRR   C      HHHHH  EEEE    SSS     T    RRRR   AAAAAA          |
|    O    O  R  R   C      H   H  E          S    T    R  R   A    A          |
|     OOOO   R   R   CCCC  H   H  EEEEE  SSSS     T    R   R  A    A          |
|                                                                              |
|                     V6.0 ULTRA - COMMAND & CONTROL                           |
|                                                                              |
+==============================================================================+
```

## Features

- **36 Specialized Agents** - 6 Core + 15 Experts + 15 L2 Sub-agents
- **6-Level Fallback System** - 100% guaranteed task completion
- **Forced Global Parallelism** - Up to 64 concurrent agents
- **Intelligent Model Selection** - Haiku/Sonnet/Opus based on task complexity
- **Auto-Execute Mode** - No confirmation needed, immediate action
- **Error Memory** - Never repeat the same mistakes

## Agent Hierarchy

```
                       +---------------------+
                       |    ORCHESTRATOR     |
                       |   V6.0 ULTRA        |
                       |  (SUPREME COMMAND)  |
                       +---------+-----------+
                                 |
          +----------------------+----------------------+
          |                      |                      |
 +--------v--------+    +--------v--------+    +--------v--------+
 |   CORE AGENTS   |    | EXPERT AGENTS   |    |  L2 SUB-AGENTS  |
 |     (6 units)   |    |   (15 units)    |    |   (15 units)    |
 +--------+--------+    +--------+--------+    +--------+--------+
          |                      |                      |
 +--------+--------+    +--------+--------+    +--------+--------+
 | * analyzer      |    | * gui-super     |    | * gui-layout    |
 | * coder         |    | * database      |    | * db-query      |
 | * reviewer      |    | * security      |    | * security-auth |
 | * documenter    |    | * mql           |    | * api-endpoint  |
 | * system_coord  |    | * trading       |    | * test-unit     |
 | * orchestrator  |    | * architect     |    | * mql-optim     |
 +-----------------+    | * integration   |    | * trading-risk  |
                        | * devops        |    | * mobile-ui     |
                        | * languages     |    | * n8n-workflow  |
                        | * ai_integr     |    | * claude-prompt |
                        | * claude_sys    |    +-----------------+
                        | * mobile        |
                        | * n8n           |
                        | * social_id     |
                        +-----------------+
```

## Installation

### Quick Install (Recommended)

1. **Backup your existing `.claude` directory** (if any):
```bash
# Windows
move %USERPROFILE%\.claude %USERPROFILE%\.claude.backup

# Linux/Mac
mv ~/.claude ~/.claude.backup
```

2. **Clone this repository**:
```bash
# Windows
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git %USERPROFILE%\.claude

# Linux/Mac
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git ~/.claude
```

3. **Set up configuration files**:
```bash
# Windows
cd %USERPROFILE%\.claude
copy settings.template.json settings.json
copy settings.local.template.json settings.local.json

# Linux/Mac
cd ~/.claude
cp settings.template.json settings.json
cp settings.local.template.json settings.local.json
```

4. **Install MCP Server dependencies** (optional, for advanced features):
```bash
cd plugins/orchestrator-plugin
npm install
npm run build
```

5. **Restart Claude Code** to apply changes.

### Manual Install (Merge with existing config)

If you have an existing `.claude` configuration, copy these folders:
- `agents/` - All agent definitions
- `commands/` - Orchestrator command
- `config/` - Routing and registry
- `plugins/orchestrator-plugin/` - MCP server

Then merge your `settings.json` with settings from `settings.template.json`.

## Usage

```bash
/orchestrator <your request>
```

**Examples:**
- `/orchestrator Create a GUI for database management`
- `/orchestrator Fix the auth module bug`
- `/orchestrator Optimize MetaTrader EA`
- `/orchestrator Design microservices architecture`

## Model Selection

| Model | When to Use | Task Tool Parameter |
|-------|-------------|---------------------|
| **Haiku** | Mechanical tasks, no reasoning | `model: "haiku"` |
| **Sonnet** | Problem solving, coding, debugging | Omit `model` parameter |
| **Opus** | Architecture, creative, complex | `model: "opus"` |

### Important: Sonnet Workaround

Due to a known bug in Claude Code Task tool ([GitHub #18873](https://github.com/anthropics/claude-code/issues/18873)), the `model: "sonnet"` parameter causes a 404 error.

**Workaround:** Omit the `model` parameter to use Sonnet (inherits from parent context).

```javascript
// WRONG - causes 404
Task({ model: "sonnet", ... })

// CORRECT - uses Sonnet via inheritance
Task({ ... })  // No model parameter
```

## Directory Structure

```
.claude/
|
+-- agents/
|   +-- core/                    # Level 0 - Core Agents (6)
|   |   +-- analyzer.md
|   |   +-- coder.md
|   |   +-- reviewer.md
|   |   +-- documenter.md
|   |   +-- system_coordinator.md
|   |   +-- orchestrator.md
|   |
|   +-- experts/                 # Level 1 - Expert Agents (15)
|   |   +-- gui-super-expert.md
|   |   +-- database_expert.md
|   |   +-- security_unified_expert.md
|   |   +-- ... (12 more)
|   |
|   +-- experts/L2/              # Level 2 - Sub-Agents (15)
|       +-- gui-layout-specialist.md
|       +-- db-query-optimizer.md
|       +-- ... (13 more)
|
+-- commands/
|   +-- orchestrator.md          # Main orchestrator command
|
+-- config/
|   +-- routing.md               # Agent routing tables
|   +-- standards.md             # Coding standards
|
+-- plugins/
    +-- orchestrator-plugin/     # MCP Server plugin
```

## 6-Level Fallback System

```
LEVEL 1: EXACT MATCH
-> Agent exists? USE IT
-> Not found? LEVEL 2

LEVEL 2: L2 -> L1 PARENT
-> L2 sub-agent not found? USE PARENT L1

LEVEL 3: DOMAIN PATTERN
-> Expert not found? PATTERN MATCH on domain

LEVEL 4: CORE AGENT
-> No expert match? USE APPROPRIATE CORE AGENT

LEVEL 5: UNIVERSAL CODER
-> Anything fails? core/coder.md handles it

LEVEL 6: ORCHESTRATOR DIRECT
-> Everything fails? ORCHESTRATOR executes directly

100% SUCCESS RATE GUARANTEED
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model ID for Sonnet alias |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model ID for Opus alias |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model ID for Haiku alias |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model for Task tool subagents |

### Recommended Settings

```json
{
  "env": {
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5-20250929",
    "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-4-5-20250929"
  }
}
```

## Changelog

### V6.0 ULTRA (February 4, 2026)
- **NEW:** Rigid hierarchy with Orchestrator as Supreme Commander
- **NEW:** 15 L2 specialized sub-agents
- **NEW:** 6-level guaranteed fallback system
- **NEW:** ASCII-compatible format for all terminals
- **NEW:** 36 total agents (6 core + 15 experts + 15 L2)
- **IMPROVED:** Intelligent model selection
- **IMPROVED:** Automatic escalation
- **FIX:** Sonnet model workaround documented
- **FIX:** Removed incompatible Unicode box-drawing characters

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

Created by [eroslifestyle](https://github.com/eroslifestyle)

---

**Remember:**
- Orchestrator commands, agents execute
- Absolute discipline, zero exceptions
- Documentation always, no bypass
- 36 agents ready to command
