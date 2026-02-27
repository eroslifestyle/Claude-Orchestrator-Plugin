#!/bin/bash
#
# Claude Orchestrator Plugin Installer
# Version: 1.0.0
# Supports: Linux (Ubuntu, Debian, CentOS, Fedora, Arch) and macOS
#
# Usage: ./install.sh [OPTIONS]
# Options:
#   -p, --path PATH     Custom install path (default: ~/.claude)
#   -s, --silent        Silent mode (no prompts, minimal output)
#   -b, --backup        Backup existing configuration before install
#   -v, --verbose       Verbose output
#   -h, --help          Show this help message
#
# Repository: https://github.com/leodg/claude-orchestrator-plugin
#

set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")
readonly MIN_BASH_VERSION=4
readonly MIN_PYTHON_VERSION="3.10"

# Default values
INSTALL_PATH=""
SILENT_MODE=false
BACKUP_MODE=false
VERBOSE_MODE=false
BACKUP_PATH=""

# Color codes (disabled in silent mode or non-interactive terminals)
if [[ -t 1 ]] && [[ "$SILENT_MODE" != "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# OS and Architecture detection
OS_TYPE=""
OS_DISTRO=""
ARCH_TYPE=""
PACKAGE_MANAGER=""

# Rollback tracking
declare -a CREATED_DIRS=()
declare -a COPIED_FILES=()
ROLLBACK_NEEDED=false

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

log_info() {
    [[ "$SILENT_MODE" == "true" ]] && return
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    [[ "$SILENT_MODE" == "true" ]] && return
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    [[ "$VERBOSE_MODE" != "true" ]] && return
    echo -e "${CYAN}[DEBUG]${NC} $1"
}

log_step() {
    [[ "$SILENT_MODE" == "true" ]] && return
    echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"
}

log_progress() {
    [[ "$SILENT_MODE" == "true" ]] && return
    printf "    ${GREEN}✓${NC} $1\n"
}

show_spinner() {
    local pid=$1
    local message=$2
    local spin='-\|/'
    local i=0

    [[ "$SILENT_MODE" == "true" ]] && return

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r    ${spin:$i:1} $message..."
        sleep 0.1
    done
    printf "\r    ${GREEN}✓${NC} $message    \n"
}

# ==============================================================================
# HELP AND USAGE
# ==============================================================================

show_help() {
    cat << EOF
${BOLD}Claude Orchestrator Plugin Installer v${SCRIPT_VERSION}${NC}

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -p, --path PATH     Custom installation path
                        Default: ~/.claude or \$XDG_CONFIG_HOME/claude

    -s, --silent        Silent mode - no prompts, minimal output
                        Useful for automated/scripted installations

    -b, --backup        Backup existing configuration before installation
                        Backup will be stored at <install_path>.backup.<timestamp>

    -v, --verbose       Verbose output - show detailed installation steps

    -h, --help          Show this help message and exit

EXAMPLES:
    # Default installation
    $SCRIPT_NAME

    # Silent installation with backup
    $SCRIPT_NAME --silent --backup

    # Custom path
    $SCRIPT_NAME --path /opt/claude-orchestrator

    # Verbose installation
    $SCRIPT_NAME -v

REQUIREMENTS:
    - Bash 4+ or Zsh
    - Python 3.10+
    - Claude Code CLI (optional, for verification)

FILES INSTALLED:
    - agents/           43 agent definitions (core, experts, L2 specialists)
    - skills/orchestrator/  Orchestrator skill + 16 documentation files
    - rules/            10 rule files (coding-style, security, testing, etc.)
    - learnings/        Learning system (instincts.json)
    - templates/        3 template files (task, review, integration)
    - workflows/        4 workflow files (bugfix, feature, refactor, optimize)
    - CLAUDE.md         Global instructions file

FILES EXCLUDED:
    - .credentials.json (security)
    - .env files (security)
    - stats-cache.json, history.jsonl (runtime data)
    - paste-cache/, debug/, backups/ (temp directories)

For more information: https://github.com/leodg/claude-orchestrator-plugin
EOF
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--path)
                if [[ -z "$2" || "$2" == -* ]]; then
                    log_error "Option --path requires a path argument"
                    exit 1
                fi
                INSTALL_PATH="$2"
                shift 2
                ;;
            -s|--silent)
                SILENT_MODE=true
                shift
                ;;
            -b|--backup)
                BACKUP_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done
}

