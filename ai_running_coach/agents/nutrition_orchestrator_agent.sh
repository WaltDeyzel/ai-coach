#!/bin/bash
export AGENT_NAME="nutrition_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "NutritionOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing NutritionOrchestratorAgent"
    write_knowledge "nutrition" "orchestrator_state" '{
        "status": "initialized"
    }'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        if [ "${msg_type}" = "nutrition_delegation" ]; then
            handle_nutrition_delegation "${message}"
        elif [ "${msg_type}" = "food_logged" ]; then
            trigger_food_analysis "${message}"
        fi
    done
}

handle_nutrition_delegation() {
    local message=$1
    local original_request=$(echo "${message}" | jq -r '.data.original_request')
    local intent=$(echo "${original_request}" | jq -r '.data.intent')
    
    log_agent "INFO" "Handling nutrition delegation: ${intent}"
    
    case "${intent}" in
        meal|nutrition)
            publish_message "nutrition_directives" "generate_meal_plan" "{
                \"original_request\": ${original_request}
            }"
            ;;
        hydration)
            publish_message "nutrition_directives" "hydration_advice" "{
                \"original_request\": ${original_request}
            }"
            ;;
    esac
}

trigger_food_analysis() {
    local message=$1
    local date=$(echo "${message}" | jq -r '.data.date')
    
    publish_message "nutrition_directives" "analyze_food_log" "{
        \"date\": \"${date}\"
    }"
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    
    log_agent "INFO" "NutritionOrchestratorAgent shutting down"
}

initialize
main_loop
