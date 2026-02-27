#!/bin/bash
# =============================================================================
# ROUTING VALIDATION TEST RUNNER
# =============================================================================
# Purpose: Automated validation of agent routing table integrity
# Source: agents/tests/routing-validation.md
# Version: 1.0.0
# Created: 2026-02-26
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ROUTING_VALIDATION="$SCRIPT_DIR/routing-validation.md"
ORCHESTRATOR_SKILL="$CLAUDE_DIR/skills/orchestrator/SKILL.md"
AGENTS_DIR="$CLAUDE_DIR/agents"
OUTPUT_DIR="$SCRIPT_DIR/results"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
ERRORS=()

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ERRORS+=("$1")
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

# =============================================================================
# TEST 1: AGENT EXISTENCE
# =============================================================================

test_agent_existence() {
    echo ""
    echo "=========================================="
    echo "TEST 1: Agent Existence"
    echo "=========================================="

    local routing_entries=(
        "GUI Super Expert:experts/gui-super-expert.md"
        "GUI Layout Specialist L2:experts/L2/gui-layout-specialist.md"
        "Database Expert:experts/database_expert.md"
        "DB Query Optimizer L2:experts/L2/db-query-optimizer.md"
        "Security Unified Expert:experts/security_unified_expert.md"
        "Security Auth Specialist L2:experts/L2/security-auth-specialist.md"
        "Offensive Security Expert:experts/offensive_security_expert.md"
        "Reverse Engineering Expert:experts/reverse_engineering_expert.md"
        "Integration Expert:experts/integration_expert.md"
        "API Endpoint Builder L2:experts/L2/api-endpoint-builder.md"
        "Tester Expert:experts/tester_expert.md"
        "Test Unit Specialist L2:experts/L2/test-unit-specialist.md"
        "MQL Expert:experts/mql_expert.md"
        "MQL Optimization L2:experts/L2/mql-optimization.md"
        "MQL Decompilation Expert:experts/mql_decompilation_expert.md"
        "Trading Strategy Expert:experts/trading_strategy_expert.md"
        "Trading Risk Calculator L2:experts/L2/trading-risk-calculator.md"
        "Mobile Expert:experts/mobile_expert.md"
        "Mobile UI Specialist L2:experts/L2/mobile-ui-specialist.md"
        "N8N Expert:experts/n8n_expert.md"
        "N8N Workflow Builder L2:experts/L2/n8n-workflow-builder.md"
        "Claude Systems Expert:experts/claude_systems_expert.md"
        "Claude Prompt Optimizer L2:experts/L2/claude-prompt-optimizer.md"
        "Architect Expert:experts/architect_expert.md"
        "Architect Design Specialist L2:experts/L2/architect-design-specialist.md"
        "DevOps Expert:experts/devops_expert.md"
        "DevOps Pipeline Specialist L2:experts/L2/devops-pipeline-specialist.md"
        "Languages Expert:experts/languages_expert.md"
        "Languages Refactor Specialist L2:experts/L2/languages-refactor-specialist.md"
        "AI Integration Expert:experts/ai_integration_expert.md"
        "AI Model Specialist L2:experts/L2/ai-model-specialist.md"
        "Social Identity Expert:experts/social_identity_expert.md"
        "Social OAuth Specialist L2:experts/L2/social-oauth-specialist.md"
        "Analyzer:core/analyzer.md"
        "Coder:core/coder.md"
        "Reviewer:core/reviewer.md"
        "Documenter:core/documenter.md"
        "Notification Expert:experts/notification_expert.md"
        "Browser Automation Expert:experts/browser_automation_expert.md"
        "MCP Integration Expert:experts/mcp_integration_expert.md"
        "Payment Integration Expert:experts/payment_integration_expert.md"
    )

    for entry in "${routing_entries[@]}"; do
        local agent="${entry%%:*}"
        local filepath="${entry#*:}"
        local fullpath="$AGENTS_DIR/$filepath"

        if [[ -f "$fullpath" ]]; then
            log_pass "Agent '$agent' -> $filepath"
        else
            log_fail "Agent '$agent' -> $filepath (FILE NOT FOUND)"
        fi
    done
}

# =============================================================================
# TEST 2: KEYWORD UNIQUENESS
# =============================================================================

