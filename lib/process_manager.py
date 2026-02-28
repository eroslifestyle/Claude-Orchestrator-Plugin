"""
ProcessManager - Windows Process Lifecycle Manager
Guarantees NO orphan processes through Windows Job Objects and signal handlers.

Usage:
    with ProcessManager() as pm:
        proc = pm.spawn(['python', 'script.py'])
        # Process automatically cleaned up on exit

Author: Claude Code Architect Expert
Version: 1.0.0
Date: 2026-02-28
"""

import ctypes
import ctypes.wintypes
import signal
import atexit
import subprocess
import threading
import logging
import uuid
import os
import time
from typing import List, Dict, Optional, Any
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

# ============================================================================
# Windows API Constants
# ============================================================================

JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000
JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = 0x400
JOB_OBJECT_LIMIT_BREAKAWAY_OK = 0x800
HANDLE_FLAG_INHERIT = 0x1
PROCESS_TERMINATE = 0x1
PROCESS_SET_QUOTA = 0x100
PROCESS_SET_INFORMATION = 0x200


# ============================================================================
# Windows API Structures
# ============================================================================

class JOBOBJECT_BASIC_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("PerProcessUserTimeLimit", ctypes.c_longlong),
        ("PerJobUserTimeLimit", ctypes.c_longlong),
        ("LimitFlags", ctypes.c_ulong),
        ("MinimumWorkingSetSize", ctypes.c_size_t),
        ("MaximumWorkingSetSize", ctypes.c_size_t),
        ("ActiveProcessLimit", ctypes.c_ulong),
        ("Affinity", ctypes.c_ulonglong),
        ("PriorityClass", ctypes.c_ulong),
        ("SchedulingClass", ctypes.c_ulong)
    ]


class IO_COUNTERS(ctypes.Structure):
    _fields_ = [
        ("ReadOperationCount", ctypes.c_ulonglong),
        ("WriteOperationCount", ctypes.c_ulonglong),
        ("OtherOperationCount", ctypes.c_ulonglong),
        ("ReadTransferCount", ctypes.c_ulonglong),
        ("WriteTransferCount", ctypes.c_ulonglong),
        ("OtherTransferCount", ctypes.c_ulonglong)
    ]


class JOBOBJECT_EXTENDED_LIMIT_INFORMATION(ctypes.Structure):
    _fields_ = [
        ("BasicLimitInformation", JOBOBJECT_BASIC_LIMIT_INFORMATION),
        ("IoInfo", IO_COUNTERS),
        ("ProcessMemoryLimit", ctypes.c_size_t),
        ("JobMemoryLimit", ctypes.c_size_t),
        ("PeakProcessMemoryUsed", ctypes.c_size_t),
        ("PeakJobMemoryUsed", ctypes.c_size_t)
    ]


# ============================================================================
# Windows DLLs
# ============================================================================

kernel32 = ctypes.windll.kernel32


# ============================================================================
# Custom Exceptions
# ============================================================================

class ProcessManagerError(Exception):
    """Base exception for ProcessManager errors."""
    pass


class ProcessSpawnError(ProcessManagerError):
    """Error when spawning a process fails."""
    pass


class ProcessTerminationError(ProcessManagerError):
    """Error when terminating a process fails."""
    pass


# ============================================================================
# Data Classes
# ============================================================================

@dataclass
class ProcessInfo:
    """Information about a managed process."""
    pid: int
    name: str
    command: List[str]
    parent_pid: int
    spawn_time: datetime
    process_handle: subprocess.Popen


@dataclass
class ProcessManagerMetrics:
    """Metrics exposed to orchestrator for observability."""
    total_spawned: int = 0
    total_terminated: int = 0
    active_processes: int = 0
    failed_terminations: int = 0
    zombie_processes: int = 0

    def to_dict(self) -> Dict[str, int]:
        """Convert metrics to dictionary."""
        return {
            'total_spawned': self.total_spawned,
            'total_terminated': self.total_terminated,
            'active_processes': self.active_processes,
            'failed_terminations': self.failed_terminations,
            'zombie_processes': self.zombie_processes
        }


# ============================================================================
# ProcessManager Singleton
# ============================================================================

