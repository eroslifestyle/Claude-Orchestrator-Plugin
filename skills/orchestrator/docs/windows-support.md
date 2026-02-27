# Windows Support Module V12.0

> **Orchestrator Extension** - Platform-specific configuration and commands for Windows

---

## Platform Configuration

| Setting | Windows | Unix/macOS |
|---------|---------|------------|
| Teammate mode | `in-process` (default) | `tmux` or `in-process` |
| Shell | PowerShell 7.x / 5.1 / Git Bash | bash/zsh |
| Path separator | `\` | `/` |
| NUL device | Special handling required | `/dev/null` |
| Process kill | `taskkill /F /IM` | `kill -9` |

---

## Agent Teams on Windows

- Agent Teams use `in-process` mode (no tmux/iTerm2)
- Use Shift+Up/Down to select teammates
- Press Enter to view teammate session, Escape to interrupt
- Press Ctrl+T to toggle task list
- Storage: `~/.claude/teams/` and `~/.claude/tasks/`

**Limitation:** `/resume` does NOT restore in-process teammates after session restart. Spawn new teammates after resuming.

---

## NUL File Deletion

Windows `NUL` is a reserved device name. Standard deletion commands fail.

### Method 1: Win32 API (Preferred)
```bash
python -c "import ctypes; ctypes.windll.kernel32.DeleteFileW(r'\\?\FULL_PATH\NUL')"
```

### Method 2: Git Bash Relative Path (Fallback)
```bash
cd <directory> && rm -f ./NUL
```

### Recursive Cleanup Script
```bash
python -c "
import os, ctypes
for root, dirs, files in os.walk('PROJECT_PATH'):
    if 'NUL' in files:
        p = os.path.join(root, 'NUL')
        ctypes.windll.kernel32.DeleteFileW(r'\\\\?\\\\' + p)
"
```

Try Method 1 first. If it returns PATH_NOT_FOUND (error 3), use Method 2.

---

## Common Windows Commands

### Process Management
```powershell
# Kill orphaned processes
taskkill /F /IM python.exe 2>NUL

# Check process tree
Get-Process | Where-Object {$_.Name -like "*python*"}
```

### Environment Variables
```powershell
# Set Agent Teams flag (session)
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"

# Set permanently (user)
[System.Environment]::SetEnvironmentVariable(
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS", "1", "User"
)
```

### Settings Configuration
Teammate mode is controlled via CLI flag, not settings.json:
```bash
claude --teammate-mode in-process   # default on Windows
claude --teammate-mode auto         # auto-detect (default overall)
```

Agent Teams enabled via settings.json:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## Known Windows Issues

| Issue | Workaround |
|-------|-----------|
| PowerShell `$_` escaping fails via Bash tool | Use .ps1 script files instead |
| Split panes not supported in VS Code/Windows Terminal/Ghostty | Use in-process mode |
| `NUL` files created by redirects | Use Win32 API deletion |
| Long path names (>260 chars) | Enable long paths in Windows registry |

---

*Windows Support Module V12.0 DEEP AUDIT - Orchestrator Extension*
