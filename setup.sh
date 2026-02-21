#!/bin/bash
# ====================================================================
# Claude Orchestrator V10.1 ULTRA - Unix/Mac Installer
# ====================================================================
# Version: 10.1.0
# Purpose: Complete Unix/Mac installer for the Claude Orchestrator multi-agent system.
#          Supports bash and zsh with automatic component selection.
# ====================================================================
#
# Usage:
#   ./setup.sh                          # Interactive installation
#   ./setup.sh --silent --components 1,2,3  # Silent mode
#   ./setup.sh --force                  # Force overwrite existing files
#   ./setup.sh --help                   # Show help
#
# Requirements:
#   - bash 4.0+ or zsh 5.0+
#   - Claude Code installed (~/.claude/)
#   - Write permissions to home directory
#
# ====================================================================

set -e

# ====================================================================
# CONFIGURATION
# ====================================================================
ORCHESTRATOR_VERSION="10.1.0"
ORCHESTRATOR_CHANNEL="stable"
REPO_URL="https://github.com/eroslifestyle/Claude-Orchestrator-Plugin"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$HOME/.claude/skills/orchestrator"
AGENTS_DIR="$HOME/.claude/agents"
ORCHESTRATOR_DIR="$HOME/.claude/orchestrator"

# Detect shell
SHELL_RC=""
SHELL_NAME=""
if [[ -n "$ZSH_VERSION" ]]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [[ -n "$BASH_VERSION" ]]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    SHELL_RC="$HOME/.profile"
    SHELL_NAME="sh"
fi

# Command line arguments
SILENT=false
FORCE=false
COMPONENTS="1,2,3"

# Component names (associative array simulation)
COMPONENT_1_NAME="Core (skills + agents)"
COMPONENT_2_NAME="Bash/Zsh Profile Integration"
COMPONENT_3_NAME="Settings Templates"
COMPONENT_4_NAME="MCP Plugin"

# Installation results
FILES_COPIED=0
FILES_SKIPPED=0
INSTALLED_COMPONENTS=()

# Colors (disable if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    GRAY='\033[0;90m'
    DARKGRAY='\033[0;37m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    CYAN=''
    GRAY=''
    DARKGRAY=''
    NC=''
fi

# ====================================================================
# FUNCTION: show_help
# ====================================================================
show_help() {
    cat << EOF
Claude Orchestrator V${ORCHESTRATOR_VERSION} - Unix/Mac Installer

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    -s, --silent           Run in silent mode with default component selection
    -f, --force            Force overwrite existing files without prompting
    -c, --components LIST  Comma-separated list of components to install
                           1 = Core (skills + agents) - REQUIRED
                           2 = Bash/Zsh Profile Integration (cca/ccg commands)
                           3 = Settings Templates (settings-anthropic.json, settings-glm.json)
                           4 = MCP Plugin (if available)
    -h, --help             Show this help message

EXAMPLES:
    ./setup.sh                           Interactive installation
    ./setup.sh --silent --components 1,2,3   Silent with specified components
    ./setup.sh --force                   Force overwrite existing files

REQUIREMENTS:
    - bash 4.0+ or zsh 5.0+
    - Claude Code installed (~/.claude/)
    - Write permissions to home directory

EOF
    exit 0
}

# ====================================================================
# FUNCTION: parse_arguments
# ====================================================================
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--silent)
                SILENT=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -c|--components)
                COMPONENTS="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo -e "${RED}[ERROR] Unknown option: $1${NC}"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
}