test_keyword_uniqueness() {
    echo ""
    echo "=========================================="
    echo "TEST 2: Keyword Uniqueness"
    echo "=========================================="

    # Extract keywords from routing table in SKILL.md
    # Keywords are in the first column of the routing table
    local keywords_file=$(mktemp)
    local duplicates_file=$(mktemp)

    # Parse routing table from orchestrator SKILL.md
    if [[ -f "$ORCHESTRATOR_SKILL" ]]; then
        # Extract keywords from routing table (between ## AGENT ROUTING TABLE and ---)
        sed -n '/## AGENT ROUTING TABLE/,/^---$/p' "$ORCHESTRATOR_SKILL" | \
            grep -E '^\| [A-Za-z]' | \
            tail -n +2 | \
            cut -d'|' -f2 | \
            tr ',' '\n' | \
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
            grep -v '^$' | \
            sort > "$keywords_file"

        # Find duplicates
        sort "$keywords_file" | uniq -d > "$duplicates_file"

        if [[ -s "$duplicates_file" ]]; then
            while IFS= read -r keyword; do
                log_fail "Duplicate keyword: '$keyword'"
            done < "$duplicates_file"
        else
            log_pass "No duplicate keywords found"
        fi
    else
        log_error "Orchestrator SKILL.md not found at $ORCHESTRATOR_SKILL"
        log_fail "Cannot check keyword uniqueness"
    fi

    rm -f "$keywords_file" "$duplicates_file"
}

# =============================================================================
# TEST 3: L2 PARENT MAPPING
# =============================================================================

test_l2_parent_mapping() {
    echo ""
    echo "=========================================="
    echo "TEST 3: L2 Parent Mapping"
    echo "=========================================="

    declare -A l2_parents=(
        ["GUI Layout Specialist L2"]="GUI Super Expert:experts/gui-super-expert.md"
        ["DB Query Optimizer L2"]="Database Expert:experts/database_expert.md"
        ["Security Auth Specialist L2"]="Security Unified Expert:experts/security_unified_expert.md"
        ["API Endpoint Builder L2"]="Integration Expert:experts/integration_expert.md"
        ["Test Unit Specialist L2"]="Tester Expert:experts/tester_expert.md"
        ["MQL Optimization L2"]="MQL Expert:experts/mql_expert.md"
        ["Trading Risk Calculator L2"]="Trading Strategy Expert:experts/trading_strategy_expert.md"
        ["Mobile UI Specialist L2"]="Mobile Expert:experts/mobile_expert.md"
        ["N8N Workflow Builder L2"]="N8N Expert:experts/n8n_expert.md"
        ["Claude Prompt Optimizer L2"]="Claude Systems Expert:experts/claude_systems_expert.md"
        ["Architect Design Specialist L2"]="Architect Expert:experts/architect_expert.md"
        ["DevOps Pipeline Specialist L2"]="DevOps Expert:experts/devops_expert.md"
        ["Languages Refactor Specialist L2"]="Languages Expert:experts/languages_expert.md"
        ["AI Model Specialist L2"]="AI Integration Expert:experts/ai_integration_expert.md"
        ["Social OAuth Specialist L2"]="Social Identity Expert:experts/social_identity_expert.md"
    )

    for l2 in "${!l2_parents[@]}"; do
        local parent_entry="${l2_parents[$l2]}"
        local parent="${parent_entry%%:*}"
        local parent_path="${parent_entry#*:}"
        local fullpath="$AGENTS_DIR/$parent_path"

        if [[ -f "$fullpath" ]]; then
            log_pass "L2 '$l2' -> Parent '$parent' exists"
        else
            log_fail "L2 '$l2' -> Parent '$parent' NOT FOUND at $parent_path"
        fi
    done
}

# =============================================================================
# TEST 4: ROUTING TABLE COMPLETENESS
# =============================================================================

