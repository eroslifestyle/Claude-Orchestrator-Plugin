# Process Management Rules

> Mandatory for ALL code that spawns processes. Violations are blocking - code MUST NOT ship with orphaned processes.
> Enforces centralized ProcessManager usage across the orchestrator ecosystem.

---

## Centralized Process Spawning (Rules 1-10)

1. **NEVER use `subprocess.Popen`, `subprocess.run`, or `subprocess.call` directly** - always use ProcessManager
2. **NEVER use `os.system`, `os.spawn*`, or `os.exec*`** - always use ProcessManager
3. **NEVER use `multiprocessing.Process` directly** - always use ProcessManager wrapper
4. **NEVER use `asyncio.create_subprocess_*` directly** - always use ProcessManager async methods
5. All process creation MUST go through `ProcessManager.spawn()` or equivalent method
6. Direct subprocess usage bypasses cleanup guarantees - VIOLATION = code rejected
7. ProcessManager provides: tracking, cleanup, timeouts, and resource limits
8. No exceptions for "quick scripts" or "one-off commands" - use ProcessManager always
9. Legacy code MUST be migrated to ProcessManager before any other changes
10. If ProcessManager is unavailable, fail explicitly - do NOT fall back to subprocess

```python
# WRONG - Direct subprocess (NEVER DO THIS)
process = subprocess.Popen(["python", "script.py"])

# CORRECT - Use ProcessManager
with process_manager.spawn(["python", "script.py"]) as process:
    process.wait()
```

## Context Manager Pattern (Rules 11-16)

11. **ALWAYS use context manager pattern** for process lifecycle (`with` statement)
12. Context managers guarantee cleanup even on exceptions
13. Never hold process references outside context manager scope
14. Nested context managers for dependent processes - innermost exits first
15. Context manager MUST implement `__enter__` and `__exit__` with proper cleanup
16. `__exit__` MUST terminate process if still running - no orphans allowed

```python
# CORRECT - Context manager ensures cleanup
with ProcessManager.instance().spawn(command) as proc:
    result = proc.communicate(timeout=30)
# Process guaranteed terminated here, even if exception occurred

# WRONG - Manual lifecycle (NEVER DO THIS)
proc = ProcessManager.instance().spawn(command)
proc.start()
# If exception here, process leaks!
proc.wait()
```

## Cleanup Handler Registration (Rules 17-22)

17. **ALWAYS register cleanup handlers** via `atexit` and signal handlers
18. Register handlers at ProcessManager initialization, not per-process
19. Handle SIGTERM, SIGINT, and SIGHUP for graceful shutdown
20. Cleanup handlers MUST iterate all tracked processes and terminate them
21. Cleanup timeout: 5 seconds for graceful, then force kill
22. Log cleanup actions for debugging orphaned process issues

```python
# CORRECT - Proper handler registration
import atexit
import signal

def setup_cleanup_handlers(process_manager):
    atexit.register(process_manager.cleanup_all)

    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda s, f: process_manager.cleanup_all())
```

## Windows Job Objects (Rules 23-28)

23. **Windows: MUST use Job Objects** for guaranteed process tree cleanup
24. Job Objects kill entire process tree including child processes
25. Assign each spawned process to a Job Object with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`
26. Job Objects work even if parent process crashes
27. Test Job Object cleanup with forced parent termination
28. Document Windows-specific cleanup in cross-platform code

```python
# Windows Job Object pattern (simplified)
import ctypes
from ctypes import wintypes

kernel32 = ctypes.windll.kernel32

JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000

def create_job_object():
    job = kernel32.CreateJobObjectW(None, None)
    info = JOBOBJECT_BASIC_LIMIT_INFORMATION()
    info.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
    kernel32.SetInformationJobObject(job, 2, ctypes.byref(info), ctypes.sizeof(info))
    return job

def spawn_in_job(job, command):
    proc = subprocess.Popen(command)
    kernel32.AssignProcessToJobObject(job, int(proc._handle))
    return proc
```

## Thread Safety (Rules 29-34)

29. **Process registry MUST be thread-safe** - use locks for all mutations
30. Use `threading.RLock` for re-entrant locking in nested calls
31. Read operations MAY use lock-free patterns if data structure supports it
32. Process spawn, terminate, and cleanup MUST acquire lock
33. Avoid deadlocks: never hold process lock while waiting on process I/O
34. Document thread-safety guarantees in ProcessManager docstring

```python
# CORRECT - Thread-safe process registry
import threading