# ====================================================================
# FUNCTION: show_banner
# ====================================================================
show_banner() {
    clear 2>/dev/null || true

    cat << EOF

  ██████╗ ██████╗  ██████╗ ██████╗ ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗
 ██╔════╝██╔═══██╗██╔════╝██╔═══██╗╚██╗██╔╝██║   ██║██╔══██╗██╔════╝██╔══██╗
 ██║     ██║   ██║██║     ██║   ██║ ╚███╔╝ ██║   ██║██║  ██║█████╗  ██████╔╝
 ██║     ██║   ██║██║     ██║   ██║ ██╔██╗ ██║   ██║██║  ██║██╔══╝  ██╔══██╗
 ╚██████╗╚██████╔╝╚██████╗╚██████╔╝██╔╝ ██╗╚██████╔╝██████╔╝███████╗██║  ██║
  ╚═════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

                ORCHESTRATOR V${ORCHESTRATOR_VERSION} ULTRA
                FULLY INTEGRATED EDITION - UNIX/MAC INSTALLER

EOF

    echo -e "${GRAY}  Repository: ${WHITE}${REPO_URL}${NC}"
    echo -e "${GRAY}  Installing: ${GREEN}Version ${ORCHESTRATOR_VERSION} (${ORCHESTRATOR_CHANNEL})${NC}"
    echo ""
    echo -e "${DARKGRAY}  $(printf '=%.0s' {1..60})${NC}"
    echo ""
}

