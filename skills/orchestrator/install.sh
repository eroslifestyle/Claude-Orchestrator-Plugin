#!/bin/bash
# =============================================================================
# Claude Orchestrator Plugin - macOS/Linux Installer
# =============================================================================
# Version: 10.2
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/eroslifestyle/Claude-Orchestrator-Plugin/main/install.sh | bash
#   OR
#   ./install.sh [--force] [--path /custom/path]
#
# Options:
#   --force, -f     Force overwrite existing files (skip backups)
#   --path, -p      Custom installation path (default: ~/.claude)
#   --help, -h      Show this help message
#   --dry-run       Show what would be done without making changes
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly SCRIPT_VERSION="10.2"
readonly GITHUB_REPO="eroslifestyle/Claude-Orchestrator-Plugin"
readonly GITHUB_BRANCH="main"

# Default values (can be overridden by env vars or args)
INSTALL_PATH="${INSTALL_PATH:-$HOME/.claude}"
FORCE="${FORCE:-false}"
DRY_RUN="${DRY_RUN:-false}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print colored message
print_color() {
    local color="$1"
    shift
    printf "${color}%s${NC}\n" "$*"
}

print_info()    { print_color "$BLUE" "[INFO] $*"; }
print_success() { print_color "$GREEN" "[OK] $*"; }
print_warning() { print_color "$YELLOW" "[WARN] $*"; }
print_error()   { print_color "$RED" "[ERROR] $*"; }
print_step()    { print_color "$CYAN" "==>"; print_color "$BOLD" "$*"; }
print_header()  {
    printf "\n${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    print_color "$MAGENTA$BOLD" "$*"
    printf "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
}

# Show usage
show_help() {
    cat << EOF
Claude Orchestrator Plugin Installer v${SCRIPT_VERSION}

USAGE:
    curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | bash
    ./install.sh [OPTIONS]

OPTIONS:
    -f, --force      Force overwrite existing files (skip backups)
    -p, --path PATH  Custom installation path (default: ~/.claude)
    -n, --dry-run    Show what would be done without making changes
    -h, --help       Show this help message

ENVIRONMENT VARIABLES:
    INSTALL_PATH     Override default installation path
    FORCE            Set to 'true' to force overwrite

EXAMPLES:
    # Standard installation
    curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | bash

    # Custom path
    INSTALL_PATH=/opt/claude ./install.sh

    # Force overwrite
    ./install.sh --force

    # Dry run to see what would happen
    ./install.sh --dry-run

EOF
    exit 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                FORCE="true"
                shift
                ;;
            -p|--path)
                INSTALL_PATH="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

# Check if running as root (not recommended)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root is not recommended!"
        print_info "Consider running as a regular user."
        if [[ "$FORCE" != "true" ]]; then
            read -r -p "Continue anyway? [y/N] " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"
    local missing=()

    # Check bash version (need 4+ for associative arrays)
    print_info "Checking bash version..."
    local bash_version="${BASH_VERSION%%.*}"
    if [[ $bash_version -lt 4 ]]; then
        print_warning "Bash version ${BASH_VERSION} detected. Bash 4+ recommended."
    else
        print_success "Bash ${BASH_VERSION}"
    fi

    # Check for curl or wget
    print_info "Checking for download tools..."
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
        print_success "curl found: $(curl --version | head -1)"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
        print_success "wget found: $(wget --version | head -1)"
    else
        missing+=("curl or wget")
    fi

    # Check for git (optional, for local installs)
    if command -v git &>/dev/null; then
        print_success "git found: $(git --version)"
        HAS_GIT="true"
    else
        print_warning "git not found (optional for local development)"
        HAS_GIT="false"
    fi

    # Check for jq (optional, for JSON processing)
    if command -v jq &>/dev/null; then
        print_success "jq found: $(jq --version)"
        HAS_JQ="true"
    else
        print_warning "jq not found (will use Python for JSON)"
        HAS_JQ="false"
    fi

    # Check for Python (fallback for JSON)
    if command -v python3 &>/dev/null; then
        print_success "Python3 found: $(python3 --version)"
        HAS_PYTHON="true"
    elif command -v python &>/dev/null; then
        print_success "Python found: $(python --version)"
        HAS_PYTHON="true"
    else
        HAS_PYTHON="false"
    fi

    # Check if Claude Code is installed
    print_info "Checking for Claude Code..."
    if [[ -d "$HOME/.claude" ]]; then
        print_success "Claude Code directory found at ~/.claude"
    else
        print_warning "Claude Code directory not found at ~/.claude"
        print_info "Installation will create it."
    fi

    # Report missing dependencies
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing required dependencies:"
        for dep in "${missing[@]}"; do
            print_error "  - $dep"
        done
        exit 1
    fi
}

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Detect if running from curl|bash (remote) or local script
detect_install_mode() {
    print_header "Detecting Installation Mode"

    # Check if we're running from a pipe (curl | bash)
    if [[ -p /dev/stdin ]] && [[ -z "$BASH_SOURCE" ]]; then
        REMOTE_INSTALL="true"
        print_info "Remote installation detected (curl | bash)"

        # Need to download files from GitHub
        SCRIPT_DIR=$(mktemp -d)
        trap "cleanup_temp" EXIT
    elif [[ -n "$BASH_SOURCE" ]]; then
        # Get the directory where this script is located
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        REMOTE_INSTALL="false"

        # Check if we're in the orchestrator directory
        if [[ -f "$SCRIPT_DIR/SKILL.md" ]]; then
            print_info "Local installation from: $SCRIPT_DIR"
        else
            print_warning "Script not in orchestrator directory"
            print_info "Will download from GitHub"
            REMOTE_INSTALL="true"
            SCRIPT_DIR=$(mktemp -d)
            trap "cleanup_temp" EXIT
        fi
    else
        REMOTE_INSTALL="true"
        SCRIPT_DIR=$(mktemp -d)
        trap "cleanup_temp" EXIT
    fi
}

