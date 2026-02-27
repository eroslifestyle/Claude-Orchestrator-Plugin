#!/bin/bash
# =============================================================================
# Claude Orchestrator Plugin - Universal Unix Installer
# =============================================================================
# Version: 12.0
# Supports: Linux (Ubuntu, Debian, CentOS, Fedora, Arch) and macOS
# Architecture: x86_64, arm64 (Apple Silicon)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/install.sh | bash
#   OR
#   ./install.sh [OPTIONS]
#
# Options:
#   -p, --path PATH     Custom install path (default: ~/.claude)
#   -s, --silent        Silent mode (non-interactive)
#   -b, --backup        Backup existing config before overwrite
#   -f, --force         Force overwrite without prompting
#   -n, --dry-run       Show what would be done without making changes
#   -v, --verbose       Verbose output
#   -h, --help          Show help message
#   --uninstall         Remove the orchestrator plugin
#   --version           Show version information
# =============================================================================

set -e
set -o pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="12.0"
readonly SCRIPT_NAME="Claude Orchestrator Plugin"
readonly GITHUB_REPO="eroslifestyle/Claude-Orchestrator-Plugin"
readonly GITHUB_BRANCH="main"

# Default values
INSTALL_PATH="${INSTALL_PATH:-$HOME/.claude}"
SILENT="${SILENT:-false}"
BACKUP="${BACKUP:-false}"
FORCE="${FORCE:-false}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
UNINSTALL_MODE="${UNINSTALL_MODE:-false}"
REMOTE_INSTALL="false"

# OS and Architecture detection
OS_TYPE=""
OS_DISTRO=""
ARCH_TYPE=""
PACKAGE_MANAGER=""

# Tool availability
HAS_GIT="false"
HAS_PYTHON="false"
HAS_JQ="false"
PYTHON_CMD=""
DOWNLOADER=""

# Rollback tracking
declare -a CREATED_DIRS=()
declare -a COPIED_FILES=()
BACKUP_DIR=""
SOURCE_ROOT=""

# Color codes (disabled in silent mode or non-interactive terminals)
if [[ -t 1 ]] && [[ "$SILENT" != "true" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BOLD=''
    DIM=''
    NC=''
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info()    { [[ "$SILENT" != "true" ]] && echo -e "${GREEN}[INFO]${NC} $1" || true; }
log_success() { [[ "$SILENT" != "true" ]] && echo -e "${GREEN}[OK]${NC} $1" || true; }
log_warning() { [[ "$SILENT" != "true" ]] && echo -e "${YELLOW}[WARN]${NC} $1" || true; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_debug()   { [[ "$VERBOSE" == "true" ]] && echo -e "${DIM}[DEBUG]${NC} $1" || true; }
log_step()    { [[ "$SILENT" != "true" ]] && echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}" || true; }

log_header() {
    [[ "$SILENT" == "true" ]] && return
    echo ""
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD} $1 ${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    [[ "$SILENT" == "true" ]] && return
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    printf "\r${CYAN}[${GREEN}$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))${DIM}$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))${CYAN}]${NC} %3d%% - %s" "$percent" "$message"
    [[ $current -eq $total ]] && echo ""
}

# =============================================================================
# HELP AND USAGE
# =============================================================================

show_help() {
    cat << EOF
${BOLD}${SCRIPT_NAME} Installer v${SCRIPT_VERSION}${NC}

${CYAN}USAGE:${NC}
    curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | bash
    ./install.sh [OPTIONS]

${CYAN}OPTIONS:${NC}
    -p, --path PATH     Custom installation path (default: ~/.claude)
    -s, --silent        Silent mode (non-interactive)
    -b, --backup        Backup existing configuration
    -f, --force         Force overwrite without prompting
    -n, --dry-run       Show what would be done without making changes
    -v, --verbose       Verbose output for debugging
    -h, --help          Show this help message
    --uninstall         Remove the orchestrator plugin
    --version           Show version information

${CYAN}ENVIRONMENT VARIABLES:${NC}
    INSTALL_PATH        Override default installation path
    FORCE               Set to 'true' to force overwrite
    SILENT              Set to 'true' for silent mode

${CYAN}EXAMPLES:${NC}
    # Standard installation
    curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | bash

    # Custom path with backup
    ./install.sh --path /opt/claude --backup

    # Silent installation (for CI/CD)
    ./install.sh --silent --force

    # Preview installation without changes
    ./install.sh --dry-run --verbose

    # Uninstall
    ./install.sh --uninstall

${CYAN}FILES INSTALLED:${NC}
    - agents/           43+ agent definitions (core, experts, specialists)
    - skills/orchestrator/  Main orchestrator skill + docs
    - rules/            10+ coding rules files
    - learnings/        Continuous learning system
    - templates/        Task, review, integration templates
    - workflows/        Bugfix, feature, refactoring workflows
    - CLAUDE.md         Root instructions file

${CYAN}FILES EXCLUDED (never copied):${NC}
    - .credentials.json
    - .env files
    - stats-cache.json
    - history.jsonl
    - paste-cache/, debug/, backups/
    - *.tmp, temp_*

${CYAN}SUPPORTED SYSTEMS:${NC}
    - Linux: Ubuntu, Debian, CentOS, Fedora, Arch, openSUSE
    - macOS: Intel (x86_64) and Apple Silicon (arm64)

For more information: https://github.com/${GITHUB_REPO}
EOF
    exit 0
}

show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    exit 0
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_args() {
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
                SILENT="true"
                shift
                ;;
            -b|--backup)
                BACKUP="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            --uninstall)
                UNINSTALL_MODE="true"
                shift
                ;;
            --version)
                show_version
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

# =============================================================================
# SYSTEM DETECTION
# =============================================================================

detect_os() {
    log_step "Detecting operating system..."

    case "$(uname -s)" in
        Linux*)
            OS_TYPE="linux"

            # Detect distribution
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                OS_DISTRO="${ID:-unknown}"
                log_debug "Detected distro: ${NAME:-Unknown} (${VERSION_ID:-})"
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

            log_success "Linux - ${OS_DISTRO} (${PACKAGE_MANAGER})"
            ;;

        Darwin*)
            OS_TYPE="macos"
            OS_DISTRO="macos"
            PACKAGE_MANAGER="brew"
            local macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            log_success "macOS ${macos_version}"
            ;;

        *)
            log_error "Unsupported operating system: $(uname -s)"
            log_error "This installer supports Linux and macOS only"
            exit 1
            ;;
    esac

    log_debug "OS_TYPE=$OS_TYPE, OS_DISTRO=$OS_DISTRO, PACKAGE_MANAGER=$PACKAGE_MANAGER"
}