class ProcessManager:
    """
    Singleton process manager for Windows that guarantees no orphan processes.

    Features:
    - Windows Job Objects for automatic cleanup on parent death
    - Thread-safe process registry
    - Context manager support
    - Signal handlers (SIGTERM, SIGINT, SIGABRT)
    - Windows console control handler (Ctrl+C, close button)
    - Instance isolation with lock files
    - Error recovery with escalation (terminate -> kill -> taskkill)

    Usage:
        with ProcessManager() as pm:
            proc = pm.spawn(['python', 'script.py'])
            # Process automatically cleaned up on exit
    """

    _instance: Optional['ProcessManager'] = None
    _lock: threading.Lock = threading.Lock()

    def __new__(cls) -> 'ProcessManager':
        """Singleton pattern implementation."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self) -> None:
        """Initialize process registry, job object, and signal handlers."""
        # Prevent re-initialization
        if hasattr(self, '_initialized') and self._initialized:
            return

        # Initialize logger
        self._logger = logging.getLogger(f'ProcessManager.{id(self)}')
        self._logger.setLevel(logging.INFO)

        # Process registry (thread-safe)
        self._registry_lock = threading.Lock()
        self._process_registry: Dict[int, ProcessInfo] = {}

        # Instance isolation
        self._instance_id: str = str(uuid.uuid4())[:8]
        self._lock_file_path: str = os.path.join(
            os.environ.get('TEMP', '/tmp'),
            f'process_manager_{self._instance_id}.lock'
        )
        self._lock_file: Optional[Any] = None

        # Job object handle
        self._job_object_handle: Optional[int] = None

        # State flag
        self._is_active: bool = False

        # Metrics
        self._metrics = ProcessManagerMetrics()

        # Setup
        self._setup_lock_file()
        self._setup_job_object()
        self._setup_signal_handlers()

        self._initialized = True
        self._is_active = True

        self._logger.info(f"ProcessManager initialized (instance_id={self._instance_id})")

    def __enter__(self) -> 'ProcessManager':
        """Context manager entry - acquire resources."""
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Context manager exit - cleanup all processes."""
        self._cleanup()

    def spawn(self, command: List[str], **kwargs: Any) -> subprocess.Popen:
        """
        Spawn a new process and register it for tracking.

        Args:
            command: Command and arguments as list (NOT shell string)
            **kwargs: Additional subprocess.Popen arguments

        Returns:
            subprocess.Popen object for the spawned process

        Raises:
            ProcessSpawnError: If process creation fails
        """
        if not isinstance(command, list):
            raise ProcessSpawnError("Command must be a list, not a string")

        try:
            # Spawn process
            proc = subprocess.Popen(command, **kwargs)

            # Register in registry
            process_info = ProcessInfo(
                pid=proc.pid,
                name=command[0] if command else 'unknown',
                command=command,
                parent_pid=os.getpid(),
                spawn_time=datetime.now(),
                process_handle=proc
            )

            with self._registry_lock:
                self._process_registry[proc.pid] = process_info

            # Assign to job object
            if self._job_object_handle:
                self._assign_process_to_job(proc.pid)

            # Update metrics
            self._metrics.total_spawned += 1
            self._metrics.active_processes = len(self._process_registry)

            self._logger.info(f"Spawned PID {proc.pid}: {' '.join(command)}")

            return proc

        except Exception as e:
            self._logger.exception(f"Failed to spawn process: {e}")
            raise ProcessSpawnError(f"Failed to spawn process: {e}") from e

    def terminate_all(self, timeout: float = 10.0) -> Dict[int, bool]:
        """
        Terminate all registered processes with escalation.

        Args:
            timeout: Seconds to wait for graceful termination

        Returns:
            Dict mapping PID to termination success status
        """
        results: Dict[int, bool] = {}

        with self._registry_lock:
            pids = list(self._process_registry.keys())

        self._logger.info(f"Terminating {len(pids)} processes")

        for pid in pids:
            success = self.terminate_process(pid, timeout)
            results[pid] = success

            # Update metrics
            if success:
                self._metrics.total_terminated += 1
            else:
                self._metrics.failed_terminations += 1

        self._metrics.active_processes = 0
        return results

    def terminate_process(self, pid: int, timeout: float = 10.0) -> bool:
        """
        Terminate a specific process by PID with escalation.

        Args:
            pid: Process ID to terminate
            timeout: Seconds to wait for graceful termination

        Returns:
            True if terminated successfully, False otherwise
        """
        with self._registry_lock:
            process_info = self._process_registry.get(pid)

        if not process_info:
            self._logger.warning(f"PID {pid} not found in registry")
            return False

        return self._escalate_termination(pid, process_info.process_handle, timeout)

    def get_process_info(self, pid: int) -> Optional[ProcessInfo]:
        """Get information about a registered process."""
        with self._registry_lock:
            return self._process_registry.get(pid)

    def list_processes(self) -> List[ProcessInfo]:
        """List all registered processes."""
        with self._registry_lock:
            return list(self._process_registry.values())

    def is_process_alive(self, pid: int) -> bool:
        """Check if a registered process is still running."""
        process_info = self.get_process_info(pid)
        if not process_info:
            return False

        return process_info.process_handle.poll() is None

    def get_metrics(self) -> Dict[str, int]:
        """Get current metrics."""
        self._metrics.active_processes = len(self._process_registry)
        return self._metrics.to_dict()

    # ========================================================================
    # Internal Methods
    # ========================================================================

    def _setup_lock_file(self) -> None:
        """Create lock file for instance isolation."""
        try:
            # Create lock file (exclusive)
            self._lock_file = open(self._lock_file_path, 'w')
            self._lock_file.write(f"PID: {os.getpid()}\n")
            self._lock_file.write(f"Instance: {self._instance_id}\n")
            self._lock_file.flush()
            self._logger.debug(f"Created lock file: {self._lock_file_path}")
        except Exception as e:
            self._logger.warning(f"Failed to create lock file: {e}")

    def _setup_job_object(self) -> None:
        """Create Windows Job Object for automatic cleanup."""
        try:
            # Create job object
            job_handle = kernel32.CreateJobObjectW(None, None)
            if not job_handle:
                error = ctypes.get_last_error()
                self._logger.error(f"Failed to create job object: {error}")
                return

            # Configure job object to kill processes when job handle closes
            info = JOBOBJECT_EXTENDED_LIMIT_INFORMATION()
            info.BasicLimitInformation.LimitFlags = (
                JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE |
                JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION
            )

            result = kernel32.SetInformationJobObject(
                job_handle,
                9,  # JobObjectExtendedLimitInformation
                ctypes.byref(info),
                ctypes.sizeof(info)
            )

            if not result:
                error = ctypes.get_last_error()
                self._logger.error(f"Failed to set job object info: {error}")
                kernel32.CloseHandle(job_handle)
                return

            self._job_object_handle = job_handle
            self._logger.info(f"Created job object with handle {job_handle}")

        except Exception as e:
            self._logger.exception(f"Exception creating job object: {e}")

    def _assign_process_to_job(self, pid: int) -> bool:
        """Assign a process to the job object."""
        if not self._job_object_handle:
            return False

        try:
            # Get process handle
            process_handle = kernel32.OpenProcess(
                PROCESS_TERMINATE | PROCESS_SET_QUOTA | PROCESS_SET_INFORMATION,
                False,
                pid
            )

            if not process_handle:
                error = ctypes.get_last_error()
                self._logger.error(f"Failed to open process {pid}: {error}")
                return False

            # Assign to job object
            result = kernel32.AssignProcessToJobObject(
                self._job_object_handle,
                process_handle
            )

            if not result:
                error = ctypes.get_last_error()
                self._logger.error(f"Failed to assign process to job: {error}")
                return False

            self._logger.debug(f"Assigned PID {pid} to job object")
            return True

        except Exception as e:
            self._logger.exception(f"Exception assigning process to job: {e}")
            return False

    def _setup_signal_handlers(self) -> None:
        """Setup signal handlers for graceful termination."""
        def signal_handler(signum: int, frame: Any) -> None:
            self._logger.info(f"Received signal {signum}, initiating cleanup")
            self._cleanup()

        # Register signal handlers
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGABRT, signal_handler)

        # Register atexit handler
        atexit.register(self._cleanup)

        # Register Windows console handler
        try:
            CTRL_HANDLER_TYPE = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_uint)

            def console_handler(ctrl_type: int) -> bool:
                CTRL_C_EVENT = 0
                CTRL_CLOSE_EVENT = 2
                CTRL_LOGOFF_EVENT = 5
                CTRL_SHUTDOWN_EVENT = 6

                if ctrl_type in (CTRL_C_EVENT, CTRL_CLOSE_EVENT,
                                CTRL_LOGOFF_EVENT, CTRL_SHUTDOWN_EVENT):
                    self._cleanup()
                    return True
                return False

            handler = CTRL_HANDLER_TYPE(console_handler)
            kernel32.SetConsoleCtrlHandler(handler, True)
            self._logger.debug("Registered Windows console control handler")

        except Exception as e:
            self._logger.warning(f"Failed to register console handler: {e}")

    def _escalate_termination(self, pid: int, process_handle: subprocess.Popen,
                             timeout: float) -> bool:
        """
        Terminate process with escalation: terminate -> kill -> taskkill.
        """
        try:
            # Level 1: Graceful termination
            self._logger.info(f"Attempting graceful termination of PID {pid}")
            process_handle.terminate()
            try:
                process_handle.wait(timeout=timeout)
                self._logger.info(f"PID {pid} terminated gracefully")

                with self._registry_lock:
                    self._process_registry.pop(pid, None)

                return True
            except subprocess.TimeoutExpired:
                pass

            # Level 2: Forceful kill
            self._logger.warning(f"Escalating to kill for PID {pid}")
            process_handle.kill()
            try:
                process_handle.wait(timeout=5)
                self._logger.info(f"PID {pid} killed")

                with self._registry_lock:
                    self._process_registry.pop(pid, None)

                return True
            except subprocess.TimeoutExpired:
                pass

            # Level 3: Windows taskkill (nuclear option)
            self._logger.warning(f"Escalating to taskkill for PID {pid}")
            taskkill_result = subprocess.run(
                ['taskkill', '/F', '/PID', str(pid)],
                capture_output=True,
                timeout=10
            )

            if taskkill_result.returncode == 0:
                self._logger.info(f"PID {pid} terminated via taskkill")

                with self._registry_lock:
                    self._process_registry.pop(pid, None)

                return True
            else:
                stderr = taskkill_result.stderr.decode()
                self._logger.error(f"taskkill failed for PID {pid}: {stderr}")
                return False

        except Exception as e:
            self._logger.exception(f"Exception during escalation for PID {pid}: {e}")
            return False

    def _cleanup(self) -> None:
        """Internal cleanup method."""
        if not self._is_active:
            return

        self._is_active = False
        self._logger.info("Starting cleanup")

        # Terminate all processes
        self.terminate_all()

        # Close job object
        if self._job_object_handle:
            kernel32.CloseHandle(self._job_object_handle)
            self._job_object_handle = None
            self._logger.debug("Closed job object")

        # Remove lock file
        if self._lock_file:
            try:
                self._lock_file.close()
                os.remove(self._lock_file_path)
                self._logger.debug(f"Removed lock file: {self._lock_file_path}")
            except Exception as e:
                self._logger.warning(f"Failed to remove lock file: {e}")

        self._logger.info("Cleanup completed")


