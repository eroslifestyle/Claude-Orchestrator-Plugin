# Claude Code Library (lib/)

Centralized utilities for the Claude Code orchestrator system.

## ProcessManager (process_manager.py)

### Purpose
Windows Process Lifecycle Manager that guarantees NO orphan processes through Windows Job Objects and signal handlers.

### Key Features
- Windows Job Objects with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` flag
- Signal handlers for graceful shutdown (SIGINT, SIGTERM)
- Atexit handlers for cleanup on normal exit
- Thread-safe process tracking with unique IDs
- Comprehensive logging and metrics

### Usage
```python
from lib.process_manager import ProcessManager

with ProcessManager() as pm:
    proc = pm.spawn(['python', 'script.py'])
    # Process automatically cleaned up on exit
```

### API Surface

#### ProcessManager Class
- `__enter__() / __exit__()`: Context manager for automatic cleanup
- `spawn(cmd: List[str], **kwargs) -> subprocess.Popen`: Spawn a managed process
- `kill_all() -> int`: Terminate all tracked processes
- `get_active_count() -> int`: Get count of active processes
- `get_metrics() -> Dict`: Get process metrics

### Files
- `process_manager.py` - Main ProcessManager implementation
- `tests/test_process_manager.py` - Test suite (45 tests)

### Dependencies
- Python 3.10+
- Windows API (ctypes) for Job Objects
- Standard library only (no external dependencies)

### Platform Support
- **Windows**: Full support with Job Objects
- **Unix/Linux**: Signal handlers only (no Job Object equivalent)

### Author
Claude Code Architect Expert
Version: 1.0.0
Date: 2026-02-28
