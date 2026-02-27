#!/usr/bin/env python3
"""
Claude Orchestrator Plugin Setup Script
Handles post-installation configuration and verification.

Cross-platform support: Windows, Linux, macOS

Usage:
    python setup.py --verify
    python setup.py --configure-mcp --install-path /path/to/install
    python setup.py --backup
    python setup.py --restore /path/to/backup
"""

import argparse
import json
import logging
import os
import platform
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional

# Configure logging
LOG_DIR = Path(__file__).parent / "logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / f"setup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


class Platform(Enum):
    """Supported platforms."""
    WINDOWS = "win32"
    LINUX = "linux"
    DARWIN = "darwin"


class SetupError(Exception):
    """Custom exception for setup errors."""
    def __init__(self, message: str, recoverable: bool = True):
        self.message = message
        self.recoverable = recoverable
        super().__init__(self.message)


@dataclass
class InstallInfo:
    """Installation information container."""
    version: str = "1.0.0"
    install_path: Path = field(default_factory=lambda: Path(__file__).parent)
    python_version: str = field(default_factory=lambda: platform.python_version())
    platform: str = field(default_factory=lambda: platform.system())
    claude_cli_path: Optional[str] = None
    mcp_configured: bool = False
    status: str = "unknown"
    files_verified: bool = False
    last_verified: Optional[str] = None