detect_architecture() {
    log_step "Detecting system architecture..."

    local arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            ARCH_TYPE="x86_64"
            log_success "x86_64 (Intel/AMD 64-bit)"
            ;;
        aarch64|arm64)
            ARCH_TYPE="arm64"
            if [[ "$OS_TYPE" == "macos" ]]; then
                log_success "arm64 (Apple Silicon)"
            else
                log_success "arm64 (ARM 64-bit)"
            fi
            ;;
        armv7l|armhf)
            ARCH_TYPE="arm32"
            log_warning "arm32 (ARM 32-bit) - limited support"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    log_debug "ARCH_TYPE=$ARCH_TYPE"
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    log_header "Checking Prerequisites"
    local missing=()
    local warnings=()

    # Check bash version (need 4+ for associative arrays)
    log_step "Checking bash version..."
    local bash_major="${BASH_VERSION%%.*}"
    if [[ $bash_major -lt 4 ]]; then
        warnings+=("Bash ${BASH_VERSION} detected. Bash 4+ recommended for full functionality.")
    else
        log_success "Bash ${BASH_VERSION}"
    fi

    # Check for curl or wget
    log_step "Checking for download tools..."
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
        log_success "curl: $(curl --version | head -1)"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
        log_success "wget: $(wget --version | head -1)"
    else
        missing+=("curl or wget (required for remote installation)")
    fi

    # Check for git (optional)
    log_step "Checking for git..."
    if command -v git &>/dev/null; then
        HAS_GIT="true"
        log_success "git: $(git --version | cut -d' ' -f3)"
    else
        HAS_GIT="false"
        warnings+=("git not found (optional, for version control features)")
    fi

    # Check for Python 3.10+
    log_step "Checking for Python..."
    if command -v python3 &>/dev/null; then
        local py_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        local py_major=$(echo "$py_version" | cut -d'.' -f1)
        local py_minor=$(echo "$py_version" | cut -d'.' -f2)

        if [[ $py_major -ge 3 ]] && [[ $py_minor -ge 10 ]]; then
            HAS_PYTHON="true"
            PYTHON_CMD="python3"
            log_success "Python $py_version"
        else
            HAS_PYTHON="true"
            PYTHON_CMD="python3"
            warnings+=("Python $py_version found. Python 3.10+ recommended.")
        fi
    elif command -v python &>/dev/null; then
        HAS_PYTHON="true"
        PYTHON_CMD="python"
        warnings+=("Using 'python' command. Python 3.10+ recommended.")
    else
        HAS_PYTHON="false"
        warnings+=("Python not found (optional, for JSON processing and MCP server)")
    fi

    # Check for jq (optional)
    log_step "Checking for jq..."
    if command -v jq &>/dev/null; then
        HAS_JQ="true"
        log_success "jq: $(jq --version)"
    else
        HAS_JQ="false"
        warnings+=("jq not found (will use Python for JSON processing)")
    fi

    # Check for Claude Code installation
    log_step "Checking for Claude Code..."
    if [[ -d "$HOME/.claude" ]]; then
        log_success "Claude Code directory found: ~/.claude"
    else
        log_info "Claude Code directory not found"
        log_info "Installation will create: $INSTALL_PATH"
    fi

    # Report warnings
    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo ""
        log_warning "Warnings:"
        for warn in "${warnings[@]}"; do
            echo -e "  ${YELLOW}-${NC} $warn"
        done
    fi

    # Report missing dependencies
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        log_error "Missing required dependencies:"
        for dep in "${missing[@]}"; do
            echo -e "  ${RED}-${NC} $dep"
        done
        exit 1
    fi

    echo ""
    log_info "Prerequisites check complete"
}