# ====================================================================
# FUNCTION: check_prerequisites
# ====================================================================
check_prerequisites() {
    echo -e "${CYAN}[Prerequisites Check]${NC}"
    echo ""

    local all_passed=true

    # 1. Bash/Zsh Version
    local shell_version=""
    local version_ok=false

    if [[ -n "$ZSH_VERSION" ]]; then
        shell_version="zsh $ZSH_VERSION"
        # zsh 5.0+ required
        [[ "$ZSH_VERSION" =~ ^([0-9]+)\. ]] && [[ ${BASH_REMATCH[1]} -ge 5 ]] && version_ok=true
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_version="bash $BASH_VERSION"
        # bash 4.0+ required
        [[ "$BASH_VERSION" =~ ^([0-9]+)\. ]] && [[ ${BASH_REMATCH[1]} -ge 4 ]] && version_ok=true
    else
        shell_version="unknown shell"
    fi

    if [[ "$version_ok" == "true" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Shell Version: ${shell_version}"
    else
        echo -e "  ${YELLOW}[WARN]${NC} Shell Version: ${shell_version} (may have compatibility issues)"
    fi

    # 2. Claude Code installed
    if [[ -d "$CLAUDE_DIR" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Claude Code Directory: ${CLAUDE_DIR}"
    else
        echo -e "  ${YELLOW}[WARN]${NC} Claude Code Directory: Not found"
        echo -e "        ${DARKGRAY}Will be created during installation.${NC}"
    fi

    # 3. Write permissions
    local can_write=false
    local test_dir="$CLAUDE_DIR"
    local test_file=""

    # Try to create directory if it doesn't exist
    mkdir -p "$test_dir" 2>/dev/null || true

    # Try to write a test file
    test_file="$test_dir/.write_test_$$"
    if touch "$test_file" 2>/dev/null; then
        rm -f "$test_file" 2>/dev/null
        can_write=true
    fi

    if [[ "$can_write" == "true" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Write Permission: Granted"
    else
        echo -e "  ${RED}[ERROR]${NC} Write Permission: Denied"
        all_passed=false
    fi

    # 4. Git installed (optional)
    if command -v git &>/dev/null; then
        local git_version=$(git --version 2>/dev/null | cut -d' ' -f3)
        echo -e "  ${GREEN}[OK]${NC} Git: ${git_version} (optional)"
    else
        echo -e "  ${DARKGRAY}[SKIP]${NC} Git: Not installed (optional)"
    fi

    # 5. Required tools
    local required_tools=("cp" "mkdir" "cat" "sed")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        echo -e "  ${GREEN}[OK]${NC} Required Tools: All present"
    else
        echo -e "  ${RED}[ERROR]${NC} Missing Tools: ${missing_tools[*]}"
        all_passed=false
    fi

    echo ""

    if [[ "$all_passed" != "true" ]]; then
        echo -e "${RED}[ERROR] Prerequisites not met. Please resolve the issues above.${NC}"
        exit 1
    fi
}

# ====================================================================
# FUNCTION: get_component_selection
# ====================================================================
get_component_selection() {
    echo -e "${CYAN}[Component Selection]${NC}"
    echo ""
    echo -e "  Available Components:"
    echo ""
    echo -e "  ${GREEN}[1] Core Only (skills + agents)${DARKGRAY} - REQUIRED${NC}"
    echo -e "  [2] Bash/Zsh Profile Integration (cca/ccg commands)"
    echo -e "  [3] Settings Templates (settings-anthropic.json, settings-glm.json)"
    echo -e "  ${DARKGRAY}[4] MCP Plugin (if available)${NC}"
    echo ""

    local selected=()

    if [[ "$SILENT" == "true" ]]; then
        echo -e "  ${YELLOW}Silent Mode: Using components [${COMPONENTS}]${NC}"
        IFS=',' read -ra selected <<< "$COMPONENTS"
    else
        echo -ne "  ${CYAN}Enter components to install (comma-separated, default=1,2,3): ${NC}"
        read -r input

        if [[ -z "$input" ]]; then
            selected=(1 2 3)
        else
            IFS=',' read -ra selected <<< "$input"
        fi
    fi

    # Trim whitespace and convert to numbers
    selected=($(for s in "${selected[@]}"; do echo "$s" | tr -d '[:space:]'; done))

    # Always include Core (1) - it's required
    if [[ ! " ${selected[*]} " =~ " 1 " ]]; then
        echo -e "  ${YELLOW}[INFO] Core component is required. Adding [1] to selection.${NC}"
        selected=(1 "${selected[@]}")
    fi

    # Validate and deduplicate
    local valid=()
    for comp in "${selected[@]}"; do
        if [[ "$comp" =~ ^[1-4]$ ]] && [[ ! " ${valid[*]} " =~ " $comp " ]]; then
            valid+=("$comp")
        fi
    done

    # Sort
    IFS=$'\n' valid=($(sort -nu <<<"${valid[*]}")); unset IFS

    # Display selection
    echo ""
    echo -ne "  Selected Components: "
    local names=()
    for comp in "${valid[@]}"; do
        case "$comp" in
            1) names+=("$COMPONENT_1_NAME") ;;
            2) names+=("$COMPONENT_2_NAME") ;;
            3) names+=("$COMPONENT_3_NAME") ;;
            4) names+=("$COMPONENT_4_NAME") ;;
        esac
    done
    echo -e "${GREEN}$(IFS=', '; echo "${names[*]}")${NC}"
    echo ""

    SELECTED_COMPONENTS=("${valid[@]}")
}

# ====================================================================
# FUNCTION: install_core_files
# ====================================================================
install_core_files() {
    echo -e "${CYAN}[Installing Core Files]${NC}"
    echo ""

    local skills_count=0
    local agents_count=0

    # Create directories
    for dir in "$SKILLS_DIR" "$AGENTS_DIR" "$ORCHESTRATOR_DIR"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo -e "  ${DARKGRAY}Created: $dir${NC}"
        fi
    done

    # Source paths
    local source_skills="$SCRIPT_DIR/core/skills/orchestrator"
    local source_agents="$SCRIPT_DIR/core/agents"

    # Install Skills
    if [[ -d "$source_skills" ]]; then
        echo -e "  Installing skills..."

        while IFS= read -r -d '' file; do
            local relative_path="${file#$source_skills/}"
            local dest_path="$SKILLS_DIR/$relative_path"
            local dest_dir=$(dirname "$dest_path")

            mkdir -p "$dest_dir"

            local should_copy=true
            if [[ -f "$dest_path" ]] && [[ "$FORCE" != "true" ]]; then
                if [[ "$file" -ot "$dest_path" ]] || [[ "$file" -ot "$dest_path" 2>/dev/null ]]; then
                    should_copy=false
                    ((FILES_SKIPPED++))
                fi
            fi

            if [[ "$should_copy" == "true" ]]; then
                cp "$file" "$dest_path"
                ((FILES_COPIED++))
                ((skills_count++))
            fi
        done < <(find "$source_skills" -type f -print0)

        echo -e "    ${GREEN}Skills files: ${skills_count}${NC}"
    else
        echo -e "  ${YELLOW}[WARN] Skills source not found: $source_skills${NC}"
    fi

    # Install Agents
    if [[ -d "$source_agents" ]]; then
        echo -e "  Installing agents..."

        while IFS= read -r -d '' file; do
            local relative_path="${file#$source_agents/}"
            local dest_path="$AGENTS_DIR/$relative_path"
            local dest_dir=$(dirname "$dest_path")

            mkdir -p "$dest_dir"

            local should_copy=true
            if [[ -f "$dest_path" ]] && [[ "$FORCE" != "true" ]]; then
                # Simple check: skip if dest exists and is newer or same age
                if [[ ! "$file" -nt "$dest_path" ]]; then
                    should_copy=false
                    ((FILES_SKIPPED++))
                fi
            fi

            if [[ "$should_copy" == "true" ]]; then
                cp "$file" "$dest_path"
                ((FILES_COPIED++))
                ((agents_count++))
            fi
        done < <(find "$source_agents" -type f -print0)

        echo -e "    ${GREEN}Agents files: ${agents_count}${NC}"
    else
        echo -e "  ${YELLOW}[WARN] Agents source not found: $source_agents${NC}"
    fi

    echo ""
    echo -e "  ${GREEN}Total files copied: ${FILES_COPIED}${NC}"
    echo -e "  ${DARKGRAY}Total files skipped: ${FILES_SKIPPED}${NC}"
    echo ""
}

# ====================================================================
# FUNCTION: install_shell_profile
# ====================================================================
install_shell_profile() {
    echo -e "${CYAN}[Installing Shell Profile Integration]${NC}"
    echo ""

    local template_path="$SCRIPT_DIR/templates/profiles/bashrc.sh.template"

    if [[ ! -f "$template_path" ]]; then
        echo -e "  ${YELLOW}[WARN] Template not found: $template_path${NC}"
        echo -e "        ${DARKGRAY}Skipping shell profile installation.${NC}"
        echo ""
        return 1
    fi

    local template_content=$(cat "$template_path")

    # Functions to inject
    local functions_to_inject=("switch_claude_profile" "test_claude_profile" "cca" "ccg" "cca_restart" "ccg_restart" "claude")

    if [[ ! -f "$SHELL_RC" ]]; then
        # No existing profile - copy template as new profile
        cp "$template_path" "$SHELL_RC"
        echo -e "  ${GREEN}Created new profile from template: $SHELL_RC${NC}"
    else
        # Existing profile - check and merge
        local existing_content=$(cat "$SHELL_RC")

        # Check which functions are already present
        local missing_functions=()
        for func_name in "${functions_to_inject[@]}"; do
            if ! grep -q "^${func_name}()" "$SHELL_RC" 2>/dev/null; then
                missing_functions+=("$func_name")
            fi
        done

        if [[ ${#missing_functions[@]} -eq 0 ]]; then
            echo -e "  ${DARKGRAY}All functions already present in $SHELL_RC. Skipping.${NC}"
            echo ""
            return 0
        fi

        # Backup existing profile
        cp "$SHELL_RC" "${SHELL_RC}.bak"
        echo -e "  ${DARKGRAY}Backup created: ${SHELL_RC}.bak${NC}"

        # Extract and append missing functions
        local append_content=""

        # Parse template for function definitions
        # Each function is: func_name() { ... }
        for func_name in "${missing_functions[@]}"; do
            # Use awk to extract function block
            local func_block=$(awk "/^${func_name}\(\)/,/^}/" "$template_path")
            if [[ -n "$func_block" ]]; then
                append_content+="${func_block}"$'\n\n'
            fi
        done

        # Also add configuration section if not present
        if ! grep -q "CLAUDE_CONFIG_DIR=" "$SHELL_RC" 2>/dev/null; then
            local config_section=$(sed -n '/^# === CONFIGURATION/,/^# === Core Function/p' "$template_path" | head -n -1)
            append_content="${config_section}"$'\n'"${append_content}"
        fi

        # Append to profile
        {
            echo ""
            echo "# === Claude Orchestrator Integration ==="
            echo "$append_content"
        } >> "$SHELL_RC"

        echo -e "  ${GREEN}Added functions: ${missing_functions[*]}${NC}"
    fi

    echo ""
    return 0
}

# ====================================================================
# FUNCTION: install_settings_templates
# ====================================================================
install_settings_templates() {
    echo -e "${CYAN}[Installing Settings Templates]${NC}"
    echo ""

    local templates=(
        "templates/settings-anthropic.json:$CLAUDE_DIR/settings-anthropic.json:Anthropic Settings:false"
        "templates/settings-glm.json.template:$CLAUDE_DIR/settings-glm.json:GLM5 Settings:true"
    )

    for template_info in "${templates[@]}"; do
        IFS=':' read -r source_rel dest_path name needs_api <<< "$template_info"

        local source_path="$SCRIPT_DIR/$source_rel"

        echo -e "  Processing ${name}..."

        if [[ ! -f "$source_path" ]]; then
            echo -e "    ${YELLOW}[WARN] Template not found: $source_path${NC}"
            continue
        fi

        # Check if destination exists
        if [[ -f "$dest_path" ]] && [[ "$FORCE" != "true" ]]; then
            echo -e "    ${DARKGRAY}Already exists. Use --force to overwrite.${NC}"
            continue
        fi

        # Copy template
        cp "$source_path" "$dest_path"
        echo -e "    ${GREEN}Installed: $dest_path${NC}"

        # Handle API key for GLM
        if [[ "$needs_api" == "true" ]] && [[ "$SILENT" != "true" ]]; then
            echo ""
            echo -ne "    ${CYAN}Configure Z.AI API key now? (Y/n): ${NC}"
            read -r configure

            if [[ -z "$configure" ]] || [[ "${configure,,}" == "y" ]]; then
                echo -ne "    ${CYAN}Enter your Z.AI API token: ${NC}"
                read -r api_key

                if [[ -n "$api_key" ]]; then
                    # Replace placeholder with actual API key
                    if [[ "$(uname)" == "Darwin" ]]; then
                        # macOS sed
                        sed -i '' "s|<YOUR_ZAI_API_TOKEN_HERE>|${api_key}|g" "$dest_path"
                    else
                        # Linux sed
                        sed -i "s|<YOUR_ZAI_API_TOKEN_HERE>|${api_key}|g" "$dest_path"
                    fi
                    echo -e "    ${GREEN}API key configured.${NC}"
                fi
            fi
        fi
    done

    echo ""
    return 0
}

# ====================================================================
# FUNCTION: install_mcp_plugin
# ====================================================================
install_mcp_plugin() {
    echo -e "${CYAN}[Installing MCP Plugin]${NC}"
    echo ""

    local mcp_source="$SCRIPT_DIR/mcp-plugin"

    if [[ ! -d "$mcp_source" ]]; then
        echo -e "  ${DARKGRAY}[SKIP] MCP plugin not available in this distribution.${NC}"
        echo ""
        return 1
    fi

    local mcp_dest="$CLAUDE_DIR/mcp-plugins/orchestrator"
    mkdir -p "$mcp_dest"

    local copied=0
    while IFS= read -r -d '' file; do
        local relative_path="${file#$mcp_source/}"
        local dest_path="$mcp_dest/$relative_path"
        local dest_dir=$(dirname "$dest_path")

        mkdir -p "$dest_dir"
        cp "$file" "$dest_path"
        ((copied++))
    done < <(find "$mcp_source" -type f -print0)

    echo -e "  ${GREEN}MCP plugin files installed: ${copied}${NC}"
    echo ""

    return 0
}

# ====================================================================
# FUNCTION: create_version_tracking
# ====================================================================
create_version_tracking() {
    echo -e "${CYAN}[Creating Version Tracking]${NC}"
    echo ""

    local component_names=()
    for comp in "${SELECTED_COMPONENTS[@]}"; do
        case "$comp" in
            1) component_names+=("$COMPONENT_1_NAME") ;;
            2) component_names+=("$COMPONENT_2_NAME") ;;
            3) component_names+=("$COMPONENT_3_NAME") ;;
            4) component_names+=("$COMPONENT_4_NAME") ;;
        esac
    done

    local install_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build JSON manually for portability
    local components_json=$(printf '"%s",' "${component_names[@]}")
    components_json="[${components_json%,}]"

    cat > "$ORCHESTRATOR_DIR/VERSION.json" << EOF
{
  "installed": "${ORCHESTRATOR_VERSION}",
  "channel": "${ORCHESTRATOR_CHANNEL}",
  "installDate": "${install_date}",
  "components": ${components_json},
  "lastCheck": null,
  "updateAvailable": false
}
EOF

    echo -e "  ${GREEN}Created: $ORCHESTRATOR_DIR/VERSION.json${NC}"
    echo ""
}

# ====================================================================
# FUNCTION: verify_installation
# ====================================================================
verify_installation() {
    echo -e "${CYAN}[Verifying Installation]${NC}"
    echo ""

    local success=true
    local skills_valid=false
    local agents_count=0
    local profile_installed=false
    local settings_installed=false

    # 1. Verify SKILL.md
    local skill_path="$SKILLS_DIR/SKILL.md"
    if [[ -f "$skill_path" ]]; then
        if grep -q "^---" "$skill_path" && grep -q "name:[[:space:]]*orchestrator" "$skill_path"; then
            skills_valid=true
            echo -e "  ${GREEN}[OK]${NC} SKILL.md is valid"
        else
            echo -e "  ${YELLOW}[WARN]${NC} SKILL.md exists but may be invalid"
        fi
    else
        echo -e "  ${RED}[ERROR]${NC} SKILL.md not found"
        success=false
    fi

    # 2. Count agent files
    if [[ -d "$AGENTS_DIR" ]]; then
        agents_count=$(find "$AGENTS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
        echo -e "  ${GREEN}[OK]${NC} Agent files installed: ${agents_count}"
    else
        echo -e "  ${YELLOW}[WARN]${NC} Agents directory not found"
    fi

    # 3. Verify shell profile (if component 2 was selected)
    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 2 " ]]; then
        if [[ -f "$SHELL_RC" ]] && grep -q "switch_claude_profile" "$SHELL_RC" 2>/dev/null; then
            profile_installed=true
            echo -e "  ${GREEN}[OK]${NC} Shell profile integration installed (${SHELL_NAME})"
        else
            echo -e "  ${YELLOW}[WARN]${NC} Shell profile integration may not be complete"
        fi
    fi

    # 4. Verify settings templates (if component 3 was selected)
    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 3 " ]]; then
        local settings_anthropic="$CLAUDE_DIR/settings-anthropic.json"
        local settings_glm="$CLAUDE_DIR/settings-glm.json"

        if [[ -f "$settings_anthropic" ]] && [[ -f "$settings_glm" ]]; then
            settings_installed=true
            echo -e "  ${GREEN}[OK]${NC} Settings templates installed"
        else
            echo -e "  ${YELLOW}[WARN]${NC} Some settings templates may be missing"
        fi
    fi

    echo ""

    VERIFICATION_SUCCESS="$success"
    VERIFICATION_AGENTS="$agents_count"
}

# ====================================================================
# FUNCTION: show_completion_message
# ====================================================================
show_completion_message() {
    echo ""
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
    echo ""

    if [[ "$VERIFICATION_SUCCESS" == "true" ]]; then
        echo -e "  ${GREEN}INSTALLATION COMPLETE${NC}"
    else
        echo -e "  ${YELLOW}INSTALLATION COMPLETE (with warnings)${NC}"
    fi

    echo ""
    echo -e "  Installed Components:"
    for comp in "${SELECTED_COMPONENTS[@]}"; do
        case "$comp" in
            1) echo -e "    ${DARKGRAY}- ${COMPONENT_1_NAME}${NC}" ;;
            2) echo -e "    ${DARKGRAY}- ${COMPONENT_2_NAME}${NC}" ;;
            3) echo -e "    ${DARKGRAY}- ${COMPONENT_3_NAME}${NC}" ;;
            4) echo -e "    ${DARKGRAY}- ${COMPONENT_4_NAME}${NC}" ;;
        esac
    done

    echo ""
    echo -e "  Installation Details:"
    echo -e "    ${DARKGRAY}Version:      ${ORCHESTRATOR_VERSION}${NC}"
    echo -e "    ${DARKGRAY}Skills Dir:   ${SKILLS_DIR}${NC}"
    echo -e "    ${DARKGRAY}Agents Dir:   ${AGENTS_DIR}${NC}"
    echo -e "    ${DARKGRAY}Agents Count: ${VERIFICATION_AGENTS}${NC}"

    echo ""
    echo -e "  ${CYAN}Next Steps:${NC}"
    echo ""
    echo -e "    1. Reload your shell: ${YELLOW}source ${SHELL_RC}${NC}"
    echo -e "    2. Test orchestrator with: ${YELLOW}/orchestrator${NC}"
    echo -e "    3. View documentation: ${DARKGRAY}${SKILLS_DIR}${NC}"

    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 2 " ]]; then
        echo ""
        echo -e "  ${CYAN}Profile Commands Available:${NC}"
        echo -e "    ${DARKGRAY}cca              - Switch to Anthropic profile${NC}"
        echo -e "    ${DARKGRAY}ccg              - Switch to GLM5 profile${NC}"
        echo -e "    ${DARKGRAY}claude           - Run claude with active profile${NC}"
        echo -e "    ${DARKGRAY}test_claude_profile - Verify current profile${NC}"
    fi

    echo ""
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
    echo ""
}

