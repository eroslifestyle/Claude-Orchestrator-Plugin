#!/bin/bash
#
# Claude Orchestrator - Perform Update (Unix/Mac)
#
# Executes the update process:
# 1. Creates backup in ~/.claude/backups/orchestrator/v{current}/
# 2. Downloads latest release from GitHub OR performs git pull
# 3. Runs setup.sh to reinstall
# 4. Updates VERSION.json
# 5. Verifies installation
# Supports automatic rollback if update fails.
#
# Usage:
#   ./do-update.sh              # Update to latest
#   ./do-update.sh --version 10.2.0  # Update to specific version
#   ./do-update.sh --force      # Force update even if up to date
#   ./do-update.sh --skip-backup     # Skip backup (risky)
#

set -e

# ====================================================================
# CONFIGURATION
# ====================================================================
ORCHESTRATOR_VERSION="10.1.0"
CLAUDE_DIR="${HOME}/.claude"
ORCHESTRATOR_DIR="${CLAUDE_DIR}/orchestrator"
BACKUP_DIR="${CLAUDE_DIR}/backups/orchestrator"
SKILLS_DIR="${CLAUDE_DIR}/skills/orchestrator"
AGENTS_DIR="${CLAUDE_DIR}/agents"
VERSION_FILE="${ORCHESTRATOR_DIR}/VERSION.json"

# GitHub configuration
GITHUB_REPO="eroslifestyle/Claude-Orchestrator-Plugin"
GITHUB_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/releases"
GITHUB_REPO_URL="https://github.com/${GITHUB_REPO}"

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(dirname "$SCRIPT_DIR")"

# Update state
UPDATE_SUCCESS=false
BACKUP_PATH=""
PREVIOUS_VERSION=""

# Parse arguments
TARGET_VERSION=""
FORCE=false
SKIP_BACKUP=false
SILENT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version|-v)
            TARGET_VERSION="$2"
            shift 2
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --silent|-s)
            SILENT=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# ====================================================================
# HELPER FUNCTIONS
# ====================================================================

log_info() {
    if [ "$SILENT" = false ]; then
        echo -e "\033[36m[$(date +%H:%M:%S)] [INFO] $1\033[0m"
    fi
}

log_ok() {
    echo -e "\033[32m[$(date +%H:%M:%S)] [OK] $1\033[0m"
}

log_warn() {
    echo -e "\033[33m[$(date +%H:%M:%S)] [WARN] $1\033[0m"
}

log_error() {
    echo -e "\033[31m[$(date +%H:%M:%S)] [ERROR] $1\033[0m"
}

log_step() {
    echo -e "\033[35m[$(date +%H:%M:%S)] [STEP] $1\033[0m"
}

github_api() {
    local url="$1"

    # Build curl command
    local args="-s"
    args="$args -H \"User-Agent: Claude-Orchestrator-Updater/$ORCHESTRATOR_VERSION\""
    args="$args -H \"Accept: application/vnd.github.v3+json\""

    if [ -n "$GITHUB_TOKEN" ]; then
        args="$args -H \"Authorization: token $GITHUB_TOKEN\""
    fi

    eval curl $args "$url" 2>/dev/null
}