# =============================================================================
# INSTALLATION MODE DETECTION
# =============================================================================

detect_install_mode() {
    log_header "Detecting Installation Mode"

    # Check if we're running from a pipe (curl | bash)
    if [[ -p /dev/stdin ]] && [[ -z "${BASH_SOURCE[0]}" ]]; then
        REMOTE_INSTALL="true"
        log_info "Remote installation mode (curl | bash)"

        SOURCE_ROOT=$(mktemp -d)
        trap "cleanup_temp" EXIT

    elif [[ -n "${BASH_SOURCE[0]}" ]]; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        REMOTE_INSTALL="false"

        # Check if we're in a valid source directory
        if [[ -d "$script_dir/../skills/orchestrator" ]] || [[ -d "$script_dir/skills/orchestrator" ]]; then
            if [[ -d "$script_dir/../skills/orchestrator" ]]; then
                SOURCE_ROOT="$(cd "$script_dir/.." && pwd)"
            else
                SOURCE_ROOT="$script_dir"
            fi
            log_info "Local installation from: $SOURCE_ROOT"
        else
            log_warning "Script not in package directory"
            log_info "Will download from GitHub"
            REMOTE_INSTALL="true"
            SOURCE_ROOT=$(mktemp -d)
            trap "cleanup_temp" EXIT
        fi
    else
        REMOTE_INSTALL="true"
        SOURCE_ROOT=$(mktemp -d)
        trap "cleanup_temp" EXIT
    fi

    log_debug "REMOTE_INSTALL=$REMOTE_INSTALL, SOURCE_ROOT=$SOURCE_ROOT"
}

# Cleanup temporary directory
cleanup_temp() {
    if [[ -n "$SOURCE_ROOT" ]] && [[ "$REMOTE_INSTALL" == "true" ]] && [[ -d "$SOURCE_ROOT" ]]; then
        rm -rf "$SOURCE_ROOT" 2>/dev/null || true
        log_debug "Cleaned up temp directory: $SOURCE_ROOT"
    fi
}

# =============================================================================
# DOWNLOAD FUNCTIONS (for remote install)
# =============================================================================

download_file() {
    local url="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY-RUN] Would download: $url"
        return 0
    fi

    log_debug "Downloading: $url -> $dest"

    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL "$url" -o "$dest" 2>/dev/null || return 1
    else
        wget -q "$url" -O "$dest" 2>/dev/null || return 1
    fi
    return 0
}

