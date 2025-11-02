#!/bin/bash
export AGENT_NAME="injury_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "InjuryOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing InjuryOrchestratorAgent"
    write_knowledge "injury" "orchestrator_state" '{"status": "initialized", "active_injuries": []}'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        case "${msg_type}" in
            injury_delegation)
                local original_request=$(echo "${message}" | jq -r '.data.original_request')
                log_agent "INFO" "Handling injury delegation"
                publish_message "injury_directives" "assess_risk" "{\"request\": ${original_request}}"
                ;;
            injury_alert)
                log_agent "WARN" "Handling injury alert"
                publish_message "injury_directives" "generate_rehab" "{\"alert\": $(echo "${message}" | jq -c '.data')}"
                ;;
        esac
    done
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    log_agent "INFO" "InjuryOrchestratorAgent shutting down"
}

initialize
main_loop