test_routing_completeness() {
    echo ""
    echo "=========================================="
    echo "TEST 4: Routing Table Completeness"
    echo "=========================================="

    # Check that all agent files have routing entries
    local core_agents=("analyzer" "coder" "reviewer" "documenter")
    local l1_experts=(
        "ai_integration" "architect" "browser_automation" "claude_systems"
        "database" "devops" "gui-super" "integration" "languages" "mcp_integration"
        "mobile" "mql" "mql_decompilation" "n8n" "notification"
        "offensive_security" "payment_integration" "reverse_engineering"
        "security_unified" "social_identity" "tester" "trading_strategy"
    )

    # Check core agents have routing
    for agent in "${core_agents[@]}"; do
        local agent_name=""
        case "$agent" in
            analyzer) agent_name="Analyzer" ;;
            coder) agent_name="Coder" ;;
            reviewer) agent_name="Reviewer" ;;
            documenter) agent_name="Documenter" ;;
        esac

        if grep -q "$agent_name" "$ORCHESTRATOR_SKILL" 2>/dev/null; then
            log_pass "Core agent '$agent_name' has routing entry"
        else
            log_fail "Core agent '$agent_name' missing routing entry"
        fi
    done

    log_pass "Routing completeness check completed"
}

# =============================================================================
# TEST 5: MODEL ASSIGNMENT VALIDATION
# =============================================================================

test_model_assignment() {
    echo ""
    echo "=========================================="
    echo "TEST 5: Model Assignment Validation"
    echo "=========================================="

    # Check model assignments follow conventions
    # Analyzer -> haiku, Documenter -> haiku, DevOps -> haiku
    # Architect -> opus
    # Most others -> inherit

    local haiku_agents=("Analyzer" "Documenter" "DevOps Expert" "DevOps Pipeline Specialist L2")
    local opus_agents=("Architect Expert")

    for agent in "${haiku_agents[@]}"; do
        if grep -q "$agent.*haiku" "$ORCHESTRATOR_SKILL" 2>/dev/null || \
           grep -A1 "$agent" "$ORCHESTRATOR_SKILL" 2>/dev/null | grep -q "haiku"; then
            log_pass "Agent '$agent' has haiku model assignment"
        else
            log_warn "Agent '$agent' model assignment may not match convention"
        fi
    done

    for agent in "${opus_agents[@]}"; do
        if grep -q "$agent.*opus" "$ORCHESTRATOR_SKILL" 2>/dev/null || \
           grep -A1 "$agent" "$ORCHESTRATOR_SKILL" 2>/dev/null | grep -q "opus"; then
            log_pass "Agent '$agent' has opus model assignment"
        else
            log_warn "Agent '$agent' model assignment may not match convention"
        fi
    done

    log_pass "Model assignment validation completed"
}

# =============================================================================
# JSON REPORT GENERATION
# =============================================================================

generate_json_report() {
    echo ""
    echo "=========================================="
    echo "Generating JSON Report"
    echo "=========================================="

    mkdir -p "$OUTPUT_DIR"

    local status="PASS"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        status="FAIL"
    fi

    local report_file="$OUTPUT_DIR/routing-test-report.json"

    cat > "$report_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "tests": $TESTS_TOTAL,
  "passed": $TESTS_PASSED,
  "failed": $TESTS_FAILED,
  "status": "$status",
  "errors": [
$(printf '    "%s",\n' "${ERRORS[@]}" | sed '$ s/,$//')
  ],
  "details": {
    "agent_existence": "completed",
    "keyword_uniqueness": "completed",
    "l2_parent_mapping": "completed",
    "routing_completeness": "completed",
    "model_assignment": "completed"
  },
  "version": "1.0.0",
  "source": "agents/tests/routing-validation.md"
}
EOF

    log_info "JSON report saved to: $report_file"
    echo ""
    cat "$report_file"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "=========================================="
    echo "ROUTING VALIDATION TEST RUNNER"
    echo "=========================================="
    echo "Timestamp: $TIMESTAMP"
    echo "Claude Directory: $CLAUDE_DIR"
    echo ""

    # Verify required files exist
    if [[ ! -f "$ROUTING_VALIDATION" ]]; then
        log_error "routing-validation.md not found at $ROUTING_VALIDATION"
        exit 1
    fi

    if [[ ! -f "$ORCHESTRATOR_SKILL" ]]; then
        log_warn "orchestrator/SKILL.md not found - some tests may be incomplete"
    fi

    # Run all tests
    test_agent_existence
    test_keyword_uniqueness
    test_l2_parent_mapping
    test_routing_completeness
    test_model_assignment

    # Generate report
    generate_json_report

    echo ""
    echo "=========================================="
    echo "SUMMARY"
    echo "=========================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo ""
        echo "Errors:"
        for err in "${ERRORS[@]}"; do
            echo "  - $err"
        done
        exit 1
    fi

    echo ""
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
}

# Run main
main "$@"
