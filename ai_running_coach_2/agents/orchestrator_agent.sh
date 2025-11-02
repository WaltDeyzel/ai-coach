#!/bin/bash
export AGENT_NAME="orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "OrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing OrchestratorAgent"
    write_knowledge "system" "orchestrator_state" '{"status": "initialized", "active_delegations": []}'
}

process_user_requests() {
    local messages=$(subscribe_channel "user_requests" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} user request(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local intent=$(echo "${message}" | jq -r '.data.intent // "general"')
            local msg_timestamp=$(echo "${message}" | jq -r '.timestamp')
            
            log_agent "INFO" "Message ${msg_id} with intent: ${intent}"
            
            case "${intent}" in
                training_plan|workout|exercise)
                    publish_message "delegation_commands" "training_delegation" "{\"original_request\": ${message}}"
                    ;;
                strength)
                    publish_message "delegation_commands" "training_delegation" "{\"original_request\": ${message}}"
                    ;;
                nutrition|meal|food|hydration)
                    publish_message "delegation_commands" "nutrition_delegation" "{\"original_request\": ${message}}"
                    ;;
                injury|pain|rehab)
                    publish_message "delegation_commands" "injury_delegation" "{\"original_request\": ${message}}"
                    ;;
                *)
                    publish_message "synthesized_responses" "general_response" "{\"request_id\": \"${msg_id}\", \"response\": \"Processing your request...\"}"
                    ;;
            esac
            
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            archive_message "user_requests" "${msg_id}"
        done
    fi
}

main_loop() {
    while should_run; do
        process_user_requests
        sleep_interval
    done
    log_agent "INFO" "OrchestratorAgent shutting down"
}

initialize
main_loop
