#!/bin/bash

# OrchestratorAgent - Central coordinator of the multi-agent system
# Receives requests and delegates to appropriate sub-orchestrators

export AGENT_NAME="orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the data bus library
source "${PROJECT_ROOT}/lib/databus.sh"

# Agent state
LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "OrchestratorAgent starting..."

# Initialize agent
initialize() {
    log_agent "INFO" "Initializing OrchestratorAgent"
    
    # Read system configuration
    local config=$(cat "${CONFIG_DIR}/system_config.json")
    
    # Initialize agent state in knowledge base
    write_knowledge "system" "orchestrator_state" '{
        "status": "initialized",
        "active_delegations": []
    }'
}

# Process user requests
process_user_requests() {
    local messages=$(subscribe_channel "user_requests" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} user request(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local msg_type=$(echo "${message}" | jq -r '.type')
            local intent=$(echo "${message}" | jq -r '.data.intent // empty')
            local msg_timestamp=$(echo "${message}" | jq -r '.timestamp')
            
            log_agent "INFO" "Processing message ${msg_id} with intent: ${intent}"
            
            # Route based on intent
            case "${intent}" in
                training_plan|workout|exercise|strength)
                    delegate_to_training "${message}"
                    ;;
                nutrition|meal|food|hydration)
                    delegate_to_nutrition "${message}"
                    ;;
                injury|pain|rehab|prehab)
                    delegate_to_injury "${message}"
                    ;;
                analysis|progress|data)
                    request_data_analysis "${message}"
                    ;;
                daily_briefing)
                    generate_daily_briefing "${message}"
                    ;;
                *)
                    log_agent "WARN" "Unknown intent: ${intent}"
                    publish_message "synthesized_responses" "error_response" "{
                        \"request_id\": \"${msg_id}\",
                        \"error\": \"Unable to understand request intent\"
                    }"
                    ;;
            esac
            
            # Update last seen timestamp
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            archive_message "user_requests" "${msg_id}"
        done
    fi
}

# Delegate to training orchestrator
delegate_to_training() {
    local message=$1
    local msg_id=$(echo "${message}" | jq -r '.id')
    
    log_agent "INFO" "Delegating to TrainingOrchestratorAgent: ${msg_id}"
    
    publish_message "delegation_commands" "training_delegation" "{
        \"original_request\": ${message},
        \"priority\": \"normal\",
        \"requires_response\": true
    }"
}

# Delegate to nutrition orchestrator
delegate_to_nutrition() {
    local message=$1
    local msg_id=$(echo "${message}" | jq -r '.id')
    
    log_agent "INFO" "Delegating to NutritionOrchestratorAgent: ${msg_id}"
    
    publish_message "delegation_commands" "nutrition_delegation" "{
        \"original_request\": ${message},
        \"priority\": \"normal\",
        \"requires_response\": true
    }"
}

# Delegate to injury orchestrator
delegate_to_injury() {
    local message=$1
    local msg_id=$(echo "${message}" | jq -r '.id')
    
    log_agent "INFO" "Delegating to InjuryOrchestratorAgent: ${msg_id}"
    
    publish_message "delegation_commands" "injury_delegation" "{
        \"original_request\": ${message},
        \"priority\": \"high\",
        \"requires_response\": true
    }"
}

# Request data analysis
request_data_analysis() {
    local message=$1
    local msg_id=$(echo "${message}" | jq -r '.id')
    
    log_agent "INFO" "Requesting data analysis: ${msg_id}"
    
    publish_message "delegation_commands" "data_analysis_request" "{
        \"original_request\": ${message},
        \"analysis_type\": \"comprehensive\",
        \"requires_response\": true
    }"
}

# Generate daily briefing (cross-domain synthesis)
generate_daily_briefing() {
    local message=$1
    local msg_id=$(echo "${message}" | jq -r '.id')
    
    log_agent "INFO" "Generating daily briefing: ${msg_id}"
    
    # This would typically call Python script for complex synthesis
    "${PROJECT_ROOT}/python/generate_briefing.py" "${msg_id}" &
    
    log_agent "INFO" "Daily briefing generation initiated"
}

# Process data alerts
process_data_alerts() {
    local messages=$(subscribe_channel "data_alerts" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} data alert(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local alert_type=$(echo "${message}" | jq -r '.data.alert_type // empty')
            local severity=$(echo "${message}" | jq -r '.data.severity // "medium"')
            
            log_agent "WARN" "Data alert received: ${alert_type} (severity: ${severity})"
            
            # Route alert to appropriate sub-orchestrator
            case "${alert_type}" in
                overtraining|fatigue)
                    publish_message "delegation_commands" "training_alert" "{
                        \"alert\": ${message},
                        \"action_required\": true
                    }"
                    ;;
                injury_risk)
                    publish_message "delegation_commands" "injury_alert" "{
                        \"alert\": ${message},
                        \"action_required\": true
                    }"
                    ;;
                nutritional_gap)
                    publish_message "delegation_commands" "nutrition_alert" "{
                        \"alert\": ${message},
                        \"action_required\": true
                    }"
                    ;;
            esac
            
            archive_message "data_alerts" "${msg_id}"
        done
    fi
}

# Main agent loop
main_loop() {
    while should_run; do
        process_user_requests
        process_data_alerts
        sleep_interval
    done
    
    log_agent "INFO" "OrchestratorAgent shutting down"
}

# Start the agent
initialize
main_loop
