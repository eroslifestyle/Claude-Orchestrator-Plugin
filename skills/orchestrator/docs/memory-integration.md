> Updated for V12.0 DEEP AUDIT: Memory now works alongside Rules Engine (Step 3) and Learning System (Step 9).

# Memory Integration Module V12.0

> **Orchestrator Extension** - Persistent context across sessions for multi-agent coordination

---

## Overview

The Memory Integration Module enables the Orchestrator V12.0 to maintain persistent context across sessions, automatically loading and updating project-specific and global memory. This ensures continuity in multi-step workflows and preserves critical information between Claude Code sessions.

### Key Capabilities

| Feature | Description |
|---------|-------------|
| **Auto-Load** | Automatically reads MEMORY.md at orchestrator startup |
| **Context Injection** | Injects memory context into subagent prompts |
| **Auto-Update** | Updates MEMORY.md after significant sessions |
| **Project Detection** | Auto-detects current project from working directory |
| **Memory Hierarchy** | Global + Project-level memory layers |
| **Cross-Session** | Full persistence across Claude Code sessions |

---

## Configuration

### Settings

Add to `~/.claude/settings.json`:

```json
{
  "memory": {
    "enabled": true,
    "autoLoad": true,
    "autoUpdate": true,
    "updateThreshold": 3,
    "maxMemorySize": 50000,
    "backupEnabled": true,
    "compressionThreshold": 30000
  }
}
```

### Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enabled` | bool | true | Enable/disable memory integration |
| `autoLoad` | bool | true | Auto-load memory at startup |
| `autoUpdate` | bool | true | Auto-update after sessions |
| `updateThreshold` | int | 3 | Min tasks before auto-update |
| `maxMemorySize` | int | 50000 | Max characters in memory file |
| `backupEnabled` | bool | true | Keep .bak of previous memory |
| `compressionThreshold` | int | 30000 | Compress if exceeds this size |

---

## Memory Locations

### Directory Structure

```
~/.claude/
├── settings.json                    # Global settings
├── CLAUDE.md                        # Global instructions
├── MEMORY.md                        # Global memory (legacy)
└── projects/
    └── {project-hash}/
        ├── CLAUDE.md                # Project instructions
        └── memory/
            ├── MEMORY.md            # Project memory (primary)
            ├── MEMORY.md.bak        # Backup (single file)
            ├── session-{id}.md      # Session log (optional)
            └── context.json         # Context metadata

```

### Path Resolution

| Memory Type | Location | Priority |
|-------------|----------|----------|
| Global Instructions | `~/.claude/CLAUDE.md` | 1 (lowest) |
| Global Memory | `~/.claude/MEMORY.md` | 2 |
| Project Instructions | `~/.claude/projects/{hash}/CLAUDE.md` | 3 |
| Project Memory | `~/.claude/projects/{hash}/memory/MEMORY.md` | 4 (highest) |

### Memory Hierarchy Visualization

```
+-----------------------------------------------------+
|                  MEMORY HIERARCHY                   |
+-----------------------------------------------------+
|                                                     |
|  Priority 4 (HIGHEST)                               |
|  +---------------------------------------------+   |
|  | ~/.claude/projects/{hash}/memory/MEMORY.md  |   |
|  | Project-specific memory (session context)   |   |
|  +---------------------------------------------+   |
|                      | overrides                    |
|  Priority 3                                         |
|  +---------------------------------------------+   |
|  | ~/.claude/projects/{hash}/CLAUDE.md         |   |
|  | Project instructions                         |   |
|  +---------------------------------------------+   |
|                      | overrides                    |
|  Priority 2                                         |
|  +---------------------------------------------+   |
|  | ~/.claude/MEMORY.md                          |   |
|  | Global memory (cross-project patterns)       |   |
|  +---------------------------------------------+   |
|                      | overrides                    |
|  Priority 1 (LOWEST)                                |
|  +---------------------------------------------+   |
|  | ~/.claude/CLAUDE.md                          |   |
|  | Global instructions (always loaded)          |   |
|  +---------------------------------------------+   |
|                                                     |
+-----------------------------------------------------+
```

### Project Hash Generation