compare_versions() {
    local v1="$1"
    local v2="$2"

    if [ "$v1" = "$v2" ]; then
        echo "0"
        return
    fi

    local IFS='.'
    read -ra v1_parts <<< "$v1"
    read -ra v2_parts <<< "$v2"

    local max_len=${#v1_parts[@]}
    if [ ${#v2_parts[@]} -gt $max_len ]; then
        max_len=${#v2_parts[@]}
    fi

    for ((i=0; i<max_len; i++)); do
        local part1=${v1_parts[i]:-0}
        local part2=${v2_parts[i]:-0}

        if [ "$part1" -lt "$part2" ]; then
            echo "-1"
            return
        elif [ "$part1" -gt "$part2" ]; then
            echo "1"
            return
        fi
    done

    echo "0"
}

get_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"//;s/\"$//"
}

create_backup() {
    local current_version="$1"

    if [ "$SKIP_BACKUP" = true ]; then
        log_warn "Backup skipped (--skip-backup)"
        return 0
    fi

    local backup_path="${BACKUP_DIR}/v${current_version}"

    if [ -d "$backup_path" ]; then
        log_warn "Backup already exists: $backup_path"
        BACKUP_PATH="$backup_path"
        return 0
    fi

    log_step "Creating backup at: $backup_path"

    mkdir -p "$backup_path"

    # Backup skills
    if [ -d "$SKILLS_DIR" ]; then
        cp -r "$SKILLS_DIR" "$backup_path/skills"
        log_info "  Backed up skills"
    fi

    # Backup agents
    if [ -d "$AGENTS_DIR" ]; then
        cp -r "$AGENTS_DIR" "$backup_path/agents"
        log_info "  Backed up agents"
    fi

    # Backup VERSION.json
    if [ -f "$VERSION_FILE" ]; then
        cp "$VERSION_FILE" "$backup_path/VERSION.json"
        log_info "  Backed up VERSION.json"
    fi

    # Create manifest
    cat > "$backup_path/manifest.json" <<EOF
{
  "version": "$current_version",
  "backupDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "skillsPath": "$SKILLS_DIR",
  "agentsPath": "$AGENTS_DIR"
}
EOF

    BACKUP_PATH="$backup_path"
    log_ok "Backup completed successfully"
}

restore_backup() {
    local backup_path="$1"

    if [ -z "$backup_path" ] || [ ! -d "$backup_path" ]; then
        log_error "No valid backup to restore"
        return 1
    fi

    log_step "Restoring from backup: $backup_path"

    # Restore skills
    if [ -d "$backup_path/skills" ]; then
        rm -rf "$SKILLS_DIR"
        cp -r "$backup_path/skills" "$SKILLS_DIR"
        log_info "  Restored skills"
    fi

    # Restore agents
    if [ -d "$backup_path/agents" ]; then
        rm -rf "$AGENTS_DIR"
        cp -r "$backup_path/agents" "$AGENTS_DIR"
        log_info "  Restored agents"
    fi

    # Restore VERSION.json
    if [ -f "$backup_path/VERSION.json" ]; then
        cp "$backup_path/VERSION.json" "$VERSION_FILE"
        log_info "  Restored VERSION.json"
    fi

    log_ok "Rollback completed successfully"
    return 0
}

update_via_git() {
    local target_dir="$1"

    log_step "Attempting git pull update..."

    pushd "$target_dir" > /dev/null 2>&1

    if [ ! -d ".git" ]; then
        log_warn "Not a git repository, falling back to download"
        popd > /dev/null 2>&1
        return 1
    fi

    git fetch origin --quiet 2>/dev/null || true
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

    if [ -n "$TARGET_VERSION" ]; then
        git checkout "v$TARGET_VERSION" --quiet 2>/dev/null || \
        git checkout "$TARGET_VERSION" --quiet 2>/dev/null || true
    else
        git pull origin "$current_branch" --quiet 2>/dev/null || true
    fi

    popd > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_ok "Git pull successful"
        return 0
    else
        log_warn "Git pull failed"
        return 1
    fi
}

update_via_download() {
    local target_version="$1"

    log_step "Downloading release v$target_version..."

    local download_dir=$(mktemp -d)
    local cleanup_done=false

    cleanup() {
        if [ "$cleanup_done" = false ]; then
            rm -rf "$download_dir"
            cleanup_done=true
        fi
    }
    trap cleanup EXIT

    # Get release info
    local release_url
    if [ -n "$target_version" ]; then
        release_url="${GITHUB_RELEASES}/tags/v${target_version}"
    else
        release_url="${GITHUB_RELEASES}/latest"
    fi

    local release_info=$(github_api "$release_url")
    local download_version=$(echo "$release_info" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"tag_name"[[:space:]]*:[[:space:]]*"//;s/"$//' | sed 's/^v//')

    if [ -z "$download_version" ]; then
        log_error "Failed to get release info"
        return 1
    fi

    # Find ZIP asset or use source archive
    local zip_url=$(echo "$release_info" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*\.zip"' | head -1 | sed 's/"browser_download_url"[[:space:]]*:[[:space:]]*"//;s/"$//')

    if [ -z "$zip_url" ]; then
        zip_url="https://github.com/${GITHUB_REPO}/archive/refs/tags/v${download_version}.zip"
    fi

    log_info "  Downloading from: $zip_url"

    local zip_path="${download_dir}/update.zip"
    curl -sL "$zip_url" -o "$zip_path"

    if [ ! -f "$zip_path" ] || [ ! -s "$zip_path" ]; then
        log_error "Failed to download update package"
        return 1
    fi

    log_info "  Extracting..."

    local extract_dir="${download_dir}/extracted"
    mkdir -p "$extract_dir"

    if command -v unzip &> /dev/null; then
        unzip -q "$zip_path" -d "$extract_dir"
    else
        log_error "unzip not found, cannot extract"
        return 1
    fi

    # Find extracted directory
    local source_dir=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -1)

    if [ -z "$source_dir" ] || [ ! -d "$source_dir" ]; then
        log_error "Failed to extract update package"
        return 1
    fi

    log_info "  Extracted to: $source_dir"

    # Copy to distribution directory
    if [ -d "$DIST_DIR" ]; then
        cp -r "$source_dir"/* "$DIST_DIR/" 2>/dev/null || true
    fi

    log_ok "Download update completed"
    return 0
}

run_setup() {
    local setup_dir="$1"

    local setup_script="${setup_dir}/setup.sh"

    # Fallback to setup.ps1 if setup.sh doesn't exist (for cross-platform)
    if [ ! -f "$setup_script" ]; then
        setup_script="${setup_dir}/setup.ps1"
        if [ ! -f "$setup_script" ]; then
            log_warn "setup.sh/setup.ps1 not found in $setup_dir"
            return 1
        fi

        # Run PowerShell setup
        log_step "Running setup.ps1..."
        if command -v pwsh &> /dev/null; then
            pwsh -NoProfile -ExecutionPolicy Bypass -File "$setup_script" -Silent -Components "1,2,3"
            return $?
        elif command -v powershell &> /dev/null; then
            powershell -NoProfile -ExecutionPolicy Bypass -File "$setup_script" -Silent -Components "1,2,3"
            return $?
        else
            log_warn "PowerShell not available for setup.ps1"
            return 1
        fi
    fi

    log_step "Running setup.sh..."

    chmod +x "$setup_script"
    bash "$setup_script" --silent

    if [ $? -eq 0 ]; then
        log_ok "Setup completed successfully"
        return 0
    else
        log_error "Setup failed"
        return 1
    fi
}

update_version_file() {
    local new_version="$1"

    if [ ! -f "$VERSION_FILE" ]; then
        log_warn "VERSION.json not found"
        return
    fi

    log_step "Updating VERSION.json..."

    if command -v jq &> /dev/null; then
        jq --arg new "$new_version" '.version = $new | .updateCheck.lastCheck = null' "$VERSION_FILE" > "${VERSION_FILE}.tmp" && mv "${VERSION_FILE}.tmp" "$VERSION_FILE"
    else
        sed -i.bak "s/\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"version\": \"$new_version\"/" "$VERSION_FILE"
        rm -f "${VERSION_FILE}.bak"
    fi

    log_ok "VERSION.json updated to $new_version"
}

verify_installation() {
    local skill_path="${SKILLS_DIR}/SKILL.md"

    if [ ! -f "$skill_path" ]; then
        log_error "Installation verification failed: SKILL.md not found"
        return 1
    fi

    if ! grep -q "name:.*orchestrator" "$skill_path" 2>/dev/null; then
        log_error "Installation verification failed: Invalid SKILL.md"
        return 1
    fi

    log_ok "Installation verified successfully"
    return 0
}

# ====================================================================
# MAIN EXECUTION
# ====================================================================

log_info "========================================"
log_info "Claude Orchestrator Update Script"
log_info "========================================"
echo ""

# ----------------------------------------------------------------
# Step 1: Read current version
# ----------------------------------------------------------------
log_step "Step 1: Checking current installation"

if [ ! -f "$VERSION_FILE" ]; then
    log_error "VERSION.json not found. Is orchestrator installed?"
    exit 1
fi

VERSION_CONTENT=$(cat "$VERSION_FILE")
PREVIOUS_VERSION=$(get_json_value "$VERSION_CONTENT" "version")

log_info "  Current version: $PREVIOUS_VERSION"

# ----------------------------------------------------------------
# Step 2: Check for updates
# ----------------------------------------------------------------
log_step "Step 2: Checking for updates"

if [ -z "$TARGET_VERSION" ]; then
    LATEST_INFO=$(github_api "${GITHUB_RELEASES}/latest")
    TARGET_VERSION=$(echo "$LATEST_INFO" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"tag_name"[[:space:]]*:[[:space:]]*"//;s/"$//' | sed 's/^v//')
fi

log_info "  Target version: $TARGET_VERSION"

# Compare versions
CMP=$(compare_versions "$PREVIOUS_VERSION" "$TARGET_VERSION")

if [ "$CMP" -ge 0 ] && [ "$FORCE" = false ]; then
    log_ok "Already up to date (or ahead). Use --force to update anyway."
    exit 0
fi

# ----------------------------------------------------------------
# Step 3: Create backup
# ----------------------------------------------------------------
log_step "Step 3: Creating backup"
create_backup "$PREVIOUS_VERSION"

# ----------------------------------------------------------------
# Step 4: Download/Update
# ----------------------------------------------------------------
log_step "Step 4: Downloading update"

UPDATE_OK=false

# Try git first
if [ -d "${DIST_DIR}/.git" ]; then
    update_via_git "$DIST_DIR" && UPDATE_OK=true
fi

# Fallback to download
if [ "$UPDATE_OK" = false ]; then
    update_via_download "$TARGET_VERSION" && UPDATE_OK=true
fi

if [ "$UPDATE_OK" = false ]; then
    log_error "Failed to download update"
    # Trigger rollback in trap
    exit 1
fi

# ----------------------------------------------------------------
# Step 5: Run setup
# ----------------------------------------------------------------
log_step "Step 5: Running installation"

if ! run_setup "$DIST_DIR"; then
    log_error "Setup failed"
    exit 1
fi

# ----------------------------------------------------------------
# Step 6: Update VERSION.json
# ----------------------------------------------------------------
log_step "Step 6: Updating version tracking"
update_version_file "$TARGET_VERSION"

# ----------------------------------------------------------------
# Step 7: Verify installation
# ----------------------------------------------------------------
log_step "Step 7: Verifying installation"

if ! verify_installation; then
    log_error "Installation verification failed"
    exit 1
fi

# ----------------------------------------------------------------
# Success!
# ----------------------------------------------------------------
UPDATE_SUCCESS=true

echo ""
log_ok "========================================"
log_ok "UPDATE SUCCESSFUL"
log_ok "  From: $PREVIOUS_VERSION"
log_ok "  To:   $TARGET_VERSION"
log_ok "========================================"

exit 0