# Download all files from GitHub
download_from_github() {
    log_header "Downloading from GitHub"

    local base_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
    local total_files=100
    local current_file=0

    # Create base directories
    mkdir -p "$SOURCE_ROOT"/{agents/{core,experts,system,config,templates,workflows,docs,tests},skills/orchestrator/docs,rules/{common,python,typescript,go},learnings,templates,workflows}

    # Root files
    local root_files=("CLAUDE.md" "VERSION.json")
    for file in "${root_files[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading $file"
        download_file "$base_url/$file" "$SOURCE_ROOT/$file" 2>/dev/null || true
    done

    # Agents - Core
    local agent_core=("analyzer.md" "coder.md" "documenter.md" "orchestrator.md" "reviewer.md" "system_coordinator.md")
    for file in "${agent_core[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading agents/core/$file"
        download_file "$base_url/agents/core/$file" "$SOURCE_ROOT/agents/core/$file" 2>/dev/null || true
    done

    # Agents - System
    local agent_system=("AGENT_REGISTRY.md" "COMMUNICATION_HUB.md" "COMPLETION_NOTIFIER.md" "DEPENDENCY_GRAPH.md" "PARALLEL_COORDINATOR.md" "PROTOCOL.md" "TASK_DECOMPOSITION.md" "TASK_TRACKER.md")
    for file in "${agent_system[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading agents/system/$file"
        download_file "$base_url/agents/system/$file" "$SOURCE_ROOT/agents/system/$file" 2>/dev/null || true
    done

    # Agents - Experts (L1)
    local agent_experts=(
        "ai_integration_expert.md" "claude_systems_expert.md" "database_expert.md"
        "devops_expert.md" "gui-super-expert.md" "integration_expert.md"
        "languages_expert.md" "mobile_expert.md" "mql_expert.md"
        "security_unified_expert.md" "tester_expert.md" "trading_strategy_expert.md"
        "architect_expert.md"
    )
    for file in "${agent_experts[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading agents/experts/$file"
        download_file "$base_url/agents/experts/$file" "$SOURCE_ROOT/agents/experts/$file" 2>/dev/null || true
    done

    # Agents - Config
    local agent_config=("routing.md" "standards.md" "circuit-breaker.json")
    for file in "${agent_config[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading agents/config/$file"
        download_file "$base_url/agents/config/$file" "$SOURCE_ROOT/agents/config/$file" 2>/dev/null || true
    done

    # Agents - additional files
    ((current_file++)); show_progress $current_file $total_files "Downloading agents/CLAUDE.md"
    download_file "$base_url/agents/CLAUDE.md" "$SOURCE_ROOT/agents/CLAUDE.md" 2>/dev/null || true
    ((current_file++)); show_progress $current_file $total_files "Downloading agents/INDEX.md"
    download_file "$base_url/agents/INDEX.md" "$SOURCE_ROOT/agents/INDEX.md" 2>/dev/null || true

    # Orchestrator skill
    local skill_files=("SKILL.md" "README.md" "CHANGELOG.md" "VERSION.json")
    for file in "${skill_files[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading skills/orchestrator/$file"
        download_file "$base_url/skills/orchestrator/$file" "$SOURCE_ROOT/skills/orchestrator/$file" 2>/dev/null || true
    done

    # Orchestrator docs
    local orchestrator_docs=(
        "README.md" "examples.md" "routing-table.md" "skills-reference.md"
        "team-patterns.md" "health-check.md" "observability.md"
        "memory-integration.md" "test-suite.md"
    )
    for file in "${orchestrator_docs[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading skills/orchestrator/docs/$file"
        download_file "$base_url/skills/orchestrator/docs/$file" "$SOURCE_ROOT/skills/orchestrator/docs/$file" 2>/dev/null || true
    done

    # Rules - common
    local rules_common=(
        "coding-style.md" "security.md" "testing.md" "git-workflow.md"
        "database.md" "api-design.md"
    )
    for file in "${rules_common[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading rules/common/$file"
        download_file "$base_url/rules/common/$file" "$SOURCE_ROOT/rules/common/$file" 2>/dev/null || true
    done

    # Rules - language specific
    for lang in python typescript go; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading rules/$lang/patterns.md"
        download_file "$base_url/rules/$lang/patterns.md" "$SOURCE_ROOT/rules/$lang/patterns.md" 2>/dev/null || true
    done

    # Rules - additional
    ((current_file++)); show_progress $current_file $total_files "Downloading rules/README.md"
    download_file "$base_url/rules/README.md" "$SOURCE_ROOT/rules/README.md" 2>/dev/null || true
    ((current_file++)); show_progress $current_file $total_files "Downloading rules/format-standard.md"
    download_file "$base_url/rules/format-standard.md" "$SOURCE_ROOT/rules/format-standard.md" 2>/dev/null || true

    # Learnings
    ((current_file++)); show_progress $current_file $total_files "Downloading learnings/instincts.json"
    download_file "$base_url/learnings/instincts.json" "$SOURCE_ROOT/learnings/instincts.json" 2>/dev/null || true
    ((current_file++)); show_progress $current_file $total_files "Downloading learnings/README.md"
    download_file "$base_url/learnings/README.md" "$SOURCE_ROOT/learnings/README.md" 2>/dev/null || true

    # Templates
    local templates=("task-template.md" "review-template.md" "integration-template.md")
    for file in "${templates[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading templates/$file"
        download_file "$base_url/templates/$file" "$SOURCE_ROOT/templates/$file" 2>/dev/null || true
    done

    # Workflows
    local workflows=("bugfix-workflow.md" "feature-workflow.md" "refactoring-workflow.md" "optimized-workflow.md")
    for file in "${workflows[@]}"; do
        ((current_file++))
        show_progress $current_file $total_files "Downloading workflows/$file"
        download_file "$base_url/workflows/$file" "$SOURCE_ROOT/workflows/$file" 2>/dev/null || true
    done

    echo ""
    log_success "Download complete"
}