```python
import hashlib

def get_project_hash(project_path: str) -> str:
    """Generate unique hash for project path."""
    normalized = project_path.lower().replace("\\", "/").rstrip("/")
    return hashlib.md5(normalized.encode()).hexdigest()[:12]
```

---

## Auto-Load Protocol

### Startup Sequence

```
ORCHESTRATOR STARTUP
        │
        ├── 1. Check memory.enabled
        │
        ├── 2. Detect PROJECT_PATH
        │      └── cwd or user-provided
        │
        ├── 3. Calculate project hash
        │
        ├── 4. Load memory hierarchy (parallel)
        │      ├── Global CLAUDE.md
        │      ├── Global MEMORY.md
        │      ├── Project CLAUDE.md
        │      └── Project MEMORY.md
        │
        ├── 5. Merge with priority (higher wins)
        │
        └── 6. Inject into orchestrator context
```

### Implementation

```python
from pathlib import Path
from typing import Optional
import hashlib

class MemoryLoader:
    """Handles automatic memory loading at orchestrator startup."""

    MEMORY_SIZE_LIMIT = 50000  # characters
    COMPRESSION_THRESHOLD = 30000

    def __init__(self, claude_dir: Path, project_path: Optional[Path] = None):
        self.claude_dir = claude_dir
        self.project_path = project_path
        self.project_hash = self._get_project_hash(project_path) if project_path else None

    def _get_project_hash(self, path: Path) -> str:
        """Generate unique hash for project path."""
        normalized = str(path).lower().replace("\\", "/").rstrip("/")
        return hashlib.md5(normalized.encode()).hexdigest()[:12]

    def _get_memory_paths(self) -> dict[str, Path]:
        """Get all memory file paths with priority."""
        paths = {
            "global_claude": self.claude_dir / "CLAUDE.md",
            "global_memory": self.claude_dir / "MEMORY.md",
        }

        if self.project_hash:
            project_dir = self.claude_dir / "projects" / self.project_hash
            paths.update({
                "project_claude": project_dir / "CLAUDE.md",
                "project_memory": project_dir / "memory" / "MEMORY.md",
            })

        return paths

    def load_all(self) -> dict[str, str]:
        """Load all memory files in parallel."""
        paths = self._get_memory_paths()
        memory = {}

        for name, path in paths.items():
            if path.exists():
                content = path.read_text(encoding="utf-8")
                if len(content) <= self.MEMORY_SIZE_LIMIT:
                    memory[name] = content

        return memory

    def merge_memory(self, memory: dict[str, str]) -> str:
        """Merge memory with priority (project > global)."""
        sections = []

        # Global instructions first
        if "global_claude" in memory:
            sections.append(f"## Global Instructions\n\n{memory['global_claude']}")

        # Global memory
        if "global_memory" in memory:
            sections.append(f"## Global Memory\n\n{memory['global_memory']}")

        # Project instructions
        if "project_claude" in memory:
            sections.append(f"## Project Instructions\n\n{memory['project_claude']}")

        # Project memory (highest priority, last)
        if "project_memory" in memory:
            sections.append(f"## Project Memory\n\n{memory['project_memory']}")

        return "\n\n---\n\n".join(sections)

    def get_context_for_injection(self) -> str:
        """Get merged memory ready for context injection."""
        memory = self.load_all()
        return self.merge_memory(memory)
```

---

## Context Injection

### Injection Points

| Injection Point | When | Target |
|-----------------|------|--------|
| Subagent Spawn | Before Task tool call | Subagent prompt |
| Teammate Spawn | Before team creation | Teammate context |
| Session Start | Orchestrator activation | Orchestrator context |

### Injection Format

```markdown
## Loaded Memory Context

### Project: {project_name}
### Session: {session_id}
### Loaded: {timestamp}

{merged_memory_content}

---
*Memory loaded by Memory Integration Module V12.0*
```

### Subagent Prompt Template

```markdown
EXECUTION RULES:
1. SHOW YOUR PLAN FIRST: Before doing any work, show a sub-task table...
2. PARALLELISM: Execute ALL independent operations in a SINGLE message...
3. UPDATE TABLE: After completing work, show the updated table with results.

## Memory Context (Auto-Loaded)

{memory_context}

## Task

{original_task}
```

