#!/bin/bash
#
# Claude Orchestrator - Check for Updates (Unix/Mac)
#
# Checks GitHub API for latest release and compares with installed version.
# Implements rate limiting: max 1 check per hour.
#
# Usage:
#   ./check-update.sh           # Check with rate limiting
#   ./check-update.sh --force   # Force check bypassing rate limit
#   ./check-update.sh --silent  # Output only JSON
#
# Output JSON:
#   {
#     "updateAvailable": true/false,
#     "currentVersion": "10.1.0",
#     "latestVersion": "10.2.0",
#     "releaseNotes": "...",
#     "publishedAt": "...",
#     "checkedAt": "...",
#     "error": null
#   }
#

set -e

# ====================================================================
# CONFIGURATION
# ====================================================================
ORCHESTRATOR_DIR="${HOME}/.claude/orchestrator"
VERSION_FILE="${ORCHESTRATOR_DIR}/VERSION.json"
RATE_LIMIT_HOURS=1

# GitHub API configuration
GITHUB_API="https://api.github.com/repos/eroslifestyle/Claude-Orchestrator-Plugin/releases/latest"

# Parse arguments
FORCE=false
SILENT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
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
        echo "  [INFO] $1"
    fi
}

log_ok() {
    if [ "$SILENT" = false ]; then
        echo -e "\033[32m  [OK] $1\033[0m"
    fi
}

log_warn() {
    if [ "$SILENT" = false ]; then
        echo -e "\033[33m  [WARN] $1\033[0m"
    fi
}

log_error() {
    if [ "$SILENT" = false ]; then
        echo -e "\033[31m  [ERROR] $1\033[0m"
    fi
}

compare_versions() {
    # Returns 0 if equal, 1 if v1 > v2, 2 if v1 < v2
    local v1="$1"
    local v2="$2"

    if [ "$v1" = "$v2" ]; then
        return 0
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
            return 2  # v1 < v2
        elif [ "$part1" -gt "$part2" ]; then
            return 1  # v1 > v2
        fi
    done

    return 0  # Equal
}

get_json_value() {
    local json="$1"
    local key="$2"

    # Simple JSON parser (works without jq)
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"//;s/\"$//"
}

# ====================================================================
# MAIN LOGIC
# ====================================================================

# Initialize result JSON
CURRENT_VERSION="unknown"
LATEST_VERSION="unknown"
RELEASE_NOTES=""
PUBLISHED_AT=""
CHECKED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ERROR=""
UPDATE_AVAILABLE=false

# ----------------------------------------------------------------
# Step 1: Read installed version
# ----------------------------------------------------------------
if [ ! -f "$VERSION_FILE" ]; then
    ERROR="VERSION.json not found at $VERSION_FILE"
    log_error "$ERROR"
