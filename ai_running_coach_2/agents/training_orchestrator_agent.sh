#!/bin/bash
export AGENT_NAME="training_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "TrainingOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing TrainingOrchestratorAgent"
    write_knowledge "training" "orchestrator_state" '{"status": "initialized"}'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        if [ "${msg_type}" = "training_delegation" ]; then
            local original_request=$(echo "${message}" | jq -r '.data.original_request')
            local intent=$(echo "${original_request}" | jq -r '.data.intent')
            
            log_agent "INFO" "Handling training delegation: ${intent}"
            
            case "${intent}" in
                training_plan)
                    publish_message "training_directives" "generate_plan" "{\"request\": ${original_request}}"
                    ;;
                workout)
                    publish_message "training_directives" "get_workout" "{\"request\": ${original_request}}"
                    ;;
                strength)
                    publish_message "strength_directives" "generate_workout" "{\"request\": ${original_request}}"
                    ;;
            esac
        fi
    done
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    log_agent "INFO" "TrainingOrchestratorAgent shutting down"
}

initialize
main_loop