# ====================================================================
# MAIN EXECUTION
# ====================================================================
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Phase 1: Banner
    show_banner

    # Phase 2: Prerequisites
    check_prerequisites

    # Phase 3: Component Selection
    get_component_selection

    # Phase 4: Install Components
    local install_start=$(date +%s)

    # Core (Component 1) - Always installed
    install_core_files

    # Shell Profile (Component 2)
    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 2 " ]]; then
        if install_shell_profile; then
            INSTALLED_COMPONENTS+=("Shell Profile")
        fi
    fi

    # Settings Templates (Component 3)
    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 3 " ]]; then
        if install_settings_templates; then
            INSTALLED_COMPONENTS+=("Settings Templates")
        fi
    fi

    # MCP Plugin (Component 4)
    if [[ " ${SELECTED_COMPONENTS[*]} " =~ " 4 " ]]; then
        if install_mcp_plugin; then
            INSTALLED_COMPONENTS+=("MCP Plugin")
        fi
    fi

    # Phase 5: Version Tracking
    create_version_tracking

    # Phase 6: Verification
    verify_installation

    # Phase 7: Completion Message
    show_completion_message

    local install_end=$(date +%s)
    local duration=$((install_end - install_start))

    echo -e "  ${DARKGRAY}Installation completed in ${duration} seconds${NC}"
    echo ""

    exit 0
}

# Run main with all arguments
main "$@"
