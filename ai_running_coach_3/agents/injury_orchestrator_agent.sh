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

generate_response() {
    local intent="$1"
    local message="$2"
    
    log_agent "INFO" "Generating injury response for intent: ${intent}"
    
    local prompt=""
    case "${intent}" in
        injury|pain)
            prompt="You are a running coach with injury prevention expertise. Respond to: '${message}'.

Provide CAUTIOUS advice:
- Use the RICE protocol (Rest, Ice, Compression, Elevation) where appropriate
- ALWAYS emphasize seeing a healthcare professional for persistent pain or injury
- Suggest modified training only if appropriate

Keep under 150 words."
            ;;
        rehab)
            prompt="You are a running coach helping with injury rehabilitation. Respond to: '${message}'.

Provide safe return-to-running advice:
- Gradual progression (walk-run method)
- 10% weekly mileage increase rule
- Emphasize professional guidance from physical therapist or sports doctor

Keep under 150 words."
            ;;
        *)
            prompt="You are a running coach focused on injury prevention. Respond helpfully to: '${message}'. Always prioritize runner safety. Keep under 100 words."
            ;;
    esac
    
    log_agent "INFO" "Calling Gemini CLI"
    local response=$(call_gemini "${prompt}")
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        log_agent "ERROR" "Failed to generate response"
        echo "For any pain or injury concerns, please consult with a healthcare professional. I cannot provide medical advice."
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
        log_agent "INFO" "Processing ${msg_count} delegation(s)"
    fi
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(extract_field "${message}" '.type')
        local msg_id=$(extract_field "${message}" '.id')
        local msg_timestamp=$(extract_field "${message}" '.timestamp')
        
        if [ "${msg_type}" != "injury_delegation" ]; then
            continue
        fi
        
        local request_id=$(extract_field "${message}" '.data.request_id')
        local intent=$(extract_field "${message}" '.data.intent' 'injury')
        local user_message=$(extract_field "${message}" '.data.message')
        
        if [ -z "$request_id" ] || [ -z "$user_message" ]; then
            log_agent "WARN" "Skipping delegation ${msg_id} - missing required fields"
            archive_message "delegation_commands" "${msg_id}"
            continue
        fi
        
        log_agent "INFO" "Handling injury delegation for request ${request_id}"
        log_agent "INFO" "Intent: ${intent}, Message: ${user_message}"
        
        local ai_response=$(generate_response "${intent}" "${user_message}")
        
        if [ -z "$ai_response" ]; then
            log_agent "ERROR" "Empty response generated"
            ai_response="For any pain or injury concerns, please consult with a healthcare professional. I cannot provide medical advice."
        fi
        
        local response_data=$(jq -n \
            --arg rid "$request_id" \
            --arg resp "$ai_response" \
            --arg src "injury_orchestrator" \
            '{
                request_id: $rid,
                response: $resp,
                source: $src
            }')
        
        local response_msg_id=$(publish_message "synthesized_responses" "injury_response" "$response_data")
        
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
    log_agent "INFO" "InjuryOrchestratorAgent shutting down"
}

initialize
main_loop
