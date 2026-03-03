# Claude Orchestrator Plugin V12.5.2

A powerful multi-agent orchestration system for Claude Code with hierarchical command structure, parallel execution, intelligent cleanup, and 100% guaranteed fallback.

```
+==============================================================================+
|                                                                              |
|     OOOO   RRRR    CCCC  H   H  EEEEE   SSSS  TTTTT  RRRR    AAAA           |
|    O    O  R   R  C      H   H  E      S        T    R   R  A    A          |
|    O    O  RRRR   C      HHHHH  EEEE    SSS     T    RRRR   AAAAAA          |
|    O    O  R  R   C      H   H  E          S    T    R  R   A    A          |
|     OOOO   R   R   CCCC  H   H  EEEEE  SSSS     T    R   R  A    A          |
|                                                                              |
|               V12.5.2 - CLEANUP ONLY AT END - CLEAN SESSION                  |
|                                                                              |
+==============================================================================+
```

## Features

- **43 Specialized Agents** - 6 Core + 22 Experts + 15 L2 Sub-agents
- **31 Skills** - Core, Utility, Workflow, Language, Learning categories
- **6-Level Fallback System** - 100% guaranteed task completion
- **Forced Global Parallelism** - Up to 64 concurrent agents
- **Intelligent Model Selection** - Haiku/Sonnet/Opus based on task complexity
- **Auto-Execute Mode** - No confirmation needed, immediate action
- **Request Pre-Processing** - Automatic complexity evaluation and expansion
- **Robust Cleanup System** - Startup + Session + Emergency cleanup
- **Process Manager** - Centralized process spawning with guaranteed cleanup
- **Rules Engine** - Context-aware rule injection per task

## What's New in V12.5.1

### TMP PATTERNS (March 3, 2026)
- **Extended temp patterns** for Claude Code files:
  - `*.*.tmp.*` - Any file with .tmp in middle
  - `*.md.tmp.*` - Markdown temp files
  - `CLAUDE.md.tmp.*` - Specific CLAUDE.md temps
  - `*.py.tmp.*` - Python temp files
- **Comprehensive cleanup** of orphan temp files

### V12.5 ROBUST CLEANUP (March 3, 2026)
- **STEP 0.6 STARTUP CLEANUP** - Removes stale temp files on session start
- **STEP 11.5 EMERGENCY CLEANUP** - Signal handlers for crash recovery
- **25+ temp patterns** - Covers generic, editor, OS, Python, Claude files
- **Windows Job Objects** - Guaranteed process tree cleanup

### V12.4 REQUEST PRE-PROCESSING (March 3, 2026)
- **NEW Skill**: `prompt-engineering-patterns` for request optimization
- **Complexity Evaluation** - Automatic detection of vague/complex requests
- **Task Type Identification** - BUG_FIX, FEATURE, REFACTOR, ANALYSIS, etc.
- **Vague Term Expansion** - "fix" -> "Identify root cause → Implement fix → Add tests → Verify"

### V12.3 SKILL INTEGRATION (March 3, 2026)
- **31 Skills** in catalog (was 26)
- **NEW**: `prompt-engineering-patterns`, `python-performance-optimization`
- **Skill Invocation** - Orchestrator can invoke skills directly
- **Slash Commands** - Integrated skill mapping

## Agent Hierarchy

```
                       +---------------------+
                       |    ORCHESTRATOR     |
                       |   V12.5.1           |
                       |  (SUPREME COMMAND)  |
                       +---------+-----------+
                                 |
          +----------------------+----------------------+
          |                      |                      |
 +--------v--------+    +--------v--------+    +--------v--------+
 |   CORE AGENTS   |    | EXPERT AGENTS   |    |  L2 SUB-AGENTS  |
 |     (6 units)   |    |   (22 units)    |    |   (15 units)    |
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
                        | * ... (13 more) |
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

## Skills Catalog (31 Total)

| Category | Skills |
|----------|--------|
| **Core (8)** | orchestrator, code-review, git-workflow, testing-strategy, debugging, api-design, remotion-best-practices, keybindings-help |
| **Utility (7)** | strategic-compact, verification-loop, checkpoint, sessions, status, metrics, prompt-engineering-patterns |
| **Workflow (9)** | plan, tdd-workflow, security-scan, refactor-clean, build-fix, multi-plan, fix, cleanup, simplify |
| **Language (4)** | python-patterns, python-performance-optimization, typescript-patterns, go-patterns |
| **Learning (2)** | learn, evolve |

## Directory Structure

```
.claude/
|
+-- agents/
|   +-- core/                    # Level 0 - Core Agents (6)
|   +-- experts/                 # Level 1 - Expert Agents (22)
|       +-- L2/                  # Level 2 - Sub-Agents (15)
|
+-- skills/                      # 31 Skills
|   +-- orchestrator/            # Main orchestrator skill
|   +-- prompt-engineering-patterns/  # NEW: Request pre-processing
|   +-- cleanup/                 # Enhanced cleanup skill
|   +-- ... (28 more)
|
+-- rules/                       # Context-aware rules engine
|   +-- common/                  # Universal rules
|   +-- python/                  # Python-specific
|   +-- typescript/              # TypeScript-specific
|   +-- go/                      # Go-specific
|
+-- lib/                         # Shared libraries
|   +-- process_manager.py       # Centralized process management
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

### V12.5.1 TMP PATTERNS (March 3, 2026)
- **NEW:** Extended temp patterns for Claude Code files
- **FIX:** Cleanup of orphan temp files (CLAUDE.md.tmp.*)
- **IMPROVED:** 25+ temp patterns in cleanup system

### V12.5 ROBUST CLEANUP (March 3, 2026)
- **NEW:** STEP 0.6 STARTUP CLEANUP
- **NEW:** STEP 11.5 EMERGENCY CLEANUP with signal handlers
- **NEW:** Process Manager for centralized process spawning
- **IMPROVED:** Windows Job Objects support

### V12.4 REQUEST PRE-PROCESSING (March 3, 2026)
- **NEW:** prompt-engineering-patterns skill
- **NEW:** STEP 0.5 complexity evaluation
- **NEW:** Task type identification (BUG_FIX, FEATURE, etc.)

### V12.3 SKILL INTEGRATION (March 3, 2026)
- **NEW:** 31 skills in catalog
- **NEW:** Skill invocation from orchestrator
- **NEW:** python-performance-optimization skill

### V12.2 PROCESS MANAGER (February 28, 2026)
- **NEW:** Centralized ProcessManager for Windows orphan prevention
- **NEW:** 100 process management rules

### V12.0 DEEP AUDIT (February 26, 2026)
- **NEW:** 100% coherence verification
- **NEW:** 43 agents verified
- **NEW:** Full documentation alignment

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Author

Created by [eroslifestyle](https://github.com/eroslifestyle)

---

**Remember:**
- Orchestrator commands, agents execute
- Clean startup. Clean session. Clean exit.
- 43 agents ready to command
- 31 skills ready to invoke
