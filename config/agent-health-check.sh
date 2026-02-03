#!/bin/bash

# Agent Health Check Script
# Verifica la disponibilità degli Expert Agents

CONFIG_FILE="$HOME/.claude/config/agent-registry.json"
LOG_FILE="$HOME/.claude/config/agent-health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione di logging
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Funzione per verificare se jq è installato
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_message "${RED}[ERROR] jq non è installato. Installalo per processare JSON.${NC}"
        exit 1
    fi
}

# Funzione per verificare esistenza file agent
check_file_exists() {
    local file_path="$1"
    local agent_id="$2"

    # Espandi ~ per path assoluto
    local expanded_path="${file_path/#\~/$HOME}"

    if [[ -f "$expanded_path" ]]; then
        log_message "${GREEN}[OK] $agent_id: File esistente${NC}"
        return 0
    else
        log_message "${RED}[FAIL] $agent_id: File non trovato - $expanded_path${NC}"
        return 1
    fi
}

# Funzione per validare contenuto agent
validate_agent_content() {
    local file_path="$1"
    local agent_id="$2"

    # Espandi ~ per path assoluto
    local expanded_path="${file_path/#\~/$HOME}"

    if head -5 "$expanded_path" | grep -q "EXPERT AGENT"; then
        log_message "${GREEN}[OK] $agent_id: Contenuto valido${NC}"
        return 0
    else
        log_message "${YELLOW}[WARN] $agent_id: Contenuto non standard${NC}"
        return 1
    fi
}

# Funzione per aggiornare timestamp nell'agent registry
update_health_timestamp() {
    local agent_id="$1"
    local status="$2"
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Aggiorna il timestamp dell'health check
    local temp_file=$(mktemp)
    jq ".agents.${agent_id}.availability.last_health_check = \"$timestamp\" | .agents.${agent_id}.availability.status = \"$status\"" "$CONFIG_FILE" > "$temp_file"
    mv "$temp_file" "$CONFIG_FILE"
}

# Funzione principale di health check
run_health_check() {
    log_message "${YELLOW}[INFO] Avvio Health Check degli Expert Agents${NC}"

    local total_agents=0
    local healthy_agents=0
    local failed_agents=0

    # Estrai lista degli agent dal JSON
    while IFS= read -r agent_id; do
        total_agents=$((total_agents + 1))

        # Estrai informazioni dell'agent
        local file_path=$(jq -r ".agents.${agent_id}.file_path" "$CONFIG_FILE")
        local status=$(jq -r ".agents.${agent_id}.status" "$CONFIG_FILE")

        log_message "${YELLOW}[CHECK] Verificando $agent_id...${NC}"

        # Salta agent inattivi
        if [[ "$status" == "inactive" ]]; then
            log_message "${YELLOW}[SKIP] $agent_id: Agent inattivo${NC}"
            continue
        fi

        # Verifica esistenza file
        if check_file_exists "$file_path" "$agent_id"; then
            # Verifica contenuto
            if validate_agent_content "$file_path" "$agent_id"; then
                update_health_timestamp "$agent_id" "active"
                healthy_agents=$((healthy_agents + 1))
            else
                update_health_timestamp "$agent_id" "degraded"
                failed_agents=$((failed_agents + 1))
            fi
        else
            update_health_timestamp "$agent_id" "unavailable"
            failed_agents=$((failed_agents + 1))
        fi

    done < <(jq -r '.agents | keys[]' "$CONFIG_FILE")

    # Report finale
    log_message "${YELLOW}[SUMMARY] Health Check Completato${NC}"
    log_message "- Totale agents: $total_agents"
    log_message "- ${GREEN}Healthy: $healthy_agents${NC}"
    log_message "- ${RED}Failed: $failed_agents${NC}"

    # Calcola success rate
    if [[ $total_agents -gt 0 ]]; then
        local success_rate=$((healthy_agents * 100 / total_agents))
        log_message "- Success Rate: ${success_rate}%"

        # Alert se success rate troppo basso
        if [[ $success_rate -lt 70 ]]; then
            log_message "${RED}[ALERT] Success rate sotto soglia critica (70%)${NC}"
        fi
    fi
}