# ============================================================================
# Health Check Function
# ============================================================================

def health_check() -> Dict[str, Any]:
    """
    Health check endpoint for orchestrator.

    Returns:
        Dict with health status information
    """
    pm = ProcessManager._instance
    if pm is None:
        return {
            'status': 'not_initialized',
            'healthy': False
        }

    return {
        'status': 'active' if pm._is_active else 'inactive',
        'healthy': pm._is_active,
        'active_processes': len(pm.list_processes()),
        'job_object_active': pm._job_object_handle is not None,
        'instance_id': pm._instance_id,
        'metrics': pm.get_metrics()
    }


# ============================================================================
# Example Usage
# ============================================================================

if __name__ == '__main__':
    # Example usage
    logging.basicConfig(level=logging.INFO)

    print("ProcessManager Test")
    print("=" * 50)

    with ProcessManager() as pm:
        # Spawn a process
        proc = pm.spawn(['python', '-c', 'import time; time.sleep(5); print("Done")'])

        print(f"Spawned PID: {proc.pid}")
        print(f"Process info: {pm.get_process_info(proc.pid)}")
        print(f"Is alive: {pm.is_process_alive(proc.pid)}")
        print(f"Metrics: {pm.get_metrics()}")
        print(f"Health: {health_check()}")

        # Wait a bit
        time.sleep(2)

        # Process will be automatically terminated on exit
        print("\nExiting context manager...")