else
    VERSION_CONTENT=$(cat "$VERSION_FILE")
    CURRENT_VERSION=$(get_json_value "$VERSION_CONTENT" "version")
    log_info "Current version: $CURRENT_VERSION"

    # ----------------------------------------------------------------
    # Step 2: Check rate limiting
    # ----------------------------------------------------------------
    LAST_CHECK=$(get_json_value "$VERSION_CONTENT" "lastCheck")

    if [ -n "$LAST_CHECK" ] && [ "$FORCE" = false ]; then
        # Calculate time since last check (simplified - check if same hour)
        LAST_CHECK_HOUR=$(echo "$LAST_CHECK" | cut -d'T' -f1,2 | cut -d':' -f1)
        CURRENT_HOUR=$(date -u +"%Y-%m-%dT%H")

        if [ "$LAST_CHECK_HOUR" = "$CURRENT_HOUR" ]; then
            log_warn "Rate limit: skipping check (same hour)"
            log_info "Use --force to bypass rate limit"
            ERROR="Rate limited - use --force to bypass"
        fi
    fi

    # ----------------------------------------------------------------
    # Step 3: Call GitHub API (if not rate limited)
    # ----------------------------------------------------------------
    if [ -z "$ERROR" ]; then
        log_info "Checking GitHub for updates..."

        # Build curl command with optional auth
        CURL_ARGS="-s -H \"User-Agent: Claude-Orchestrator-Updater/10.1.0\""
        CURL_ARGS="$CURL_ARGS -H \"Accept: application/vnd.github.v3+json\""

        if [ -n "$GITHUB_TOKEN" ]; then
            CURL_ARGS="$CURL_ARGS -H \"Authorization: token $GITHUB_TOKEN\""
        fi

        # Fetch release info
        API_RESPONSE=$(eval curl $CURL_ARGS "$GITHUB_API" 2>/dev/null || echo '{"error": "API call failed"}')

        if echo "$API_RESPONSE" | grep -q '"tag_name"'; then
            LATEST_VERSION=$(echo "$API_RESPONSE" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"tag_name"[[:space:]]*:[[:space:]]*"//;s/"$//' | sed 's/^v//')
            PUBLISHED_AT=$(echo "$API_RESPONSE" | grep -o '"published_at"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"published_at"[[:space:]]*:[[:space:]]*"//;s/"$//')

            # Extract release notes (simplified - get first line or truncate)
            RELEASE_NOTES=$(echo "$API_RESPONSE" | grep -o '"body"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"body"[[:space:]]*:[[:space:]]*"//;s/"$//' | head -c 200)

            log_ok "Latest version: $LATEST_VERSION"
            log_info "Published at: $PUBLISHED_AT"

            # ----------------------------------------------------------------
            # Step 4: Compare versions
            # ----------------------------------------------------------------
            compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
            CMP_RESULT=$?

            if [ $CMP_RESULT -eq 2 ]; then
                UPDATE_AVAILABLE=true
                log_ok "Update available!"
            elif [ $CMP_RESULT -eq 1 ]; then
                UPDATE_AVAILABLE=false
                log_warn "Running pre-release or dev version"
            else
                UPDATE_AVAILABLE=false
                log_ok "Already up to date"
            fi

            # ----------------------------------------------------------------
            # Step 5: Update VERSION.json with last check time
            # ----------------------------------------------------------------
            if command -v jq &> /dev/null; then
                # Use jq if available
                jq --arg checked "$CHECKED_AT" \
                   --argjson avail "$UPDATE_AVAILABLE" \
                   --arg latest "$LATEST_VERSION" \
                   '.updateCheck.lastCheck = $checked |
                    .updateCheck.cachedResult = {
                        updateAvailable: $avail,
                        latestVersion: $latest
                    }' "$VERSION_FILE" > "${VERSION_FILE}.tmp" && mv "${VERSION_FILE}.tmp" "$VERSION_FILE"
            else
                # Simple sed replacement for lastCheck
                sed -i.bak "s/\"lastCheck\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"lastCheck\": \"$CHECKED_AT\"/" "$VERSION_FILE"
                rm -f "${VERSION_FILE}.bak"
            fi
        else
            ERROR="Failed to fetch release info from GitHub"
            log_error "$ERROR"
        fi
    fi
fi

# ====================================================================
# OUTPUT
# ====================================================================

# Build JSON output
OUTPUT=$(cat <<EOF
{
  "updateAvailable": $UPDATE_AVAILABLE,
  "currentVersion": "$CURRENT_VERSION",
  "latestVersion": "$LATEST_VERSION",
  "releaseNotes": "$RELEASE_NOTES",
  "publishedAt": "$PUBLISHED_AT",
  "checkedAt": "$CHECKED_AT",
  "error": $(if [ -n "$ERROR" ]; then echo "\"$ERROR\""; else echo "null"; fi)
}
EOF
)

if [ "$SILENT" = true ]; then
    echo "$OUTPUT"
else
    echo ""
    echo "  Result:"
    echo "$OUTPUT"
fi