class ProcessManager:
    def __init__(self):
        self._lock = threading.RLock()
        self._processes = {}

    def spawn(self, command):
        with self._lock:
            proc = subprocess.Popen(command)
            self._processes[proc.pid] = proc
            return proc

    def terminate(self, pid):
        with self._lock:
            proc = self._processes.pop(pid, None)
            if proc:
                proc.terminate()
```

## Metrics and Logging (Rules 35-40)

35. **Log all process lifecycle events**: spawn, terminate, kill, timeout, cleanup
36. Include in logs: PID, command, timestamp, duration, exit code, parent context
37. Track metrics: active count, total spawned, cleanup successes/failures
38. Alert on anomalies: >50 active processes, cleanup failures, zombie detection
39. Use structured logging (JSON) for process events - easier to parse
40. Log cleanup attempts even if process already terminated

```python
# CORRECT - Comprehensive logging
import logging
import time

logger = logging.getLogger(__name__)

def spawn_with_logging(command, context):
    logger.info({
        "event": "process_spawn",
        "command": command,
        "context": context,
        "timestamp": time.time()
    })
    proc = ProcessManager.instance().spawn(command)
    logger.info({
        "event": "process_spawned",
        "pid": proc.pid,
        "command": command
    })
    return proc
```

## Error Handling Escalation (Rules 41-46)

41. **Use escalation sequence**: terminate -> wait(3s) -> kill -> wait(2s) -> taskkill (Windows)
42. Never skip steps in escalation - graceful first, then force
43. Log each escalation step with reason and timestamp
44. On Windows, use `taskkill /F /T /PID <pid>` for stubborn processes
45. On Unix, use `kill -9` only after `kill -15` fails
46. Report unkillable processes as CRITICAL errors - may indicate system issue

```python
# CORRECT - Escalation sequence
def force_terminate(proc, timeout_graceful=3, timeout_force=2):
    # Step 1: Graceful terminate
    proc.terminate()
    try:
        proc.wait(timeout=timeout_graceful)
        return True
    except subprocess.TimeoutExpired:
        pass

    # Step 2: Force kill
    proc.kill()
    try:
        proc.wait(timeout=timeout_force)
        return True
    except subprocess.TimeoutExpired:
        pass

    # Step 3: Platform-specific last resort
    if sys.platform == "win32":
        os.system(f"taskkill /F /T /PID {proc.pid}")
    else:
        os.kill(proc.pid, signal.SIGKILL)

    return False
```

## Instance Isolation (Rules 47-50)

47. **Use singleton pattern** for ProcessManager - one instance per process
48. Different orchestrator instances MUST use different ProcessManager instances
49. Include instance ID in process metadata for debugging conflicts
50. Never share ProcessManager instances across unrelated components

```python
# CORRECT - Singleton with instance ID
import uuid

class ProcessManager:
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._instance_id = str(uuid.uuid4())[:8]
                    cls._instance._processes = {}
        return cls._instance

    @property
    def instance_id(self):
        return self._instance_id
```

## Testing Requirements (Rules 51-58)

51. **Test cleanup on normal exit** - verify all processes terminated
52. **Test cleanup on exception** - simulate failure, verify cleanup
53. **Test cleanup on SIGTERM** - send signal, verify graceful shutdown
54. **Test cleanup on SIGKILL** - simulate crash, verify Job Object cleanup (Windows)
55. **Test concurrent spawns** - verify thread safety under load
56. **Test timeout handling** - spawn long-running process, verify termination
57. **Test orphan detection** - verify metrics alert on leaked processes
58. Include process tests in CI pipeline - cleanup bugs are critical

```python
# CORRECT - Comprehensive test pattern
import pytest
import subprocess
import time

def test_cleanup_on_exception():
    """Verify processes cleaned up even when exception occurs."""
    pm = ProcessManager.instance()

    try:
        with pm.spawn(["python", "-c", "import time; time.sleep(60)"]) as proc:
            pid = proc.pid
            raise RuntimeError("Simulated failure")
    except RuntimeError:
        pass

    # Verify process terminated
    assert pid not in pm.active_pids()
    with pytest.raises(OSError):
        os.kill(pid, 0)  # Process should not exist