# Funzione per mostrare stato corrente
show_status() {
    log_message "${YELLOW}[STATUS] Stato corrente degli Expert Agents${NC}"

    while IFS= read -r agent_id; do
        local status=$(jq -r ".agents.${agent_id}.availability.status" "$CONFIG_FILE")
        local last_check=$(jq -r ".agents.${agent_id}.availability.last_health_check" "$CONFIG_FILE")
        local priority=$(jq -r ".agents.${agent_id}.priority_level" "$CONFIG_FILE")

        case $status in
            "active"|"always_available")
                echo -e "${GREEN}✓${NC} $agent_id (Priority: $priority) - Last check: $last_check"
                ;;
            "degraded"|"on_demand")
                echo -e "${YELLOW}⚠${NC} $agent_id (Priority: $priority) - Last check: $last_check"
                ;;
            "unavailable"|"inactive")
                echo -e "${RED}✗${NC} $agent_id (Priority: $priority) - Last check: $last_check"
                ;;
        esac
    done < <(jq -r '.agents | keys[]' "$CONFIG_FILE")
}

# Funzione per verificare fallback disponibili
check_fallbacks() {
    local agent_id="$1"

    local primary_fallback=$(jq -r ".fallback_strategies.cascading_rules.${agent_id}.primary_fallback" "$CONFIG_FILE")
    local secondary_fallback=$(jq -r ".fallback_strategies.cascading_rules.${agent_id}.secondary_fallback" "$CONFIG_FILE")

    log_message "${YELLOW}[FALLBACK] Verificando fallback per $agent_id${NC}"

    # Verifica primary fallback
    if [[ "$primary_fallback" != "null" ]]; then
        local primary_status=$(jq -r ".agents.${primary_fallback}.availability.status" "$CONFIG_FILE")
        if [[ "$primary_status" == "active" ]] || [[ "$primary_status" == "always_available" ]]; then
            log_message "${GREEN}[OK] Primary fallback disponibile: $primary_fallback${NC}"
        else
            log_message "${RED}[FAIL] Primary fallback non disponibile: $primary_fallback${NC}"
        fi
    fi

    # Verifica secondary fallback
    if [[ "$secondary_fallback" != "null" ]]; then
        local secondary_status=$(jq -r ".agents.${secondary_fallback}.availability.status" "$CONFIG_FILE")
        if [[ "$secondary_status" == "active" ]] || [[ "$secondary_status" == "always_available" ]]; then
            log_message "${GREEN}[OK] Secondary fallback disponibile: $secondary_fallback${NC}"
        else
            log_message "${RED}[FAIL] Secondary fallback non disponibile: $secondary_fallback${NC}"
        fi
    fi
}

# Main script
main() {
    # Verifica prerequisiti
    check_jq

    # Verifica che il file di configurazione esista
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_message "${RED}[ERROR] File di configurazione non trovato: $CONFIG_FILE${NC}"
        exit 1
    fi

    # Parsing argomenti
    case "${1:-check}" in
        "check")
            run_health_check
            ;;
        "status")
            show_status
            ;;
        "fallback")
            if [[ -z "$2" ]]; then
                log_message "${RED}[ERROR] Specifica un agent_id per verificare i fallback${NC}"
                exit 1
            fi
            check_fallbacks "$2"
            ;;
        "help")
            echo "Uso: $0 [check|status|fallback <agent_id>|help]"
            echo "  check    - Esegue health check completo"
            echo "  status   - Mostra stato corrente"
            echo "  fallback - Verifica fallback per agent specifico"
            echo "  help     - Mostra questo aiuto"
            ;;
        *)
            log_message "${RED}[ERROR] Comando non riconosciuto: $1${NC}"
            echo "Usa '$0 help' per vedere i comandi disponibili"
            exit 1
            ;;
    esac
}

# Esegui main con tutti gli argomenti
main "$@"