# Cleanup temporary directory
cleanup_temp() {
    if [[ -n "$SCRIPT_DIR" ]] && [[ "$REMOTE_INSTALL" == "true" ]] && [[ -d "$SCRIPT_DIR" ]]; then
        rm -rf "$SCRIPT_DIR"
    fi
}

# =============================================================================
# DOWNLOAD FUNCTIONS
# =============================================================================

# Download file from URL
download_file() {
    local url="$1"
    local dest="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would download: $url -> $dest"
        return 0
    fi

    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL "$url" -o "$dest"
    else
        wget -q "$url" -O "$dest"
    fi
}

# Download directory contents from GitHub
download_from_github() {
    print_header "Downloading from GitHub"

    local base_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"

    # Files and directories to download
    local files=(
        "SKILL.md"
        "README.md"
        "CHANGELOG.md"
        "VERSION.json"
    )

    local dirs=(
        "agents"
        "docs"
    )

    # Download individual files
    for file in "${files[@]}"; do
        print_info "Downloading $file..."
        download_file "$base_url/$file" "$SCRIPT_DIR/$file"
    done

    # For directories, we need the GitHub API to list files
    # Simplified approach: download key files we know exist
    mkdir -p "$SCRIPT_DIR/agents"

    # Download agents system files
    local agent_system_files=(
        "AGENT_REGISTRY.md"
        "COMMUNICATION_HUB.md"
        "COMPLETION_NOTIFIER.md"
        "DEPENDENCY_GRAPH.md"
        "PARALLEL_COORDINATOR.md"
        "PROTOCOL.md"
        "TASK_DECOMPOSITION.md"
        "TASK_TRACKER.md"
    )

    mkdir -p "$SCRIPT_DIR/agents/system"
    for file in "${agent_system_files[@]}"; do
        download_file "$base_url/agents/system/$file" "$SCRIPT_DIR/agents/system/$file" 2>/dev/null || true
    done

    # Download agent core files
    local agent_core_files=(
        "analyzer.md"
        "coder.md"
        "documenter.md"
        "orchestrator.md"
        "reviewer.md"
        "system_coordinator.md"
    )

    mkdir -p "$SCRIPT_DIR/agents/core"
    for file in "${agent_core_files[@]}"; do
        download_file "$base_url/agents/core/$file" "$SCRIPT_DIR/agents/core/$file" 2>/dev/null || true
    done

    # Download CLAUDE.md for agents
    download_file "$base_url/agents/CLAUDE.md" "$SCRIPT_DIR/agents/CLAUDE.md" 2>/dev/null || true
    download_file "$base_url/agents/INDEX.md" "$SCRIPT_DIR/agents/INDEX.md" 2>/dev/null || true

    # Download config files
    mkdir -p "$SCRIPT_DIR/agents/config"
    download_file "$base_url/agents/config/routing.md" "$SCRIPT_DIR/agents/config/routing.md" 2>/dev/null || true
    download_file "$base_url/agents/config/standards.md" "$SCRIPT_DIR/agents/config/standards.md" 2>/dev/null || true
    download_file "$base_url/agents/config/circuit-breaker.json" "$SCRIPT_DIR/agents/config/circuit-breaker.json" 2>/dev/null || true

    # Download expert agents
    local expert_files=(
        "ai_integration_expert.md"
        "claude_systems_expert.md"
        "database_expert.md"
        "devops_expert.md"
        "gui-super-expert.md"
        "integration_expert.md"
        "mobile_expert.md"
        "mql_expert.md"
        "security_unified_expert.md"
        "trading_strategy_expert.md"
        "languages_expert.md"
        "tester_expert.md"
        "architect_expert.md"
    )

    mkdir -p "$SCRIPT_DIR/agents/experts"
    for file in "${expert_files[@]}"; do
        download_file "$base_url/agents/experts/$file" "$SCRIPT_DIR/agents/experts/$file" 2>/dev/null || true
    done

    # Download templates
    mkdir -p "$SCRIPT_DIR/agents/templates"
    download_file "$base_url/agents/templates/task.md" "$SCRIPT_DIR/agents/templates/task.md" 2>/dev/null || true
    download_file "$base_url/agents/templates/review.md" "$SCRIPT_DIR/agents/templates/review.md" 2>/dev/null || true
    download_file "$base_url/agents/templates/integration.md" "$SCRIPT_DIR/agents/templates/integration.md" 2>/dev/null || true

    # Download workflows
    mkdir -p "$SCRIPT_DIR/agents/workflows"
    download_file "$base_url/agents/workflows/bugfix.md" "$SCRIPT_DIR/agents/workflows/bugfix.md" 2>/dev/null || true
    download_file "$base_url/agents/workflows/feature.md" "$SCRIPT_DIR/agents/workflows/feature.md" 2>/dev/null || true
    download_file "$base_url/agents/workflows/refactoring.md" "$SCRIPT_DIR/agents/workflows/refactoring.md" 2>/dev/null || true

    # Download docs
    mkdir -p "$SCRIPT_DIR/docs"
    local doc_files=(
        "examples.md"
        "routing-table.md"
        "skills-reference.md"
        "team-patterns.md"
        "health-check.md"
        "observability.md"
        "memory-integration.md"
        "test-suite.md"
    )
    for file in "${doc_files[@]}"; do
        download_file "$base_url/docs/$file" "$SCRIPT_DIR/docs/$file" 2>/dev/null || true
    done

    print_success "Download complete"
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Create directory structure
create_directories() {
    print_header "Creating Directory Structure"

    local dirs=(
        "$INSTALL_PATH"
        "$INSTALL_PATH/skills"
        "$INSTALL_PATH/skills/orchestrator"
        "$INSTALL_PATH/skills/orchestrator/agents"
        "$INSTALL_PATH/skills/orchestrator/docs"
        "$INSTALL_PATH/agents"
        "$INSTALL_PATH/logs"
        "$INSTALL_PATH/tasks"
        "$INSTALL_PATH/teams"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_success "Directory exists: $dir"
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would create: $dir"
            else
                mkdir -p "$dir"
                print_success "Created: $dir"
            fi
        fi
    done
}

# Backup existing files
backup_files() {
    if [[ "$FORCE" == "true" ]]; then
        print_info "Force mode: skipping backups"
        return
    fi

    print_header "Backing Up Existing Files"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$INSTALL_PATH/backups/orchestrator_$timestamp"

    # Directories to backup
    local dirs_to_backup=(
        "$INSTALL_PATH/skills/orchestrator"
        "$INSTALL_PATH/agents/agents"
    )

    local backed_up=false

    for dir in "${dirs_to_backup[@]}"; do
        if [[ -d "$dir" ]] && [[ "$(ls -A "$dir" 2>/dev/null)" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would backup: $dir"
                backed_up=true
            else
                mkdir -p "$backup_dir"
                local dir_name=$(basename "$dir")
                cp -r "$dir" "$backup_dir/$dir_name"
                print_success "Backed up: $dir -> $backup_dir/$dir_name"
                backed_up=true
            fi
        fi
    done

    if [[ "$backed_up" == "true" ]]; then
        print_info "Backup location: $backup_dir"
    else
        print_info "No existing files to backup"
    fi
}

# Copy orchestrator skill files
install_skill_files() {
    print_header "Installing Orchestrator Skill"

    local dest="$INSTALL_PATH/skills/orchestrator"

    # Main files
    local main_files=(
        "SKILL.md"
        "README.md"
        "CHANGELOG.md"
        "VERSION.json"
    )

    for file in "${main_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: $file -> $dest/$file"
            else
                cp "$SCRIPT_DIR/$file" "$dest/$file"
                print_success "Installed: $file"
            fi
        fi
    done

    # Copy agents directory
    if [[ -d "$SCRIPT_DIR/agents" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_info "[DRY-RUN] Would copy: agents/* -> $dest/agents/"
        else
            cp -r "$SCRIPT_DIR/agents/"* "$dest/agents/" 2>/dev/null || true
            print_success "Installed: agents directory"
        fi
    fi

    # Copy docs directory
    if [[ -d "$SCRIPT_DIR/docs" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_info "[DRY-RUN] Would copy: docs/* -> $dest/docs/"
        else
            cp -r "$SCRIPT_DIR/docs/"* "$dest/docs/" 2>/dev/null || true
            print_success "Installed: docs directory"
        fi
    fi
}

# Copy agent files to ~/.claude/agents/agents/
install_agent_files() {
    print_header "Installing Agent Definitions"

    local dest="$INSTALL_PATH/agents/agents"

    # Create dest if needed
    if [[ ! -d "$dest" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_info "[DRY-RUN] Would create: $dest"
        else
            mkdir -p "$dest"
        fi
    fi

    # Copy from skills/orchestrator/agents to agents/agents
    local src="$INSTALL_PATH/skills/orchestrator/agents"

    if [[ -d "$src" ]]; then
        # Copy core agents
        if [[ -d "$src/core" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: core agents"
            else
                cp -r "$src/core" "$dest/" 2>/dev/null || true
                print_success "Installed: core agents"
            fi
        fi

        # Copy expert agents
        if [[ -d "$src/experts" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: expert agents"
            else
                cp -r "$src/experts" "$dest/" 2>/dev/null || true
                print_success "Installed: expert agents"
            fi
        fi

        # Copy system files
        if [[ -d "$src/system" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: system files"
            else
                cp -r "$src/system" "$dest/" 2>/dev/null || true
                print_success "Installed: system files"
            fi
        fi

        # Copy config files
        if [[ -d "$src/config" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: config files"
            else
                cp -r "$src/config" "$dest/" 2>/dev/null || true
                print_success "Installed: config files"
            fi
        fi

        # Copy templates
        if [[ -d "$src/templates" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: templates"
            else
                cp -r "$src/templates" "$dest/" 2>/dev/null || true
                print_success "Installed: templates"
            fi
        fi

        # Copy workflows
        if [[ -d "$src/workflows" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "[DRY-RUN] Would copy: workflows"
            else
                cp -r "$src/workflows" "$dest/" 2>/dev/null || true
                print_success "Installed: workflows"
            fi
        fi

        # Copy CLAUDE.md and INDEX.md
        if [[ -f "$src/CLAUDE.md" ]]; then
            cp "$src/CLAUDE.md" "$dest/" 2>/dev/null || true
        fi
        if [[ -f "$src/INDEX.md" ]]; then
            cp "$src/INDEX.md" "$dest/" 2>/dev/null || true
        fi
    fi
}

# Configure settings.json for Agent Teams
configure_settings() {
    print_header "Configuring Claude Code Settings"

    local settings_file="$INSTALL_PATH/settings.json"

    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "[DRY-RUN] Would configure: $settings_file"
        return
    fi

    # Check if settings.json exists
    if [[ ! -f "$settings_file" ]]; then
        print_info "Creating new settings.json..."
        echo '{}' > "$settings_file"
    fi

    # Check if we have jq
    if [[ "$HAS_JQ" == "true" ]]; then
        # Use jq to update settings
        local temp_file=$(mktemp)

        jq --arg key "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" --arg value "1" '
            .env = (.env // {}) |
            .env[$key] = $value
        ' "$settings_file" > "$temp_file" && mv "$temp_file" "$settings_file"

        print_success "Updated settings.json with Agent Teams enabled"

    elif [[ "$HAS_PYTHON" == "true" ]]; then
        # Use Python as fallback
        python3 << PYEOF
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

print("Updated settings.json with Agent Teams enabled")
PYEOF
        print_success "Updated settings.json via Python"

    else
        # Manual fallback - check if already configured
        if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$settings_file" 2>/dev/null; then
            print_success "Agent Teams already configured"
        else
            print_warning "Cannot automatically configure settings.json"
            print_info "Please add this to $settings_file:"
            echo ""
            echo '  "env": {'
            echo '    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"'
            echo '  }'
            echo ""
        fi
    fi
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    local errors=0
    local warnings=0

    # Check skill directory
    if [[ -d "$INSTALL_PATH/skills/orchestrator" ]]; then
        print_success "Skill directory exists"
    else
        print_error "Skill directory missing"
        ((errors++))
    fi

    # Check SKILL.md
    if [[ -f "$INSTALL_PATH/skills/orchestrator/SKILL.md" ]]; then
        print_success "SKILL.md installed"
    else
        print_error "SKILL.md missing"
        ((errors++))
    fi

    # Check agents directory
    if [[ -d "$INSTALL_PATH/skills/orchestrator/agents" ]]; then
        print_success "Agents directory installed"
    else
        print_warning "Agents directory missing"
        ((warnings++))
    fi

    # Check Agent Teams configuration
    if [[ -f "$INSTALL_PATH/settings.json" ]]; then
        if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$INSTALL_PATH/settings.json" 2>/dev/null; then
            print_success "Agent Teams configured"
        else
            print_warning "Agent Teams not configured"
            ((warnings++))
        fi
    else
        print_warning "settings.json not found"
        ((warnings++))
    fi

    # Summary
    echo ""
    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            print_success "Installation verified successfully!"
        else
            print_warning "Installation complete with $warnings warning(s)"
        fi
    else
        print_error "Installation completed with $errors error(s) and $warnings warning(s)"
        return 1
    fi
}

# Print post-install instructions
print_post_install() {
    print_header "Post-Installation Instructions"

    cat << EOF

${BOLD}Orchestrator Plugin v${SCRIPT_VERSION} installed successfully!${NC}

${CYAN}To use the orchestrator:${NC}

1. ${BOLD}Restart Claude Code${NC} (if running) to load the new skill

2. ${BOLD}Verify installation${NC} by checking:
   - Skill: ${INSTALL_PATH}/skills/orchestrator/SKILL.md
   - Agents: ${INSTALL_PATH}/agents/agents/

3. ${BOLD}Use the orchestrator${BOLD} by typing:
   /orchestrator <your request>

4. ${BOLD}Enable Agent Teams${NC} (optional, for multi-agent):
   - Already configured in settings.json
   - Restart Claude Code to activate

${CYAN}Quick Test:${NC}
   /orchestrator analyze current directory structure

${CYAN}Documentation:${NC}
   ${INSTALL_PATH}/skills/orchestrator/README.md
   ${INSTALL_PATH}/skills/orchestrator/docs/

${CYAN}Support:${NC}
   https://github.com/${GITHUB_REPO}

${GREEN}${BOLD}Happy orchestrating!${NC}

EOF
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse arguments first
    parse_args "$@"

    # Print banner
    echo ""
    printf "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${MAGENTA}${BOLD}║       Claude Orchestrator Plugin Installer v%-5s                   ║${NC}\n" "$SCRIPT_VERSION"
    printf "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""

    print_info "Install path: $INSTALL_PATH"
    print_info "Force mode: $FORCE"
    print_info "Dry run: $DRY_RUN"
    echo ""

    # Run installation steps
    check_root
    check_prerequisites
    detect_install_mode

    if [[ "$REMOTE_INSTALL" == "true" ]]; then
        download_from_github
    fi

    create_directories
    backup_files
    install_skill_files
    install_agent_files
    configure_settings

    if [[ "$DRY_RUN" != "true" ]]; then
        verify_installation
        print_post_install
    else
        print_header "Dry Run Complete"
        print_info "No changes were made. Run without --dry-run to install."
    fi
}

# Run main function
main "$@"