class ClaudeOrchestratorSetup:
    """
    Main setup class for Claude Orchestrator Plugin.
    Handles cross-platform installation, configuration, and verification.
    """

    # Required files for a complete installation
    REQUIRED_FILES = [
        "setup.py",
        "requirements.txt",
        "README.md",
        "src/orchestrator/__init__.py",
        "src/orchestrator/server.py",
        "src/orchestrator/config.py",
    ]

    # Python version requirements
    MIN_PYTHON_VERSION = (3, 10)

    def __init__(self, install_path: Optional[Path] = None):
        self.install_path = install_path or Path(__file__).parent
        self.platform = self._detect_platform()
        self.info = InstallInfo(install_path=self.install_path)
        self._backup_dir = self.install_path / "backups"
        self._config_dir = self.install_path / "config"

    def _detect_platform(self) -> Platform:
        """Detect current platform."""
        system = platform.system().lower()
        if system == "windows" or sys.platform == "win32":
            return Platform.WINDOWS
        elif system == "linux" or sys.platform.startswith("linux"):
            return Platform.LINUX
        elif system == "darwin" or sys.platform == "darwin":
            return Platform.DARWIN
        else:
            logger.warning(f"Unknown platform: {system}, defaulting to Linux")
            return Platform.LINUX

    def check_prerequisites(self) -> dict[str, bool]:
        """
        Verify all prerequisites are met.

        Returns:
            Dictionary with prerequisite check results.
        """
        logger.info("Checking prerequisites...")
        results = {}

        # Python version check
        current_version = sys.version_info[:2]
        python_ok = current_version >= self.MIN_PYTHON_VERSION
        results["python_version"] = python_ok
        if python_ok:
            logger.info(f"Python version OK: {platform.python_version()}")
        else:
            logger.error(
                f"Python version too old: {platform.python_version()}, "
                f"minimum required: {self.MIN_PYTHON_VERSION}"
            )

        # Claude CLI check
        claude_path = self._find_claude_cli()
        results["claude_cli"] = claude_path is not None
        self.info.claude_cli_path = claude_path
        if claude_path:
            logger.info(f"Claude CLI found: {claude_path}")
        else:
            logger.warning("Claude CLI not found in PATH")

        # Git check
        git_ok = shutil.which("git") is not None
        results["git"] = git_ok
        if git_ok:
            logger.info("Git found")
        else:
            logger.warning("Git not found - some features may not work")

        # pip check
        pip_ok = shutil.which("pip") is not None or shutil.which("pip3") is not None
        results["pip"] = pip_ok
        if pip_ok:
            logger.info("pip found")
        else:
            logger.error("pip not found")

        # venv module check
        try:
            import venv
            results["venv"] = True
            logger.info("venv module available")
        except ImportError:
            results["venv"] = False
            logger.error("venv module not available")

        all_passed = all(results.values())
        logger.info(f"Prerequisites check: {'PASSED' if all_passed else 'FAILED'}")

        return results

    def _find_claude_cli(self) -> Optional[str]:
        """Find Claude CLI executable."""
        # Check common locations based on platform
        if self.platform == Platform.WINDOWS:
            paths_to_check = [
                shutil.which("claude"),
                os.path.expandvars(r"%LOCALAPPDATA%\Programs\claude\claude.exe"),
                os.path.expandvars(r"%APPDATA%\npm\claude.cmd"),
            ]
        else:
            paths_to_check = [
                shutil.which("claude"),
                "/usr/local/bin/claude",
                "/usr/bin/claude",
                os.path.expanduser("~/.local/bin/claude"),
                os.path.expanduser("~/.npm-global/bin/claude"),
            ]

        for path in paths_to_check:
            if path and Path(path).exists():
                return str(Path(path).resolve())
        return None

    def verify_installation(self) -> bool:
        """
        Check all required files are present and valid.

        Returns:
            True if installation is valid, False otherwise.
        """
        logger.info("Verifying installation...")
        logger.info(f"Install path: {self.install_path}")

        missing_files = []
        invalid_files = []

        for file_path in self.REQUIRED_FILES:
            full_path = self.install_path / file_path
            if not full_path.exists():
                missing_files.append(file_path)
                logger.warning(f"Missing file: {file_path}")
            elif full_path.stat().st_size == 0:
                invalid_files.append(file_path)
                logger.warning(f"Empty file: {file_path}")
            else:
                logger.debug(f"Found: {file_path}")

        # Check if src directory exists
        src_dir = self.install_path / "src"
        if not src_dir.exists():
            logger.warning("src/ directory not found")
            missing_files.append("src/")

        if missing_files or invalid_files:
            logger.error(
                f"Verification failed: {len(missing_files)} missing, "
                f"{len(invalid_files)} invalid files"
            )
            self.info.files_verified = False
            self.info.status = "incomplete"
            return False

        logger.info("Installation verified successfully")
        self.info.files_verified = True
        self.info.status = "verified"
        self.info.last_verified = datetime.now().isoformat()
        return True

    def setup_python_env(
        self, venv_path: Optional[Path] = None, upgrade: bool = True
    ) -> bool:
        """
        Create virtual environment and install dependencies.

        Args:
            venv_path: Path for virtual environment (default: install_path/.venv)
            upgrade: Whether to upgrade pip

        Returns:
            True if setup successful, False otherwise.
        """
        logger.info("Setting up Python environment...")

        venv_path = venv_path or self.install_path / ".venv"
        requirements_path = self.install_path / "requirements.txt"

        try:
            # Create virtual environment
            if venv_path.exists():
                logger.info(f"Virtual environment already exists: {venv_path}")
            else:
                logger.info(f"Creating virtual environment: {venv_path}")
                import venv
                venv.create(venv_path, with_pip=True)

            # Determine pip executable
            if self.platform == Platform.WINDOWS:
                pip_executable = str(venv_path / "Scripts" / "pip.exe")
                python_executable = str(venv_path / "Scripts" / "python.exe")
            else:
                pip_executable = str(venv_path / "bin" / "pip")
                python_executable = str(venv_path / "bin" / "python")

            # Upgrade pip
            if upgrade:
                logger.info("Upgrading pip...")
                subprocess.run(
                    [python_executable, "-m", "pip", "install", "--upgrade", "pip"],
                    check=True,
                    capture_output=True,
                )

            # Install requirements
            if requirements_path.exists():
                logger.info(f"Installing requirements from {requirements_path}")
                subprocess.run(
                    [pip_executable, "install", "-r", str(requirements_path)],
                    check=True,
                    capture_output=True,
                )
                logger.info("Dependencies installed successfully")
            else:
                logger.warning(f"requirements.txt not found at {requirements_path}")

            return True

        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to setup Python environment: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error during environment setup: {e}")
            return False

    def configure_mcp(self, claude_config_path: Optional[Path] = None) -> bool:
        """
        Setup MCP server configuration for Claude CLI.

        Args:
            claude_config_path: Path to Claude config directory

        Returns:
            True if configuration successful, False otherwise.
        """
        logger.info("Configuring MCP server...")

        # Determine Claude config path
        if claude_config_path is None:
            if self.platform == Platform.WINDOWS:
                claude_config_path = Path(
                    os.path.expandvars(r"%APPDATA%\Claude")
                )
            elif self.platform == Platform.DARWIN:
                claude_config_path = Path.home() / "Library" / "Application Support" / "Claude"
            else:
                claude_config_path = Path.home() / ".config" / "claude"

        settings_path = claude_config_path / "settings.json"

        try:
            # Create Claude config directory if needed
            claude_config_path.mkdir(parents=True, exist_ok=True)

            # Load existing settings or create new
            if settings_path.exists():
                logger.info(f"Loading existing settings: {settings_path}")
                with open(settings_path, "r", encoding="utf-8") as f:
                    settings = json.load(f)
            else:
                logger.info("Creating new settings file")
                settings = {}

            # Ensure mcpServers exists
            if "mcpServers" not in settings:
                settings["mcpServers"] = {}

            # Add orchestrator MCP server configuration
            orchestrator_path = self.install_path / "src" / "orchestrator" / "server.py"
            settings["mcpServers"]["orchestrator"] = {
                "command": sys.executable,
                "args": [str(orchestrator_path)],
                "env": {},
                "disabled": False,
            }

            # Save settings
            with open(settings_path, "w", encoding="utf-8") as f:
                json.dump(settings, f, indent=2)

            logger.info(f"MCP configuration written to {settings_path}")
            self.info.mcp_configured = True
            return True

        except PermissionError as e:
            logger.error(f"Permission denied writing to {settings_path}: {e}")
            return False
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON in settings file: {e}")
            return False
        except Exception as e:
            logger.error(f"Failed to configure MCP: {e}")
            return False

    def generate_mcp_config_template(self) -> dict:
        """
        Generate MCP configuration template.

        Returns:
            MCP configuration dictionary.
        """
        return {
            "mcpServers": {
                "orchestrator": {
                    "command": sys.executable,
                    "args": [str(self.install_path / "src" / "orchestrator" / "server.py")],
                    "env": {},
                    "disabled": False,
                }
            }
        }

    def backup_config(self, backup_path: Optional[Path] = None) -> Optional[Path]:
        """
        Create backup of current configuration.

        Args:
            backup_path: Custom backup path (default: backups/timestamp/)

        Returns:
            Path to backup directory, or None on failure.
        """
        logger.info("Creating configuration backup...")

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = backup_path or self._backup_dir / timestamp

        try:
            backup_dir.mkdir(parents=True, exist_ok=True)

            # Backup config directory
            if self._config_dir.exists():
                config_backup = backup_dir / "config"
                shutil.copytree(self._config_dir, config_backup)
                logger.info(f"Config backed up to {config_backup}")

            # Backup settings.json if exists
            settings_src = self.install_path / "settings.json"
            if settings_src.exists():
                settings_dst = backup_dir / "settings.json"
                shutil.copy2(settings_src, settings_dst)
                logger.info(f"Settings backed up to {settings_dst}")

            # Backup requirements.txt
            requirements_src = self.install_path / "requirements.txt"
            if requirements_src.exists():
                requirements_dst = backup_dir / "requirements.txt"
                shutil.copy2(requirements_src, requirements_dst)
                logger.info(f"Requirements backed up to {requirements_dst}")

            # Create backup manifest
            manifest = {
                "timestamp": timestamp,
                "platform": self.platform.value,
                "python_version": platform.python_version(),
                "install_path": str(self.install_path),
                "files": [str(p.relative_to(backup_dir)) for p in backup_dir.rglob("*") if p.is_file()],
            }

            manifest_path = backup_dir / "manifest.json"
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f, indent=2)

            logger.info(f"Backup created successfully: {backup_dir}")
            return backup_dir

        except Exception as e:
            logger.error(f"Backup failed: {e}")
            # Cleanup partial backup
            if backup_dir.exists():
                shutil.rmtree(backup_dir, ignore_errors=True)
            return None

    def restore_config(self, backup_path: Path) -> bool:
        """
        Restore configuration from backup.

        Args:
            backup_path: Path to backup directory

        Returns:
            True if restore successful, False otherwise.
        """
        logger.info(f"Restoring configuration from {backup_path}...")

        if not backup_path.exists():
            logger.error(f"Backup path does not exist: {backup_path}")
            return False

        # Check for manifest
        manifest_path = backup_path / "manifest.json"
        if not manifest_path.exists():
            logger.error("Backup manifest not found - invalid backup")
            return False

        try:
            # Load manifest
            with open(manifest_path, "r", encoding="utf-8") as f:
                manifest = json.load(f)

            logger.info(f"Restoring backup from {manifest['timestamp']}")

            # Create backup of current config before restore
            current_backup = self.backup_config()
            if current_backup:
                logger.info(f"Current config backed up to {current_backup}")

            # Restore config directory
            config_backup = backup_path / "config"
            if config_backup.exists():
                if self._config_dir.exists():
                    shutil.rmtree(self._config_dir)
                shutil.copytree(config_backup, self._config_dir)
                logger.info("Config directory restored")

            # Restore settings.json
            settings_backup = backup_path / "settings.json"
            if settings_backup.exists():
                settings_dst = self.install_path / "settings.json"
                shutil.copy2(settings_backup, settings_dst)
                logger.info("Settings restored")

            # Restore requirements.txt
            requirements_backup = backup_path / "requirements.txt"
            if requirements_backup.exists():
                requirements_dst = self.install_path / "requirements.txt"
                shutil.copy2(requirements_backup, requirements_dst)
                logger.info("Requirements restored")

            logger.info("Configuration restored successfully")
            return True

        except Exception as e:
            logger.error(f"Restore failed: {e}")
            return False

    def generate_settings_json(self) -> dict:
        """
        Generate default settings.json content.

        Returns:
            Settings dictionary.
        """
        return {
            "version": self.info.version,
            "install_path": str(self.install_path),
            "created": datetime.now().isoformat(),
            "platform": self.platform.value,
            "orchestrator": {
                "enabled": True,
                "log_level": "INFO",
                "max_workers": 4,
                "timeout_seconds": 300,
            },
            "agents": {
                "default_model": "inherit",
                "parallel_tasks": True,
                "max_retries": 3,
            },
            "logging": {
                "level": "INFO",
                "file_logging": True,
                "console_logging": True,
                "log_dir": "logs",
            },
        }

    def generate_gitignore(self) -> str:
        """
        Generate .gitignore content for the package.

        Returns:
            .gitignore content string.
        """
        return """# Claude Orchestrator Plugin - Git Ignore

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
.venv/
venv/
ENV/
env/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# Logs
logs/
*.log

# Backups
backups/
*.bak

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Environment variables
.env
.env.local
.env.*.local

# OS files
.DS_Store
Thumbs.db
desktop.ini

# Claude specific
.claude/
credentials.json
"""

    def generate_files(self, force: bool = False) -> list[Path]:
        """
        Generate configuration files if they don't exist.

        Args:
            force: Overwrite existing files

        Returns:
            List of created files.
        """
        logger.info("Generating configuration files...")
        created_files = []

        # settings.json
        settings_path = self.install_path / "settings.json"
        if force or not settings_path.exists():
            with open(settings_path, "w", encoding="utf-8") as f:
                json.dump(self.generate_settings_json(), f, indent=2)
            logger.info(f"Created: {settings_path}")
            created_files.append(settings_path)

        # .gitignore
        gitignore_path = self.install_path / ".gitignore"
        if force or not gitignore_path.exists():
            with open(gitignore_path, "w", encoding="utf-8") as f:
                f.write(self.generate_gitignore())
            logger.info(f"Created: {gitignore_path}")
            created_files.append(gitignore_path)

        # mcp_config.json template
        mcp_config_path = self.install_path / "mcp_config.json"
        if force or not mcp_config_path.exists():
            with open(mcp_config_path, "w", encoding="utf-8") as f:
                json.dump(self.generate_mcp_config_template(), f, indent=2)
            logger.info(f"Created: {mcp_config_path}")
            created_files.append(mcp_config_path)

        # Create config directory
        self._config_dir.mkdir(exist_ok=True)
        logger.info(f"Ensured directory exists: {self._config_dir}")

        return created_files

    def get_install_info(self) -> InstallInfo:
        """
        Get current installation information.

        Returns:
            InstallInfo dataclass with current status.
        """
        # Update info
        self.info.platform = platform.system()
        self.info.python_version = platform.python_version()

        # Check Claude CLI
        self.info.claude_cli_path = self._find_claude_cli()

        # Check if MCP is configured
        if self.platform == Platform.WINDOWS:
            settings_path = Path(os.path.expandvars(r"%APPDATA%\Claude\settings.json"))
        elif self.platform == Platform.DARWIN:
            settings_path = Path.home() / "Library" / "Application Support" / "Claude" / "settings.json"
        else:
            settings_path = Path.home() / ".config" / "claude" / "settings.json"

        if settings_path.exists():
            try:
                with open(settings_path, "r", encoding="utf-8") as f:
                    settings = json.load(f)
                self.info.mcp_configured = "orchestrator" in settings.get("mcpServers", {})
            except Exception:
                self.info.mcp_configured = False

        return self.info

    def full_setup(self) -> bool:
        """
        Run complete setup process.

        Returns:
            True if setup successful, False otherwise.
        """
        logger.info("=" * 50)
        logger.info("Starting Claude Orchestrator Plugin Setup")
        logger.info("=" * 50)

        try:
            # Step 1: Check prerequisites
            prereqs = self.check_prerequisites()
            if not all(prereqs.values()):
                failed = [k for k, v in prereqs.items() if not v]
                raise SetupError(f"Prerequisites not met: {failed}")

            # Step 2: Generate configuration files
            created = self.generate_files()
            logger.info(f"Created {len(created)} configuration files")

            # Step 3: Setup Python environment
            if not self.setup_python_env():
                raise SetupError("Failed to setup Python environment", recoverable=True)

            # Step 4: Configure MCP
            if not self.configure_mcp():
                logger.warning("MCP configuration failed - manual setup may be required")

            # Step 5: Verify installation
            if not self.verify_installation():
                logger.warning("Installation verification incomplete")

            logger.info("=" * 50)
            logger.info("Setup completed successfully!")
            logger.info("=" * 50)

            self.info.status = "installed"
            return True

        except SetupError as e:
            logger.error(f"Setup failed: {e.message}")
            if e.recoverable:
                logger.info("You may be able to continue with manual steps")
            return False
        except Exception as e:
            logger.error(f"Unexpected error during setup: {e}")
            return False


