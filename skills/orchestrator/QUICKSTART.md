# Claude Orchestrator Plugin - Quick Start Guide

Get up and running with the Orchestrator Plugin in under 2 minutes.

---

## Installation Methods

### Method A: One-Liner (Windows)

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.ps1 | iex
```

**What it does:**
- Creates backup of existing `~/.claude` if needed
- Downloads and extracts the plugin to `~/.claude/skills/orchestrator`
- Copies agent definitions to `~/.claude/agents/`
- Optionally configures settings.json for Agent Teams

---

### Method B: One-Liner (macOS / Linux)

Open terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.sh | bash
```

**What it does:**
- Creates backup of existing `~/.claude` if needed
- Downloads and extracts the plugin to `~/.claude/skills/orchestrator`
- Copies agent definitions to `~/.claude/agents/`
- Optionally configures settings.json for Agent Teams

---

### Method C: Manual Clone

**Step 1:** Clone the repository

```bash
# Option 1: Clone directly (replaces entire .claude)
cd ~ && git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git .claude

# Option 2: Clone to temp and copy
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git /tmp/orchestrator
cp -r /tmp/orchestrator ~/.claude/skills/orchestrator
```

**Step 2:** Configure settings (optional but recommended)

Create or edit `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Step 3:** Restart Claude Code

---

## Verify Installation

1. Start Claude Code
2. Type `/orchestrator` or just start working
3. You should see the orchestrator activate and manage your tasks

### Check File Structure

**Linux/macOS:**
```bash
ls -la ~/.claude/skills/orchestrator/
```

**Windows PowerShell:**
```powershell
Get-ChildItem "$env:USERPROFILE\.claude\skills\orchestrator\"
```

Expected output:
```
SKILL.md           # Main skill definition
README.md          # Documentation
CHANGELOG.md       # Version history
agents/            # Agent definitions
docs/              # Additional documentation
VERSION.json       # Version info
```

### Check Agent Teams Setting

```bash
cat ~/.claude/settings.json
```

Should contain:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## First Use

### Basic Usage

Just type your request naturally. The orchestrator will:

1. **Analyze** your request
2. **Route** to specialized agents
3. **Execute** tasks in parallel when possible
4. **Report** consolidated results

### Example Commands

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

---

## Available Agents

| Category | Agents |
|----------|--------|
| **Development** | Coder, Languages Expert, GUI Super Expert, Mobile Expert |
| **Architecture** | Architect Expert, Database Expert, Integration Expert |
| **Quality** | Reviewer, Tester Expert, Security Expert |
| **Operations** | DevOps Expert, Analyzer, Documenter |
| **Trading** | MQL Expert, Trading Strategy Expert |
| **AI** | AI Integration Expert, Claude Systems Expert |
| **Automation** | N8N Expert, Notification Expert |

Total: **40+ specialized agents**

---

## Enable Agent Teams (Optional)

Agent Teams allow multiple agents to work in parallel on complex tasks.

### Prerequisites

1. Verify setting in `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
     }
   }
   ```

2. Restart Claude Code after changing settings

### When to Use Agent Teams

- 4+ parallel tasks on different files
- Complex multi-layer changes (frontend + backend + tests)
- Competing hypotheses investigation
- Multi-perspective code review

### Teammate Modes

| Mode | Platform | Description |
|------|----------|-------------|
| `in-process` | Windows (default) | No tmux required |
| `tmux` | macOS/Linux | Split panes |
| `auto` | All | Auto-detect |

---

## Common Issues

### "Skill not found"

- Verify installation path: `~/.claude/skills/orchestrator/SKILL.md`
- Restart Claude Code

### "Agent Teams not working"

- Check `settings.json` has the `env` block
- Restart Claude Code after editing settings

### "Permission denied"

- Ensure write permissions to `~/.claude/`
- Run installer with appropriate privileges

### "Git clone fails"

- Install git: `winget install Git.Git` (Windows) or `brew install git` (macOS)
- Check network connectivity

---

## Next Steps

1. Read the [README.md](README.md) for detailed documentation
2. Check [CHANGELOG.md](CHANGELOG.md) for latest updates
3. Explore `agents/` directory for agent definitions
4. Join discussions on GitHub Issues

---

## Quick Reference

| Command | Action |
|---------|--------|
| `/orchestrator` | Activate orchestrator explicitly |
| `/orchestrator metrics` | Show session metrics |
| `/orchestrator health` | Run health check |
| `--teammate-mode in-process` | Force in-process mode (Windows) |
| `--teammate-mode tmux` | Force tmux mode (macOS/Linux) |

---

## Support

- **GitHub Issues:** https://github.com/eroslifestyle/Claude-Orchestrator-Plugin/issues
- **Documentation:** See `docs/` folder
- **Version:** Check `VERSION.json`

---

*Orchestrator Plugin v10.2 - Making Claude Code a team of experts*
