# Installation Guide

## Prerequisites

- Claude Code CLI installed
- Node.js 18+ (for MCP server)
- Git

## Step-by-Step Installation

### Step 1: Backup Existing Configuration

```bash
# Windows PowerShell
if (Test-Path "$env:USERPROFILE\.claude") {
    Move-Item "$env:USERPROFILE\.claude" "$env:USERPROFILE\.claude.backup"
}

# Windows CMD
if exist "%USERPROFILE%\.claude" move "%USERPROFILE%\.claude" "%USERPROFILE%\.claude.backup"

# Linux/Mac
[ -d ~/.claude ] && mv ~/.claude ~/.claude.backup
```

### Step 2: Clone Repository

```bash
# Windows
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git %USERPROFILE%\.claude

# Linux/Mac
git clone https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git ~/.claude
```

### Step 3: Configure Settings

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

### Step 4: Install MCP Server (Optional)

The MCP server provides advanced orchestration features.

```bash
cd plugins/orchestrator-plugin
npm install
npm run build
```

### Step 5: Verify Installation

Start Claude Code and test:

```bash
claude
```

Then run:
```
/orchestrator analyze project structure
```

## Configuration

### settings.json

The main configuration file. Key settings:

```json
{
  "env": {
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5-20250929",
    "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-4-5-20250929"
  },
  "permissions": {
    "allow": [
      "Bash(*)",
      "Task(*)",
      "mcp__orchestrator__*"
    ]
  }
}
```

### settings.local.json

Local settings for MCP servers:

```json
{
  "enableAllProjectMcpServers": true,
  "enabledMcpjsonServers": ["orchestrator"]
}
```

## Troubleshooting

### Error: "model: claude-3-5-sonnet-20241022" (404)

This is a known bug. The workaround is already applied in this plugin:
- When using Task tool, omit the `model` parameter for Sonnet
- Use `model: "haiku"` for simple tasks
- Use `model: "opus"` for complex tasks

### Error: Agent not found

Check that the agent file exists in `agents/` directory. The fallback system should handle missing agents automatically.

### MCP Server not connecting

1. Ensure Node.js is installed
2. Run `npm install` in `plugins/orchestrator-plugin/`
3. Check `settings.local.json` has the orchestrator enabled

### Permission denied errors

Add required permissions to `settings.json`:
```json
{
  "permissions": {
    "allow": ["Bash(*)", "Task(*)", "Edit", "Write", "Read"]
  }
}
```

## Updating

To update to the latest version:

```bash
cd ~/.claude  # or %USERPROFILE%\.claude on Windows
git pull origin main
```

## Uninstalling

```bash
# Windows
rmdir /s %USERPROFILE%\.claude

# Linux/Mac
rm -rf ~/.claude
```

To restore backup:
```bash
# Windows
move %USERPROFILE%\.claude.backup %USERPROFILE%\.claude

# Linux/Mac
mv ~/.claude.backup ~/.claude
```