```

## Resource Limits (Rules 59-64)

59. **Set maximum active processes** - default 100, configurable per deployment
60. **Reject spawn requests** when limit reached - fail fast, don't queue
61. **Set per-process timeouts** - default 5 minutes, override per-call
62. **Set per-process memory limits** - use cgroups (Linux) or Job Objects (Windows)
63. **Set per-process CPU limits** - prevent runaway CPU consumption
64. Log resource limit violations for capacity planning

## Process Tree Handling (Rules 65-70)

65. **Track process trees** - not just parent, but all descendants
66. **Use process groups** on Unix for tree-wide termination (`os.setpgid`)
67. **Use Job Objects** on Windows for tree-wide termination
68. **Log process tree** before and after spawn for debugging
69. **Handle disowned processes** - children that detach from parent
70. Test with processes that spawn their own children

```python
# CORRECT - Process group for tree termination
import os
import signal

def spawn_with_process_group(command):
    """Spawn process in new process group for clean tree termination."""
    proc = subprocess.Popen(
        command,
        start_new_session=True,  # Creates new process group
        preexec_fn=os.setsid if os.name != 'nt' else None
    )
    return proc

def terminate_process_group(pgid):
    """Terminate entire process group."""
    os.killpg(pgid, signal.SIGTERM)
```

## Timeout Enforcement (Rules 71-76)

71. **Always set timeouts** - no process runs forever
72. Default timeout: 300 seconds (5 minutes)
73. Override timeout per-call for long-running operations
74. Timeout triggers escalation sequence (terminate -> kill -> taskkill)
75. Log timeout events with process details for debugging
76. Track timeout frequency in metrics - high rate indicates problems

```python
# CORRECT - Timeout enforcement
def spawn_with_timeout(command, timeout=300):
    """Spawn process with enforced timeout."""
    pm = ProcessManager.instance()

    with pm.spawn(command, timeout=timeout) as proc:
        try:
            return proc.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            logger.warning(f"Process {proc.pid} timed out after {timeout}s")
            raise
```

## Health Monitoring (Rules 77-82)

77. **Implement health check** method on ProcessManager
78. Health check verifies: cleanup handlers registered, process limits OK, no zombies
79. **Detect zombie processes** - completed but not reaped
80. **Detect orphan processes** - running without parent tracking
81. Log health check results periodically (every 60 seconds)
82. Expose health status for orchestration/monitoring systems

## Configuration (Rules 83-88)

83. **Make all limits configurable** - max processes, timeouts, cleanup intervals
84. Use environment variables for deployment-specific settings
85. Provide sensible defaults - works out of box, tunable for scale
86. Validate configuration at startup - fail fast on invalid settings
87. Document all configuration options with examples
88. Log effective configuration at startup for debugging

```python
# CORRECT - Configurable settings
import os

class ProcessManagerConfig:
    MAX_PROCESSES = int(os.getenv("PM_MAX_PROCESSES", "100"))
    DEFAULT_TIMEOUT = int(os.getenv("PM_DEFAULT_TIMEOUT", "300"))
    CLEANUP_INTERVAL = int(os.getenv("PM_CLEANUP_INTERVAL", "60"))
    GRACEFUL_TIMEOUT = int(os.getenv("PM_GRACEFUL_TIMEOUT", "5"))

    @classmethod
    def validate(cls):
        if cls.MAX_PROCESSES < 1:
            raise ValueError("MAX_PROCESSES must be >= 1")
        if cls.DEFAULT_TIMEOUT < 1:
            raise ValueError("DEFAULT_TIMEOUT must be >= 1")
```

## Integration Requirements (Rules 89-94)

89. **Import ProcessManager** from centralized location - no local copies
90. **Initialize ProcessManager** at application startup, before any process spawning
91. **Call cleanup** at application shutdown, after all work complete
92. Handle ProcessManager initialization failure as fatal error
93. Document ProcessManager integration in component README
94. Version-check ProcessManager API - fail on incompatible versions

## Error Reporting (Rules 95-100)

95. **Report all cleanup failures** as CRITICAL - orphaned processes are bugs
96. Include process details in error reports: PID, command, spawn time, parent
97. Differentiate: spawn failures vs cleanup failures vs timeout failures
98. Aggregate error metrics for trend analysis
99. Alert on repeated cleanup failures - indicates systemic issue
100. Never silently ignore cleanup failures - always log at minimum

```python
# CORRECT - Error reporting
def report_cleanup_failure(proc, error):
    """Report cleanup failure with full context."""
    error_report = {
        "level": "CRITICAL",
        "event": "process_cleanup_failure",
        "pid": proc.pid,
        "command": proc.args,
        "spawn_time": proc._spawn_time,
        "error": str(error),
        "instance_id": ProcessManager.instance().instance_id
    }
    logger.critical(error_report)
    # Also send to monitoring/alerting system
    alerting.report(error_report)
```
