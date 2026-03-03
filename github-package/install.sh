#!/bin/bash

# =============================================================================
# Claude Orchestrator Plugin - Installation Script for Linux/Mac
# Repository: https://github.com/eroslifestyle/Claude-Orchestrator-Plugin
# Version: 1.0.0
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# ANSI Color Codes
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
REPO_URL="https://github.com/eroslifestyle/Claude-Orchestrator-Plugin.git"
INSTALL_DIR="$HOME/.claude"
BACKUP_DIR="$HOME/.claude_backup_$(date +%Y%m%d_%H%M%S)"
REQUIRED_COMMANDS=("git" "node" "npm")

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}${WHITE}     Claude Orchestrator Plugin - Installer for Linux/Mac      ${NC}${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_node_version() {
    node --version 2>/dev/null | sed 's/v//'
}

get_npm_version() {
    npm --version 2>/dev/null
}

# -----------------------------------------------------------------------------
# Step 1: Check Prerequisites
# -----------------------------------------------------------------------------

check_prerequisites() {
    print_step "Checking prerequisites..."
    echo ""

    local missing=()

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if command_exists "$cmd"; then
            case "$cmd" in
                "git")
                    local version=$(git --version | awk '{print $3}')
                    print_success "git version $version found"
                    ;;
                "node")
                    local version=$(get_node_version)
                    print_success "Node.js v$version found"
                    ;;
                "npm")
                    local version=$(get_npm_version)
                    print_success "npm v$version found"
                    ;;
            esac
        else
            print_error "$cmd not found"
            missing+=("$cmd")
        fi
    done

    echo ""

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing[*]}"
        echo ""
        print_info "Please install missing dependencies:"
        echo ""
        for cmd in "${missing[@]}"; do
            case "$cmd" in
                "git")
                    echo "  • git:    https://git-scm.com/downloads"
                    echo "            Debian/Ubuntu: sudo apt install git"
                    echo "            macOS: brew install git"
                    ;;
                "node")
                    echo "  • Node.js: https://nodejs.org/"
                    echo "             Debian/Ubuntu: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt install nodejs"
                    echo "             macOS: brew install node"
                    ;;
                "npm")
                    echo "  • npm:    Usually included with Node.js"
                    ;;
            esac
        done
        echo ""
        exit 1
    fi

    print_success "All prerequisites satisfied!"
    echo ""
}

# -----------------------------------------------------------------------------
# Step 2: Backup Existing Installation
# -----------------------------------------------------------------------------

backup_existing() {
    print_step "Checking for existing installation..."

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Existing ~/.claude directory found"
        echo ""

        read -p "Do you want to backup the existing installation? [Y/n]: " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Creating backup at: $BACKUP_DIR"

            # Backup specific directories and files, excluding temp files
            mkdir -p "$BACKUP_DIR"

            # Backup important config files
            if [ -f "$INSTALL_DIR/settings.json" ]; then
                cp "$INSTALL_DIR/settings.json" "$BACKUP_DIR/"
            fi

            if [ -f "$INSTALL_DIR/settings.local.json" ]; then
                cp "$INSTALL_DIR/settings.local.json" "$BACKUP_DIR/"
            fi

            # Backup memory if exists
            if [ -d "$INSTALL_DIR/memory" ]; then
                cp -r "$INSTALL_DIR/memory" "$BACKUP_DIR/"
            fi

            # Backup learnings if exists
            if [ -d "$INSTALL_DIR/learnings" ]; then
                cp -r "$INSTALL_DIR/learnings" "$BACKUP_DIR/"
            fi

            # Backup sessions if exists
            if [ -d "$INSTALL_DIR/sessions" ]; then
                cp -r "$INSTALL_DIR/sessions" "$BACKUP_DIR/"
            fi

            # Backup projects if exists
            if [ -d "$INSTALL_DIR/projects" ]; then
                cp -r "$INSTALL_DIR/projects" "$BACKUP_DIR/"
            fi

            print_success "Backup created successfully!"
        else
            print_warning "Skipping backup. Existing files will be preserved."
        fi
    else
        print_info "No existing installation found. Proceeding with fresh install."
    fi

    echo ""
}

# -----------------------------------------------------------------------------
# Step 3: Clone Repository
# -----------------------------------------------------------------------------

clone_repository() {
    print_step "Cloning repository..."

    if [ -d "$INSTALL_DIR/.git" ]; then
        print_info "Repository already cloned. Pulling latest changes..."
        cd "$INSTALL_DIR"
        git pull origin main || git pull origin master
        print_success "Repository updated!"
    else
        print_info "Cloning from: $REPO_URL"
        print_info "Target directory: $INSTALL_DIR"

        # Create parent directory if needed
        mkdir -p "$(dirname "$INSTALL_DIR")"

        # Clone the repository
        git clone "$REPO_URL" "$INSTALL_DIR"
        print_success "Repository cloned successfully!"
    fi

    cd "$INSTALL_DIR"
    echo ""
}