### Implementation

```python
from datetime import datetime
from typing import Optional

class ContextInjector:
    """Injects memory context into subagent prompts."""

    def __init__(self, memory_loader: MemoryLoader):
        self.loader = memory_loader
        self._cached_context: Optional[str] = None

    def get_context_block(
        self,
        project_name: str = "Unknown",
        session_id: str = "N/A"
    ) -> str:
        """Generate formatted context block for injection."""
        if self._cached_context is None:
            memory_content = self.loader.get_context_for_injection()
            self._cached_context = memory_content

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        return f"""## Loaded Memory Context

### Project: {project_name}
### Session: {session_id}
### Loaded: {timestamp}

{self._cached_context}

---
*Memory loaded by Memory Integration Module V12.0*
"""

    def inject_into_prompt(
        self,
        original_prompt: str,
        project_name: str = "Unknown",
        session_id: str = "N/A"
    ) -> str:
        """Inject memory context into subagent prompt."""
        context_block = self.get_context_block(project_name, session_id)

        # Insert before task description
        if "## Task" in original_prompt:
            return original_prompt.replace(
                "## Task",
                f"{context_block}\n\n## Task"
            )
        else:
            return f"{context_block}\n\n{original_prompt}"

    def clear_cache(self) -> None:
        """Clear cached context (use after memory update)."""
        self._cached_context = None
```

---

## Auto-Update Protocol

### Update Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| Session End | Tasks >= threshold | Update MEMORY.md |
| Manual | User request | Force update |
| Significant Change | Architecture change | Update + backup |
| Size Exceeded | Memory > limit | Compress + update |

### Update Flow

```
SESSION END
     │
     ├── 1. Count completed tasks
     │
     ├── 2. Check threshold (default: 3)
     │
     ├── 3. Generate session summary
     │      ├── Key decisions
     │      ├── Files modified
     │      ├── Patterns established
     │      └── Issues encountered
     │
     ├── 4. Merge with existing memory
     │
     ├── 5. Check size limits
     │      └── Compress if needed
     │
     ├── 6. Create backup (.bak)
     │
     └── 7. Write updated MEMORY.md
```

### Implementation

```python
from datetime import datetime
from pathlib import Path
from typing import List, Optional
import shutil

class MemoryUpdater:
    """Handles automatic memory updates after sessions."""

    UPDATE_THRESHOLD = 3  # Minimum tasks before auto-update
    MAX_SIZE = 50000      # Maximum memory file size
    BACKUP_SUFFIX = ".bak"

    def __init__(self, memory_path: Path):
        self.memory_path = memory_path
        self.backup_path = memory_path.with_suffix(f".md{self.BACKUP_SUFFIX}")

    def should_update(self, task_count: int, has_significant_changes: bool) -> bool:
        """Determine if memory should be updated."""
        return task_count >= self.UPDATE_THRESHOLD or has_significant_changes

    def create_backup(self) -> bool:
        """Create single backup file (overwrites previous)."""
        if self.memory_path.exists():
            shutil.copy2(self.memory_path, self.backup_path)
            return True
        return False

    def generate_session_summary(
        self,
        task_summaries: List[str],
        files_modified: List[str],
        decisions: List[str],
        patterns: List[str],
        issues: List[str]
    ) -> str:
        """Generate session summary for memory."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")

        sections = [f"## Session Summary - {timestamp}\n"]

        if decisions:
            sections.append("### Key Decisions")
            for d in decisions:
                sections.append(f"- {d}")
            sections.append("")

        if files_modified:
            sections.append("### Files Modified")
            for f in files_modified:
                sections.append(f"- {f}")
            sections.append("")

        if patterns:
            sections.append("### Patterns Established")
            for p in patterns:
                sections.append(f"- {p}")
            sections.append("")

        if issues:
            sections.append("### Issues/Notes")
            for i in issues:
                sections.append(f"- {i}")
            sections.append("")

        return "\n".join(sections)

    def compress_memory(self, content: str) -> str:
        """Compress memory content if too large."""
        lines = content.split("\n")

        # Keep structure sections, compress details
        compressed = []
        in_detail_section = False

        for line in lines:
            # Markers for detailed sections to compress
            if line.startswith("## ") or line.startswith("### "):
                in_detail_section = "log" in line.lower() or "history" in line.lower()

            if not in_detail_section:
                compressed.append(line)

        return "\n".join(compressed)

    def update_memory(
        self,
        session_summary: str,
        force: bool = False
    ) -> bool:
        """Update memory file with new session summary."""
        try:
            # Create backup first
            self.create_backup()

            # Read existing memory
            existing = ""
            if self.memory_path.exists():
                existing = self.memory_path.read_text(encoding="utf-8")

            # Prepend new summary
            new_content = f"{session_summary}\n\n{existing}"

            # Compress if needed
            if len(new_content) > self.MAX_SIZE:
                new_content = self.compress_memory(new_content)

            # Write updated memory
            self.memory_path.parent.mkdir(parents=True, exist_ok=True)
            self.memory_path.write_text(new_content, encoding="utf-8")

            return True

        except Exception as e:
            print(f"Memory update failed: {e}")
            return False
```