def main():
    """Main entry point for setup script."""
    parser = argparse.ArgumentParser(
        description="Claude Orchestrator Plugin Setup Script",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python setup.py --verify
    python setup.py --configure-mcp
    python setup.py --full-setup
    python setup.py --backup
    python setup.py --restore ./backups/20260227_120000
    python setup.py --info
        """,
    )

    parser.add_argument(
        "--install-path",
        type=Path,
        default=Path(__file__).parent,
        help="Installation directory path",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify installation integrity",
    )
    parser.add_argument(
        "--configure-mcp",
        action="store_true",
        help="Configure MCP server for Claude CLI",
    )
    parser.add_argument(
        "--setup-env",
        action="store_true",
        help="Setup Python virtual environment",
    )
    parser.add_argument(
        "--backup",
        action="store_true",
        help="Create backup of current configuration",
    )
    parser.add_argument(
        "--restore",
        type=Path,
        default=None,
        help="Restore configuration from backup path",
    )
    parser.add_argument(
        "--generate-files",
        action="store_true",
        help="Generate configuration files (settings.json, .gitignore, etc.)",
    )
    parser.add_argument(
        "--full-setup",
        action="store_true",
        help="Run complete setup process",
    )
    parser.add_argument(
        "--info",
        action="store_true",
        help="Display installation information",
    )
    parser.add_argument(
        "--check-prereqs",
        action="store_true",
        help="Check prerequisites only",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force overwrite existing files",
    )

    args = parser.parse_args()

    # Initialize setup
    setup = ClaudeOrchestratorSetup(args.install_path)

    # Handle no arguments - show help
    if len(sys.argv) == 1:
        parser.print_help()
        return 0

    try:
        # Execute requested action
        if args.check_prereqs:
            results = setup.check_prerequisites()
            print("\nPrerequisites Check Results:")
            for name, passed in results.items():
                status = "PASS" if passed else "FAIL"
                print(f"  {name}: {status}")
            return 0 if all(results.values()) else 1

        if args.verify:
            success = setup.verify_installation()
            print(f"\nVerification: {'PASSED' if success else 'FAILED'}")
            return 0 if success else 1

        if args.configure_mcp:
            success = setup.configure_mcp()
            print(f"\nMCP Configuration: {'SUCCESS' if success else 'FAILED'}")
            return 0 if success else 1

        if args.setup_env:
            success = setup.setup_python_env()
            print(f"\nEnvironment Setup: {'SUCCESS' if success else 'FAILED'}")
            return 0 if success else 1

        if args.backup:
            backup_path = setup.backup_config()
            if backup_path:
                print(f"\nBackup created: {backup_path}")
                return 0
            else:
                print("\nBackup FAILED")
                return 1

        if args.restore:
            success = setup.restore_config(args.restore)
            print(f"\nRestore: {'SUCCESS' if success else 'FAILED'}")
            return 0 if success else 1

        if args.generate_files:
            created = setup.generate_files(force=args.force)
            print(f"\nGenerated {len(created)} files:")
            for f in created:
                print(f"  {f}")
            return 0

        if args.info:
            info = setup.get_install_info()
            print("\nInstallation Information:")
            print(f"  Version: {info.version}")
            print(f"  Platform: {info.platform}")
            print(f"  Python: {info.python_version}")
            print(f"  Install Path: {info.install_path}")
            print(f"  Claude CLI: {info.claude_cli_path or 'Not found'}")
            print(f"  MCP Configured: {info.mcp_configured}")
            print(f"  Files Verified: {info.files_verified}")
            print(f"  Status: {info.status}")
            print(f"  Last Verified: {info.last_verified or 'Never'}")
            return 0

        if args.full_setup:
            success = setup.full_setup()
            return 0 if success else 1

        # Default: run verification
        success = setup.verify_installation()
        return 0 if success else 1

    except KeyboardInterrupt:
        print("\n\nSetup cancelled by user")
        return 130
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        print(f"\nError: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