# -----------------------------------------------------------------------------
# Step 4: Setup Configuration Files
# -----------------------------------------------------------------------------

setup_config_files() {
    print_step "Setting up configuration files..."

    cd "$INSTALL_DIR"

    # Copy settings template if settings.json doesn't exist
    if [ ! -f "settings.json" ]; then
        if [ -f "templates/settings.template.json" ]; then
            cp "templates/settings.template.json" "settings.json"
            print_success "Created settings.json from template"
        elif [ -f "settings.template.json" ]; then
            cp "settings.template.json" "settings.json"
            print_success "Created settings.json from template"
        else
            print_warning "settings.template.json not found, skipping"
        fi
    else
        print_info "settings.json already exists, preserving"
    fi

    # Copy local settings template if settings.local.json doesn't exist
    if [ ! -f "settings.local.json" ]; then
        if [ -f "templates/settings.local.template.json" ]; then
            cp "templates/settings.local.template.json" "settings.local.json"
            print_success "Created settings.local.json from template"
        elif [ -f "settings.local.template.json" ]; then
            cp "settings.local.template.json" "settings.local.json"
            print_success "Created settings.local.json from template"
        else
            print_warning "settings.local.template.json not found, skipping"
        fi
    else
        print_info "settings.local.json already exists, preserving"
    fi

    echo ""
}

# -----------------------------------------------------------------------------
# Step 5: Create Required Directories
# -----------------------------------------------------------------------------

create_directories() {
    print_step "Creating required directories..."

    cd "$INSTALL_DIR"

    local dirs=("tmp" "sessions" "learnings" "projects" "memory")

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir/"
        else
            print_info "Directory already exists: $dir/"
        fi
    done

    # Create .gitkeep files to preserve empty directories
    for dir in "${dirs[@]}"; do
        touch "$dir/.gitkeep"
    done

    echo ""
}

# -----------------------------------------------------------------------------
# Step 6: Install MCP Server Dependencies
# -----------------------------------------------------------------------------

install_mcp_dependencies() {
    print_step "Installing MCP server dependencies..."

    cd "$INSTALL_DIR"

    # Check if plugins directory exists
    if [ -d "plugins/orchestrator-plugin" ]; then
        print_info "Found plugins/orchestrator-plugin"
        cd "plugins/orchestrator-plugin"

        # Check for package.json
        if [ -f "package.json" ]; then
            print_info "Installing npm dependencies..."

            # Install dependencies
            npm install

            # Build if build script exists
            if grep -q '"build"' package.json; then
                print_info "Building plugin..."
                npm run build
                print_success "Plugin built successfully!"
            else
                print_info "No build script found, skipping build step"
            fi

            print_success "MCP dependencies installed!"
        else
            print_warning "package.json not found in plugins/orchestrator-plugin"
        fi
    elif [ -d "plugins" ]; then
        print_info "Searching for MCP plugins..."
        for plugin_dir in plugins/*/; do
            if [ -f "$plugin_dir/package.json" ]; then
                print_info "Found plugin: $plugin_dir"
                cd "$plugin_dir"
                npm install

                if grep -q '"build"' package.json; then
                    npm run build
                fi
                cd "$INSTALL_DIR"
                print_success "Installed: $plugin_dir"
            fi
        done
    else
        print_warning "No plugins directory found, skipping MCP installation"
    fi

    echo ""
}

# -----------------------------------------------------------------------------
# Step 7: Show Completion Message
# -----------------------------------------------------------------------------

show_completion() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}${WHITE}              Installation Complete!                            ${NC}${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Installation Details:${NC}"
    echo -e "  ${WHITE}Directory:${NC} $INSTALL_DIR"
    echo -e "  ${WHITE}Repository:${NC} $REPO_URL"
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Backup Location:${NC} $BACKUP_DIR"
        echo ""
    fi

    echo -e "${CYAN}Configuration Files:${NC}"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/settings.json"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/settings.local.json"
    echo ""

    echo -e "${CYAN}Directories Created:${NC}"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/tmp/"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/sessions/"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/learnings/"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/projects/"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/memory/"
    echo ""

    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  ${WHITE}1.${NC} Edit ${WHITE}settings.json${NC} to configure Claude Code"
    echo -e "  ${WHITE}2.${NC} Edit ${WHITE}settings.local.json${NC} for local settings"
    echo -e "  ${WHITE}3.${NC} Restart Claude Code to apply changes"
    echo ""

    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/README.md"
    echo -e "  ${WHITE}•${NC} $INSTALL_DIR/docs/"
    echo ""

    echo -e "${GREEN}Happy coding with Claude Orchestrator!${NC}"
    echo ""
}

# -----------------------------------------------------------------------------
# Main Installation Flow
# -----------------------------------------------------------------------------

main() {
    print_header
    check_prerequisites
    backup_existing
    clone_repository
    setup_config_files
    create_directories
    install_mcp_dependencies
    show_completion
}

# Run main function
main "$@"