# ==============================================================================
# SYSTEM DETECTION
# ==============================================================================

detect_os() {
    log_step "Detecting operating system..."

    case "$(uname -s)" in
        Linux*)
            OS_TYPE="linux"

            # Detect distribution
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                OS_DISTRO="${ID}"
                log_debug "Detected distro: ${ID} (${VERSION_ID:-unknown version})"
            elif [[ -f /etc/redhat-release ]]; then
                OS_DISTRO="rhel"
            elif [[ -f /etc/debian_version ]]; then
                OS_DISTRO="debian"
            else
                OS_DISTRO="unknown"
            fi

            # Detect package manager
            if command -v apt-get &>/dev/null; then
                PACKAGE_MANAGER="apt"
            elif command -v dnf &>/dev/null; then
                PACKAGE_MANAGER="dnf"
            elif command -v yum &>/dev/null; then
                PACKAGE_MANAGER="yum"
            elif command -v pacman &>/dev/null; then
                PACKAGE_MANAGER="pacman"
            elif command -v zypper &>/dev/null; then
                PACKAGE_MANAGER="zypper"
            else
                PACKAGE_MANAGER="unknown"
            fi

            log_progress "Linux (${OS_DISTRO}) with ${PACKAGE_MANAGER} package manager"
            ;;

        Darwin*)
            OS_TYPE="macos"
            OS_DISTRO="macos"
            PACKAGE_MANAGER="brew"
            log_progress "macOS detected"
            ;;

        *)
            log_error "Unsupported operating system: $(uname -s)"
            log_error "This installer supports Linux and macOS only"
            exit 1
            ;;
    esac
}

detect_architecture() {
    log_step "Detecting system architecture..."

    local arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            ARCH_TYPE="x86_64"
            log_progress "x86_64 (Intel/AMD 64-bit)"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            if [[ "$OS_TYPE" == "macos" ]]; then
                log_progress "arm64 (Apple Silicon)"
            else
                log_progress "arm64 (ARM 64-bit)"
            fi
            ;;
        armv7l|armhf)
            ARCH_TYPE="arm32"
            log_progress "arm32 (ARM 32-bit)"
            log_warn "ARM 32-bit may have limited support"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# ==============================================================================
# PREREQUISITE CHECKS
# ==============================================================================

check_bash_version() {
    log_step "Checking Bash version..."

    local bash_version="${BASH_VERSION%%.*}"

    if [[ "$bash_version" -lt "$MIN_BASH_VERSION" ]]; then
        log_error "Bash version $MIN_BASH_VERSION+ required, found ${BASH_VERSION}"
        log_error "Please upgrade Bash or use Zsh"

        # Check for Zsh as alternative
        if [[ -n "$ZSH_VERSION" ]]; then
            log_info "Zsh detected - you can run this script with zsh"
        fi
        exit 1
    fi

    log_progress "Bash ${BASH_VERSION} (OK)"
}

check_python() {
    log_step "Checking Python installation..."

    local python_cmd=""
    local python_version=""

    # Try python3 first, then python
    if command -v python3 &>/dev/null; then
        python_cmd="python3"
    elif command -v python &>/dev/null; then
        python_cmd="python"
    else
        log_error "Python not found"
        log_error "Python ${MIN_PYTHON_VERSION}+ is required"
        [[ "$SILENT_MODE" != "true" ]] && suggest_python_install
        exit 1
    fi

    # Get version
    python_version=$($python_cmd --version 2>&1 | awk '{print $2}')
    log_debug "Found Python version: $python_version"

    # Verify minimum version
    local major=$(echo "$python_version" | cut -d. -f1)
    local minor=$(echo "$python_version" | cut -d. -f2)

    if [[ "$major" -lt 3 ]] || ([[ "$major" -eq 3 ]] && [[ "$minor" -lt 10 ]]); then
        log_error "Python ${MIN_PYTHON_VERSION}+ required, found ${python_version}"
        exit 1
    fi

    log_progress "Python ${python_version} (OK)"
}