# =============================================================================
# BACKUP AND ROLLBACK FUNCTIONS
# =============================================================================

create_backup() {
    if [[ "$BACKUP" != "true" ]]; then
        return 0
    fi

    if [[ ! -d "$INSTALL_PATH" ]]; then
        log_info "No existing installation to backup"
        return 0
    fi

    log_header "Creating Backup"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="${INSTALL_PATH}.backup.${timestamp}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would create backup at: $BACKUP_DIR"
        return 0
    fi

    if cp -rp "$INSTALL_PATH" "$BACKUP_DIR"; then
        log_success "Backup created: $BACKUP_DIR"
    else
        log_error "Failed to create backup"
        exit 1
    fi
}

# Rollback on failure
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
            rmdir "$dir" 2>/dev/null || true
            log_debug "Removed directory: $dir"
        fi
    done

    # Restore backup if created
    if [[ -n "$BACKUP_DIR" ]] && [[ -d "$BACKUP_DIR" ]]; then
        if [[ -d "$INSTALL_PATH" ]]; then
            rm -rf "$INSTALL_PATH"
        fi
        mv "$BACKUP_DIR" "$INSTALL_PATH"
        log_info "Backup restored from: $BACKUP_DIR"
    fi

    log_info "Rollback complete"
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Create directory structure
create_directories() {
    log_header "Creating Directory Structure"

    local dirs=(
        "$INSTALL_PATH"
        "$INSTALL_PATH/agents"
        "$INSTALL_PATH/agents/core"
        "$INSTALL_PATH/agents/experts"
        "$INSTALL_PATH/agents/system"
        "$INSTALL_PATH/agents/config"
        "$INSTALL_PATH/agents/templates"
        "$INSTALL_PATH/agents/workflows"
        "$INSTALL_PATH/agents/docs"
        "$INSTALL_PATH/agents/tests"
        "$INSTALL_PATH/agents/scripts"
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
        "$INSTALL_PATH/logs"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Exists: ${dir#$INSTALL_PATH/}"
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] Would create: ${dir#$INSTALL_PATH/}"
            else
                mkdir -p "$dir"
                CREATED_DIRS+=("$dir")
                log_success "Created: ${dir#$INSTALL_PATH/}"
            fi
        fi
    done
}

# Copy a directory with exclusions
copy_directory() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [[ ! -d "$src" ]]; then
        log_debug "Source directory not found: $src"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $name/* -> ${dest#$INSTALL_PATH/}/"
        return 0
    fi

    # Use rsync if available, otherwise cp
    if command -v rsync &>/dev/null; then
        rsync -a --exclude='.git' --exclude='*.tmp' --exclude='temp_*' \
              --exclude='.credentials.json' --exclude='.env*' \
              --exclude='stats-cache.json' --exclude='history.jsonl' \
              --exclude='paste-cache' --exclude='debug' --exclude='backups' \
              "$src/" "$dest/" 2>/dev/null
    else
        cp -r "$src/"* "$dest/" 2>/dev/null || true
        # Remove excluded files
        rm -f "$dest/.credentials.json" 2>/dev/null || true
        rm -f "$dest/.env" 2>/dev/null || true
        rm -f "$dest/stats-cache.json" 2>/dev/null || true
        rm -f "$dest/history.jsonl" 2>/dev/null || true
        rm -rf "$dest/paste-cache" 2>/dev/null || true
        rm -rf "$dest/debug" 2>/dev/null || true
        rm -rf "$dest/backups" 2>/dev/null || true
        rm -f "$dest"/*.tmp 2>/dev/null || true
        rm -rf "$dest"/temp_* 2>/dev/null || true
    fi

    # Track copied files
    while IFS= read -r -d '' file; do
        COPIED_FILES+=("$file")
    done < <(find "$dest" -type f -print0 2>/dev/null)

    log_success "Copied: $name/"
}

# Copy a single file
copy_file() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [[ ! -f "$src" ]]; then
        log_debug "Source file not found: $src"
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would copy: $name -> ${dest#$INSTALL_PATH/}"
        return 0
    fi

    cp "$src" "$dest"
    COPIED_FILES+=("$dest")
    log_success "Copied: $name"
}

# Install all files
install_files() {
    log_header "Installing Files"

    local src="$SOURCE_ROOT"

    # Root CLAUDE.md
    if [[ -f "$src/CLAUDE.md" ]]; then
        copy_file "$src/CLAUDE.md" "$INSTALL_PATH/CLAUDE.md" "CLAUDE.md"
    fi

    # VERSION.json
    if [[ -f "$src/VERSION.json" ]]; then
        copy_file "$src/VERSION.json" "$INSTALL_PATH/VERSION.json" "VERSION.json"
    fi

    # Agents directory
    log_step "Installing agents..."
    copy_directory "$src/agents/core" "$INSTALL_PATH/agents/core" "agents/core"
    copy_directory "$src/agents/experts" "$INSTALL_PATH/agents/experts" "agents/experts"
    copy_directory "$src/agents/system" "$INSTALL_PATH/agents/system" "agents/system"
    copy_directory "$src/agents/config" "$INSTALL_PATH/agents/config" "agents/config"
    copy_directory "$src/agents/templates" "$INSTALL_PATH/agents/templates" "agents/templates"
    copy_directory "$src/agents/workflows" "$INSTALL_PATH/agents/workflows" "agents/workflows"
    copy_directory "$src/agents/docs" "$INSTALL_PATH/agents/docs" "agents/docs"
    copy_directory "$src/agents/tests" "$INSTALL_PATH/agents/tests" "agents/tests"
    copy_file "$src/agents/CLAUDE.md" "$INSTALL_PATH/agents/CLAUDE.md" "agents/CLAUDE.md"
    copy_file "$src/agents/INDEX.md" "$INSTALL_PATH/agents/INDEX.md" "agents/INDEX.md"

    # Orchestrator skill
    log_step "Installing orchestrator skill..."
    copy_file "$src/skills/orchestrator/SKILL.md" "$INSTALL_PATH/skills/orchestrator/SKILL.md" "skills/orchestrator/SKILL.md"
    copy_directory "$src/skills/orchestrator/docs" "$INSTALL_PATH/skills/orchestrator/docs" "skills/orchestrator/docs"
    copy_file "$src/skills/orchestrator/README.md" "$INSTALL_PATH/skills/orchestrator/README.md" "skills/orchestrator/README.md"
    copy_file "$src/skills/orchestrator/CHANGELOG.md" "$INSTALL_PATH/skills/orchestrator/CHANGELOG.md" "skills/orchestrator/CHANGELOG.md"
    copy_file "$src/skills/orchestrator/VERSION.json" "$INSTALL_PATH/skills/orchestrator/VERSION.json" "skills/orchestrator/VERSION.json"

    # Rules
    log_step "Installing rules..."
    copy_directory "$src/rules/common" "$INSTALL_PATH/rules/common" "rules/common"
    copy_directory "$src/rules/python" "$INSTALL_PATH/rules/python" "rules/python"
    copy_directory "$src/rules/typescript" "$INSTALL_PATH/rules/typescript" "rules/typescript"
    copy_directory "$src/rules/go" "$INSTALL_PATH/rules/go" "rules/go"
    copy_file "$src/rules/README.md" "$INSTALL_PATH/rules/README.md" "rules/README.md"
    copy_file "$src/rules/format-standard.md" "$INSTALL_PATH/rules/format-standard.md" "rules/format-standard.md"

    # Learnings
    log_step "Installing learnings..."
    copy_directory "$src/learnings" "$INSTALL_PATH/learnings" "learnings"

    # Templates
    log_step "Installing templates..."
    copy_directory "$src/templates" "$INSTALL_PATH/templates" "templates"

    # Workflows
    log_step "Installing workflows..."
    copy_directory "$src/workflows" "$INSTALL_PATH/workflows" "workflows"
}

# Set file permissions
set_permissions() {
    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    log_header "Setting Permissions"

    # Set directory permissions
    find "$INSTALL_PATH" -type d -exec chmod 755 {} \; 2>/dev/null || true

    # Set file permissions
    find "$INSTALL_PATH" -type f -exec chmod 644 {} \; 2>/dev/null || true

    # Make scripts executable
    find "$INSTALL_PATH" -type f -name "*.sh" -exec chmod 755 {} \; 2>/dev/null || true
    find "$INSTALL_PATH" -type f -name "*.py" -exec chmod 755 {} \; 2>/dev/null || true

    # Secure permissions for root directory
    chmod 700 "$INSTALL_PATH" 2>/dev/null || true

    log_success "Permissions set"
}

# Configure settings.json
configure_settings() {
    log_header "Configuring Settings"

    local settings_file="$INSTALL_PATH/settings.json"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would configure: $settings_file"
        return 0
    fi

    # Create settings.json if it doesn't exist
    if [[ ! -f "$settings_file" ]]; then
        echo '{}' > "$settings_file"
        log_info "Created new settings.json"
    fi

    # Configure Agent Teams
    if [[ "$HAS_JQ" == "true" ]]; then
        local temp_file=$(mktemp)
        jq --arg key "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" --arg value "1" \
            '.env = (.env // {}) | .env[$key] = $value' \
            "$settings_file" > "$temp_file" && mv "$temp_file" "$settings_file"
        log_success "Enabled Agent Teams in settings.json"
    elif [[ "$HAS_PYTHON" == "true" ]]; then
        $PYTHON_CMD << PYEOF
import json
import sys

settings_file = "$settings_file"

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

if 'env' not in settings:
    settings['env'] = {}

settings['env']['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = "1"

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("Updated settings.json")
PYEOF
        log_success "Enabled Agent Teams in settings.json (via Python)"
    else
        log_warning "Cannot automatically configure settings.json"
        log_info "Please add to $settings_file:"
        echo ""
        echo '  "env": {'
        echo '    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"'
        echo '  }'
    fi
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_installation() {
    log_header "Verifying Installation"

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
            log_error "Missing directory: ${dir#$INSTALL_PATH/}"
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
            log_error "Missing critical file: ${file#$INSTALL_PATH/}"
            ((errors++))
        else
            log_success "${file#$INSTALL_PATH/}"
        fi
    done

    # Count installed components
    local agent_count=$(find "$INSTALL_PATH/agents" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local rule_count=$(find "$INSTALL_PATH/rules" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local template_count=$(find "$INSTALL_PATH/templates" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local workflow_count=$(find "$INSTALL_PATH/workflows" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    local doc_count=$(find "$INSTALL_PATH/skills/orchestrator/docs" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

    log_debug "Agent files: $agent_count"
    log_debug "Rule files: $rule_count"
    log_debug "Template files: $template_count"
    log_debug "Workflow files: $workflow_count"
    log_debug "Documentation files: $doc_count"

    # Validate counts
    if [[ $agent_count -lt 40 ]]; then
        log_warning "Agent count ($agent_count) lower than expected (43+)"
        ((warnings++))
    else
        log_success "agents/ ($agent_count files)"
    fi

    if [[ $rule_count -lt 8 ]]; then
        log_warning "Rule count ($rule_count) lower than expected (10+)"
        ((warnings++))
    else
        log_success "rules/ ($rule_count files)"
    fi

    if [[ $template_count -lt 2 ]]; then
        log_warning "Template count ($template_count) lower than expected (3)"
        ((warnings++))
    else
        log_success "templates/ ($template_count files)"
    fi

    if [[ $workflow_count -lt 3 ]]; then
        log_warning "Workflow count ($workflow_count) lower than expected (4)"
        ((warnings++))
    else
        log_success "workflows/ ($workflow_count files)"
    fi

    # Check settings
    if [[ -f "$INSTALL_PATH/settings.json" ]]; then
        if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$INSTALL_PATH/settings.json" 2>/dev/null; then
            log_success "Agent Teams enabled"
        else
            log_warning "Agent Teams not configured"
            ((warnings++))
        fi
    fi

    # Report results
    echo ""
    if [[ $errors -gt 0 ]]; then
        log_error "Verification failed with $errors error(s)"
        return 1
    elif [[ $warnings -gt 0 ]]; then
        log_warning "Verification completed with $warnings warning(s)"
        return 0
    else
        log_success "Installation verified successfully!"
        return 0
    fi
}

# =============================================================================
# UNINSTALL FUNCTION
# =============================================================================

uninstall() {
    log_header "Uninstalling Claude Orchestrator Plugin"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would uninstall orchestrator plugin"
        return 0
    fi

    # Ask for confirmation
    if [[ "$FORCE" != "true" ]] && [[ "$SILENT" != "true" ]]; then
        read -r -p "Are you sure you want to uninstall? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled"
            exit 0
        fi
    fi

    # Create backup before uninstall
    if [[ "$BACKUP" == "true" ]]; then
        create_backup
    fi

    # Remove orchestrator-specific files
    local items_to_remove=(
        "$INSTALL_PATH/skills/orchestrator"
        "$INSTALL_PATH/agents"
        "$INSTALL_PATH/rules"
        "$INSTALL_PATH/learnings"
        "$INSTALL_PATH/templates"
        "$INSTALL_PATH/workflows"
    )

    for item in "${items_to_remove[@]}"; do
        if [[ -e "$item" ]]; then
            rm -rf "$item"
            log_success "Removed: ${item#$INSTALL_PATH/}"
        fi
    done

    # Optionally remove CLAUDE.md (might be customized)
    if [[ -f "$INSTALL_PATH/CLAUDE.md" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            rm -f "$INSTALL_PATH/CLAUDE.md"
            log_success "Removed: CLAUDE.md"
        else
            log_info "Keeping CLAUDE.md (use --force to remove)"
        fi
    fi

    log_success "Uninstall complete"

    if [[ -n "$BACKUP_DIR" ]] && [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backup saved at: $BACKUP_DIR"
    fi
}

# =============================================================================
# POST-INSTALL
# =============================================================================

print_post_install() {
    log_header "Installation Complete"

    cat << EOF

${BOLD}${GREEN}Claude Orchestrator Plugin v${SCRIPT_VERSION} installed successfully!${NC}

${CYAN}System Information:${NC}
    OS:       ${OS_TYPE} (${OS_DISTRO})
    Arch:     ${ARCH_TYPE}
    Path:     ${INSTALL_PATH}

${CYAN}To use the orchestrator:${NC}

1. ${BOLD}Restart Claude Code${NC} (if running) to load the new skill

2. ${BOLD}Verify installation:${NC}
   ls -la $INSTALL_PATH/skills/orchestrator/

3. ${BOLD}Use the orchestrator${NC} by typing:
   /orchestrator <your request>

${CYAN}Quick Test:${NC}
   /orchestrator analyze current directory structure

${CYAN}Documentation:${NC}
   $INSTALL_PATH/skills/orchestrator/README.md
   $INSTALL_PATH/skills/orchestrator/docs/

${CYAN}Configuration:${NC}
   Agent Teams: Enabled in settings.json

${CYAN}Backup:${NC}
EOF

    if [[ -n "$BACKUP_DIR" ]] && [[ -d "$BACKUP_DIR" ]]; then
        echo "   $BACKUP_DIR"
    else
        echo "   Not created (use --backup to enable)"
    fi

    cat << EOF

${CYAN}Support:${NC}
   https://github.com/${GITHUB_REPO}

${GREEN}${BOLD}Happy orchestrating!${NC}

EOF
}

# =============================================================================
# TRAP HANDLERS
# =============================================================================

cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]] && [[ "$DRY_RUN" != "true" ]] && [[ "$UNINSTALL_MODE" != "true" ]]; then
        rollback
    fi
    exit $exit_code
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Set up error handling
    trap cleanup_on_error EXIT

    # Parse arguments
    parse_args "$@"

    # Print banner
    echo ""
    echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}${BOLD}║       ${SCRIPT_NAME} v${SCRIPT_VERSION}                        ║${NC}"
    echo -e "${MAGENTA}${BOLD}║       Universal Unix Installer                                       ║${NC}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Handle uninstall
    if [[ "$UNINSTALL_MODE" == "true" ]]; then
        uninstall
        exit 0
    fi

    # Show configuration
    log_info "Install path: $INSTALL_PATH"
    log_info "Silent mode: $SILENT"
    log_info "Backup: $BACKUP"
    log_info "Force: $FORCE"
    log_info "Dry run: $DRY_RUN"
    echo ""

    # Detection phase
    detect_os
    detect_architecture
    check_prerequisites
    detect_install_mode

    # Download phase (if remote)
    if [[ "$REMOTE_INSTALL" == "true" ]]; then
        download_from_github
    fi

    # Installation phase
    create_backup
    create_directories
    install_files
    set_permissions
    configure_settings

    # Verification phase
    if [[ "$DRY_RUN" != "true" ]]; then
        if ! verify_installation; then
            log_error "Verification failed"
            exit 1
        fi
        print_post_install
    else
        log_header "Dry Run Complete"
        log_info "No changes were made."
        log_info "Run without --dry-run to install."
    fi

    # Disable trap on success
    trap - EXIT
}

# Run main function
main "$@"