---

## API Reference

### MemoryLoader

```python
class MemoryLoader:
    def __init__(self, claude_dir: Path, project_path: Optional[Path] = None):
        """Initialize memory loader with Claude directory and optional project path."""

    def load_all(self) -> dict[str, str]:
        """Load all memory files. Returns dict mapping names to content."""

    def merge_memory(self, memory: dict[str, str]) -> str:
        """Merge memory files with priority (project > global)."""

    def get_context_for_injection(self) -> str:
        """Get merged memory ready for context injection."""
```

### ContextInjector

```python
class ContextInjector:
    def __init__(self, memory_loader: MemoryLoader):
        """Initialize injector with memory loader."""

    def get_context_block(self, project_name: str, session_id: str) -> str:
        """Generate formatted context block for injection."""

    def inject_into_prompt(self, original_prompt: str, project_name: str, session_id: str) -> str:
        """Inject memory context into subagent prompt."""

    def clear_cache(self) -> None:
        """Clear cached context (use after memory update)."""
```

### MemoryUpdater

```python
class MemoryUpdater:
    def __init__(self, memory_path: Path):
        """Initialize updater with target memory file path."""

    def should_update(self, task_count: int, has_significant_changes: bool) -> bool:
        """Determine if memory should be updated."""

    def create_backup(self) -> bool:
        """Create single backup file (overwrites previous)."""

    def generate_session_summary(
        self,
        task_summaries: List[str],
        files_modified: List[str],
        decisions: List[str],
        patterns: List[str],
        issues: List[str]
    ) -> str:
        """Generate session summary for memory."""

    def update_memory(self, session_summary: str, force: bool = False) -> bool:
        """Update memory file with new session summary."""
```

---

## Examples

### Example 1: Basic Memory Loading

```python
from pathlib import Path

# Initialize
claude_dir = Path.home() / ".claude"
project_path = Path("E:/Dropbox/1_Forex/Programmazione/NexusArb")

loader = MemoryLoader(claude_dir, project_path)

# Load all memory
memory = loader.load_all()
print(f"Loaded {len(memory)} memory files")

# Get merged context
context = loader.get_context_for_injection()
print(f"Merged context: {len(context)} characters")
```

### Example 2: Context Injection for Subagent

```python
from pathlib import Path

# Setup
loader = MemoryLoader(Path.home() / ".claude", Path.cwd())
injector = ContextInjector(loader)

# Original subagent prompt
original_prompt = """EXECUTION RULES:
1. SHOW YOUR PLAN FIRST...
2. PARALLELISM...

## Task

Implement the authentication module."""

# Inject memory context
enhanced_prompt = injector.inject_into_prompt(
    original_prompt,
    project_name="NexusArb",
    session_id="d4b394a2-fe54-4109-8c41-ba9f6b984c81"
)

# Use enhanced_prompt in Task tool call
```

### Example 3: Session End Update