suggest_python_install() {
    echo ""
    echo "To install Python ${MIN_PYTHON_VERSION}+:"
    case "$PACKAGE_MANAGER" in
        apt)
            echo "  sudo apt update && sudo apt install python3 python3-pip"
            ;;
        dnf|yum)
            echo "  sudo $PACKAGE_MANAGER install python3 python3-pip"
            ;;
        pacman)
            echo "  sudo pacman -S python python-pip"
            ;;
        brew)
            echo "  brew install python"
            ;;
        *)
            echo "  Visit: https://www.python.org/downloads/"
            ;;
    esac
}

check_git() {
    log_step "Checking Git (optional)..."

    if command -v git &>/dev/null; then
        local git_version=$(git --version | awk '{print $3}')
        log_progress "Git ${git_version} (OK)"
    else
        log_warn "Git not found - some features may be limited"
        log_debug "Git is optional but recommended for version control"
    fi
}

check_claude_cli() {
    log_step "Checking Claude Code CLI (optional)..."

    if command -v claude &>/dev/null; then
        log_progress "Claude Code CLI found (OK)"
    else
        log_warn "Claude Code CLI not found"
        log_debug "Claude Code CLI is required to use the orchestrator"
        [[ "$SILENT_MODE" != "true" ]] && echo "  Install from: https://claude.ai/claude-code"
    fi
}

# ==============================================================================
# PATH SETUP
# ==============================================================================

setup_install_path() {
    log_step "Setting up installation path..."

    # Determine default path
    if [[ -z "$INSTALL_PATH" ]]; then
        if [[ -n "$XDG_CONFIG_HOME" ]]; then
            INSTALL_PATH="${XDG_CONFIG_HOME}/claude"
            log_debug "Using XDG_CONFIG_HOME: $INSTALL_PATH"
        else
            INSTALL_PATH="$HOME/.claude"
            log_debug "Using default path: $INSTALL_PATH"
        fi
    fi

    # Expand ~ if present
    INSTALL_PATH="${INSTALL_PATH/#\~/$HOME}"

    # Validate path
    if [[ ! "$INSTALL_PATH" =~ ^/ ]]; then
        log_error "Install path must be absolute: $INSTALL_PATH"
        exit 1
    fi

    log_progress "Installation path: ${INSTALL_PATH}"
}

# ==============================================================================
# BACKUP
# ==============================================================================

create_backup() {
    if [[ "$BACKUP_MODE" != "true" ]]; then
        return 0
    fi

    if [[ ! -d "$INSTALL_PATH" ]]; then
        log_info "No existing installation to backup"
        return 0
    fi

    log_step "Creating backup..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="${INSTALL_PATH}.backup.${timestamp}"

    if cp -rp "$INSTALL_PATH" "$BACKUP_PATH"; then
        log_progress "Backup created: ${BACKUP_PATH}"
    else
        log_error "Failed to create backup"
        ROLLBACK_NEEDED=false  # Nothing to rollback if backup fails
        exit 1
    fi
}

# ==============================================================================
# ROLLBACK
# ==============================================================================

