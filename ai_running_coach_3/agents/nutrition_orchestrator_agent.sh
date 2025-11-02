#!/bin/bash
export AGENT_NAME="nutrition_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "NutritionOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing NutritionOrchestratorAgent"
    write_knowledge "nutrition" "orchestrator_state" '{"status": "initialized"}'
}

generate_response() {
    local intent="$1"
    local message="$2"
    
    log_agent "INFO" "Generating nutrition response for intent: ${intent}"
    
    local prompt=""
    case "${intent}" in
        meal|nutrition)
            prompt="You are a sports nutritionist specializing in endurance running. Provide practical meal/nutrition advice for: '${message}'.

Include:
- Specific foods and portions
- Timing recommendations
- Focus on carbohydrate loading, protein recovery, and race-day fueling

Keep response under 150 words."
            ;;
        hydration)
            prompt="You are a sports nutritionist. Provide detailed hydration advice for: '${message}'.

Include:
- Fluid amounts (ml/hour)
- Timing recommendations
- Electrolyte recommendations
- Signs of proper hydration

Keep under 120 words."
            ;;
        *)
            prompt="You are a sports nutritionist for endurance runners. Provide helpful advice for: '${message}'. Keep under 100 words."
            ;;
    esac
    
    log_agent "INFO" "Calling Gemini CLI"
    local response=$(call_gemini "${prompt}")
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        log_agent "ERROR" "Failed to generate response"
        echo "I apologize, but I'm having trouble generating nutrition advice. Please try again."
        return 1
    fi
    
    response=$(echo "$response" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '\n' ' ' | sed 's/  */ /g')
    
    log_agent "INFO" "Generated response (${#response} chars)"
    echo "$response"
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "$msg_count" -gt 0 ]; then
        log_agent "INFO" "Found ${msg_count} new delegation(s)"
    fi
    
    local processed=0
    
    while read -r message; do
        [ -z "$message" ] && continue
        local msg_type=$(extract_field "${message}" '.type')
        local msg_id=$(extract_field "${message}" '.id')
        local msg_timestamp=$(extract_field "${message}" '.timestamp')
        
        if [ "${msg_type}" != "nutrition_delegation" ]; then
            continue
        fi
        
        local request_id=$(extract_field "${message}" '.data.request_id')
        local intent=$(extract_field "${message}" '.data.intent' 'nutrition')
        local user_message=$(extract_field "${message}" '.data.message')
        
        if [ -z "$request_id" ] || [ -z "$user_message" ]; then
            log_agent "WARN" "Skipping delegation ${msg_id} - missing required fields"
            archive_message "delegation_commands" "${msg_id}"
            continue
        fi
        
        log_agent "INFO" "Handling nutrition delegation for request ${request_id}"
        log_agent "INFO" "Intent: ${intent}, Message: ${user_message}"
        
        local ai_response=$(generate_response "${intent}" "${user_message}")
        
        if [ -z "$ai_response" ]; then
            log_agent "ERROR" "Empty response generated"
            ai_response="I apologize, but I could not generate a nutrition response at this time. Please try again."
        fi
        
        local response_data=$(jq -n \
            --arg rid "$request_id" \
            --arg resp "$ai_response" \
            --arg src "nutrition_orchestrator" \
            '{
                request_id: $rid,
                response: $resp,
                source: $src
            }')
        
        local response_msg_id=$(publish_message "synthesized_responses" "nutrition_response" "$response_data")
        
        log_agent "INFO" "Published response ${response_msg_id} for request ${request_id}"
        
        LAST_SEEN_TIMESTAMP="${msg_timestamp}"
        archive_message "delegation_commands" "${msg_id}"
    done
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