```python
from pathlib import Path

# Setup
memory_path = Path.home() / ".claude" / "projects" / "abc123def456" / "memory" / "MEMORY.md"
updater = MemoryUpdater(memory_path)

# Session data
task_count = 5
has_significant = True

# Check if update needed
if updater.should_update(task_count, has_significant):
    summary = updater.generate_session_summary(
        task_summaries=["T1: Auth module", "T2: DB schema"],
        files_modified=["src/auth.py", "src/models.py"],
        decisions=["Use JWT for auth", "PostgreSQL for DB"],
        patterns=["Repository pattern", "Dependency injection"],
        issues=["Need to add rate limiting"]
    )

    success = updater.update_memory(summary)
    print(f"Memory updated: {success}")
```

### Example 4: Orchestrator Integration

```python
# In orchestrator startup
class OrchestratorV10:
    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.claude_dir = Path.home() / ".claude"

        # Initialize memory system
        self.memory_loader = MemoryLoader(self.claude_dir, project_path)
        self.context_injector = ContextInjector(self.memory_loader)
        self.memory_updater = MemoryUpdater(
            self._get_project_memory_path()
        )

        # Auto-load at startup
        self._load_memory()

    def _get_project_memory_path(self) -> Path:
        """Get project-specific memory file path."""
        project_hash = hashlib.md5(
            str(self.project_path).lower().encode()
        ).hexdigest()[:12]
        return (
            self.claude_dir / "projects" / project_hash /
            "memory" / "MEMORY.md"
        )

    def _load_memory(self) -> None:
        """Load memory at orchestrator startup."""
        context = self.memory_loader.get_context_for_injection()
        print(f"Memory loaded: {len(context)} characters")

    def delegate_to_subagent(self, task: str, agent: str) -> None:
        """Delegate task to subagent with memory context."""
        enhanced_task = self.context_injector.inject_into_prompt(
            task,
            project_name=self.project_path.name,
            session_id=self.session_id
        )
        # Call Task tool with enhanced_task...

    def on_session_end(self, session_data: dict) -> None:
        """Handle session end with memory update."""
        if self.memory_updater.should_update(
            session_data["task_count"],
            session_data.get("significant", False)
        ):
            summary = self.memory_updater.generate_session_summary(
                task_summaries=session_data["tasks"],
                files_modified=session_data["files"],
                decisions=session_data.get("decisions", []),
                patterns=session_data.get("patterns", []),
                issues=session_data.get("issues", [])
            )
            self.memory_updater.update_memory(summary)
            self.context_injector.clear_cache()
```

---

## Best Practices

### Memory Content Guidelines

1. **Keep Concise**: Aim for < 50KB total memory size
2. **Prioritize Active Info**: Remove outdated/deprecated entries
3. **Structure Well**: Use consistent markdown formatting
4. **Version Important Decisions**: Log architectural decisions with rationale
5. **Cross-Reference**: Link to relevant files/docs when applicable

### Update Strategy

1. **Threshold-Based**: Only update after 3+ tasks (configurable)
2. **Backup Always**: Keep single .bak file for rollback
3. **Compress Proactively**: Auto-compress when approaching size limit
4. **Preserve Structure**: Maintain section hierarchy during compression

### Integration Points

1. **Startup**: Load memory before showing agent roster
2. **Task Delegation**: Inject context into every Task tool call
3. **Team Creation**: Include memory in teammate spawn prompts
4. **Session End**: Update memory before final report

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Memory not loading | Invalid path | Check project hash generation |
| Context too large | Memory > 50KB | Enable compression or reduce content |
| Update fails | Permission error | Check file permissions |
| Backup missing | First run | Normal - backup created on first update |
| Stale context | Cache not cleared | Call `clear_cache()` after updates |

---

## Changelog

### V12.0 - February 2026
- Deep audit complete, aligned with orchestrator V12.0 DEEP AUDIT

### V10.2 - February 2026
- Updated for Orchestrator V10.2 compatibility
- Enhanced memory compression algorithms
- Improved context injection performance

### V10.0 - February 2026
- Initial release for Orchestrator V10.0
- Auto-load protocol implementation
- Context injection system
- Auto-update with threshold
- Memory hierarchy (global + project)
- Cross-session persistence

---

*Memory Integration Module V12.0 - Orchestrator Extension*
*Compatible with Orchestrator V8.0+ and V12.0*