rollback() {
    log_error "Installation failed. Rolling back..."

    # Remove copied files
    for file in "${COPIED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_debug "Removed: $file"
        fi
    done

    # Remove created directories (in reverse order)
    for ((i=${#CREATED_DIRS[@]}-1; i>=0; i--)); do
        local dir="${CREATED_DIRS[$i]}"
        if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
            rmdir "$dir"
            log_debug "Removed directory: $dir"
        fi
    done

    # Restore backup if created
    if [[ -n "$BACKUP_PATH" ]] && [[ -d "$BACKUP_PATH" ]]; then
        if [[ -d "$INSTALL_PATH" ]]; then
            rm -rf "$INSTALL_PATH"
        fi
        mv "$BACKUP_PATH" "$INSTALL_PATH"
        log_info "Backup restored from: $BACKUP_PATH"
    fi

    log_error "Rollback complete. Installation cancelled."
}

# ==============================================================================
# DIRECTORY STRUCTURE
# ==============================================================================

create_directory_structure() {
    log_step "Creating directory structure..."

    local directories=(
        "$INSTALL_PATH"
        "$INSTALL_PATH/agents"
        "$INSTALL_PATH/agents/core"
        "$INSTALL_PATH/agents/experts"
        "$INSTALL_PATH/agents/experts/L2"
        "$INSTALL_PATH/agents/system"
        "$INSTALL_PATH/agents/docs"
        "$INSTALL_PATH/agents/config"
        "$INSTALL_PATH/agents/tests"
        "$INSTALL_PATH/skills"
        "$INSTALL_PATH/skills/orchestrator"
        "$INSTALL_PATH/skills/orchestrator/docs"
        "$INSTALL_PATH/rules"
        "$INSTALL_PATH/rules/common"
        "$INSTALL_PATH/rules/python"
        "$INSTALL_PATH/rules/typescript"
        "$INSTALL_PATH/rules/go"
        "$INSTALL_PATH/learnings"
        "$INSTALL_PATH/templates"
        "$INSTALL_PATH/workflows"
    )

    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            CREATED_DIRS+=("$dir")
            log_debug "Created: $dir"
        else
            log_debug "Exists: $dir"
        fi
    done

    log_progress "Directory structure created (${#CREATED_DIRS[@]} new directories)"
}

# ==============================================================================
# FILE COPYING
# ==============================================================================

copy_files() {
    log_step "Copying plugin files..."

    # Get script directory (source of files)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # If running from extracted archive, use relative paths
    # If running from repo, adjust paths accordingly
    local source_root=""

    # Determine source location
    if [[ -d "$script_dir/agents" ]]; then
        source_root="$script_dir"
    elif [[ -d "$script_dir/../.claude/agents" ]]; then
        source_root="$script_dir/.."
    else
        log_error "Cannot find source files. Are you running from the correct directory?"
        exit 1
    fi

    local files_copied=0
    local files_failed=0

    # Function to copy with tracking
    copy_file() {
        local src="$1"
        local dst="$2"

        if [[ -f "$src" ]]; then
            cp -p "$src" "$dst"
            COPIED_FILES+=("$dst")
            ((files_copied++))
            log_debug "Copied: $src -> $dst"
        else
            log_warn "Source file not found: $src"
            ((files_failed++))
        fi
    }

    # Copy CLAUDE.md
    copy_file "$source_root/CLAUDE.md" "$INSTALL_PATH/CLAUDE.md"

    # Copy agents/
    log_debug "Copying agents..."
    for file in "$source_root/agents/core"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/core/"
    done
    for file in "$source_root/agents/experts"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/experts/"
    done
    for file in "$source_root/agents/experts/L2"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/experts/L2/"
    done
    for file in "$source_root/agents/system"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/system/"
    done
    for file in "$source_root/agents/docs"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/docs/"
    done
    for file in "$source_root/agents/config"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/config/"
    done
    for file in "$source_root/agents/tests"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/agents/tests/"
    done
    [[ -f "$source_root/agents/INDEX.md" ]] && copy_file "$source_root/agents/INDEX.md" "$INSTALL_PATH/agents/"
    [[ -f "$source_root/agents/CLAUDE.md" ]] && copy_file "$source_root/agents/CLAUDE.md" "$INSTALL_PATH/agents/"

    # Copy skills/orchestrator/
    log_debug "Copying skills/orchestrator..."
    copy_file "$source_root/skills/orchestrator/SKILL.md" "$INSTALL_PATH/skills/orchestrator/"
    for file in "$source_root/skills/orchestrator/docs"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/skills/orchestrator/docs/"
    done

    # Copy rules/
    log_debug "Copying rules..."
    for file in "$source_root/rules/common"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/rules/common/"
    done
    for file in "$source_root/rules/python"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/rules/python/"
    done
    for file in "$source_root/rules/typescript"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/rules/typescript/"
    done
    for file in "$source_root/rules/go"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/rules/go/"
    done
    [[ -f "$source_root/rules/format-standard.md" ]] && copy_file "$source_root/rules/format-standard.md" "$INSTALL_PATH/rules/"
    [[ -f "$source_root/rules/README.md" ]] && copy_file "$source_root/rules/README.md" "$INSTALL_PATH/rules/"

    # Copy learnings/
    log_debug "Copying learnings..."
    copy_file "$source_root/learnings/instincts.json" "$INSTALL_PATH/learnings/"
    copy_file "$source_root/learnings/README.md" "$INSTALL_PATH/learnings/"

    # Copy templates/
    log_debug "Copying templates..."
    for file in "$source_root/templates"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/templates/"
    done

    # Copy workflows/
    log_debug "Copying workflows..."
    for file in "$source_root/workflows"/*.md; do
        [[ -f "$file" ]] && copy_file "$file" "$INSTALL_PATH/workflows/"
    done

    log_progress "Files copied: ${files_copied}"
    [[ "$files_failed" -gt 0 ]] && log_warn "Files failed: ${files_failed}"
}

# ==============================================================================
# PERMISSIONS
# ==============================================================================

set_permissions() {
    log_step "Setting permissions..."

    # Set directory permissions
    find "$INSTALL_PATH" -type d -exec chmod 755 {} \; 2>/dev/null || true

    # Set file permissions
    find "$INSTALL_PATH" -type f -exec chmod 644 {} \; 2>/dev/null || true

    # Make any shell scripts executable
    find "$INSTALL_PATH" -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true

    log_progress "Permissions set (directories: 755, files: 644)"
}

# ==============================================================================
# VERIFICATION
# ==============================================================================

verify_installation() {
    log_step "Verifying installation..."

    local errors=0
    local warnings=0

    # Check required directories
    local required_dirs=(
        "$INSTALL_PATH/agents"
        "$INSTALL_PATH/agents/core"
        "$INSTALL_PATH/agents/experts"
        "$INSTALL_PATH/skills/orchestrator"
        "$INSTALL_PATH/rules"
        "$INSTALL_PATH/learnings"
        "$INSTALL_PATH/templates"
        "$INSTALL_PATH/workflows"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Missing directory: $dir"
            ((errors++))
        fi
    done

    # Check critical files
    local critical_files=(
        "$INSTALL_PATH/CLAUDE.md"
        "$INSTALL_PATH/skills/orchestrator/SKILL.md"
        "$INSTALL_PATH/agents/INDEX.md"
        "$INSTALL_PATH/learnings/instincts.json"
    )

    for file in "${critical_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing critical file: $file"
            ((errors++))
        fi
    done

    # Count installed components
    local agent_count=$(find "$INSTALL_PATH/agents" -name "*.md" -type f 2>/dev/null | wc -l)
    local rule_count=$(find "$INSTALL_PATH/rules" -name "*.md" -type f 2>/dev/null | wc -l)
    local template_count=$(find "$INSTALL_PATH/templates" -name "*.md" -type f 2>/dev/null | wc -l)
    local workflow_count=$(find "$INSTALL_PATH/workflows" -name "*.md" -type f 2>/dev/null | wc -l)
    local doc_count=$(find "$INSTALL_PATH/skills/orchestrator/docs" -name "*.md" -type f 2>/dev/null | wc -l)

    log_debug "Agent files: $agent_count"
    log_debug "Rule files: $rule_count"
    log_debug "Template files: $template_count"
    log_debug "Workflow files: $workflow_count"
    log_debug "Documentation files: $doc_count"

    # Expected counts (approximate)
    if [[ "$agent_count" -lt 40 ]]; then
        log_warn "Agent count ($agent_count) lower than expected (43+)"
        ((warnings++))
    fi

    if [[ "$rule_count" -lt 8 ]]; then
        log_warn "Rule count ($rule_count) lower than expected (10+)"
        ((warnings++))
    fi

    # Report results
    if [[ "$errors" -gt 0 ]]; then
        log_error "Verification failed with $errors error(s)"
        return 1
    elif [[ "$warnings" -gt 0 ]]; then
        log_warn "Verification completed with $warnings warning(s)"
        return 0
    else
        log_progress "Verification passed"
        return 0
    fi
}

# ==============================================================================
# SUCCESS MESSAGE
# ==============================================================================

show_success() {
    [[ "$SILENT_MODE" == "true" ]] && return

    echo ""
    echo -e "${GREEN}${BOLD}========================================${NC}"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}========================================${NC}"
    echo ""
    echo -e "  ${BOLD}Installation Path:${NC}    ${INSTALL_PATH}"
    echo -e "  ${BOLD}Version:${NC}             v${SCRIPT_VERSION}"
    echo -e "  ${BOLD}Platform:${NC}            ${OS_TYPE} (${ARCH_TYPE})"
    echo ""

    if [[ -n "$BACKUP_PATH" ]]; then
        echo -e "  ${BOLD}Backup:${NC}             ${BACKUP_PATH}"
        echo ""
    fi

    echo -e "  ${BOLD}Components Installed:${NC}"
    echo "    - 43 Agent definitions (core + experts + L2)"
    echo "    - Orchestrator skill + 16 documentation files"
    echo "    - 10 Rule files (security, testing, coding style)"
    echo "    - Learning system (instincts.json)"
    echo "    - 3 Template files"
    echo "    - 4 Workflow files"
    echo ""

    echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
    echo ""
    echo "  1. Ensure Claude Code CLI is installed"
    echo "     https://claude.ai/claude-code"
    echo ""
    echo "  2. Restart Claude Code or open a new session"
    echo ""
    echo "  3. Verify installation with:"
    echo "     ${CYAN}claude${NC}"
    echo "     Then type: ${CYAN}/orchestrator${NC}"
    echo ""
    echo -e "${BLUE}Documentation: ${INSTALL_PATH}/skills/orchestrator/docs/${NC}"
    echo -e "${BLUE}Changelog: ${INSTALL_PATH}/skills/orchestrator/docs/changelog.md${NC}"
    echo ""

    if [[ "$VERBOSE_MODE" == "true" ]]; then
        echo -e "${CYAN}Debug Info:${NC}"
        echo "  - Directories created: ${#CREATED_DIRS[@]}"
        echo "  - Files copied: ${#COPIED_FILES[@]}"
        echo "  - Package manager: ${PACKAGE_MANAGER}"
        echo "  - OS distribution: ${OS_DISTRO}"
        echo ""
    fi

    echo -e "${GREEN}Happy coding with Claude Orchestrator!${NC}"
    echo ""
}

# ==============================================================================
# TRAP HANDLERS
# ==============================================================================

cleanup_on_error() {
    local exit_code=$?

    if [[ $exit_code -ne 0 ]] && [[ "$ROLLBACK_NEEDED" == "true" ]]; then
        rollback
    fi

    exit $exit_code
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    # Set up error handling
    trap cleanup_on_error EXIT

    # Parse command line arguments
    parse_arguments "$@"

    # Show banner (unless silent)
    if [[ "$SILENT_MODE" != "true" ]]; then
        echo ""
        echo -e "${BOLD}Claude Orchestrator Plugin Installer v${SCRIPT_VERSION}${NC}"
        echo -e "${BLUE}============================================${NC}"
        echo ""
    fi

    # Step 1: Detect OS and architecture
    detect_os
    detect_architecture

    # Step 2: Check prerequisites
    check_bash_version
    check_python
    check_git
    check_claude_cli

    # Step 3: Setup installation path
    setup_install_path

    # Step 4: Create backup if requested
    create_backup

    # Enable rollback from this point
    ROLLBACK_NEEDED=true

    # Step 5: Create directory structure
    create_directory_structure

    # Step 6: Copy files
    copy_files

    # Step 7: Set permissions
    set_permissions

    # Step 8: Verify installation
    if ! verify_installation; then
        log_error "Installation verification failed"
        exit 1
    fi

    # Disable rollback - installation successful
    ROLLBACK_NEEDED=false

    # Step 9: Show success message
    show_success

    # Clean up backup path variable for trap
    unset BACKUP_PATH

    exit 0
}

# Run main with all arguments
main "$@"
