#!/bin/bash
export AGENT_NAME="user_interaction"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "UserInteractionAgent starting..."

initialize() {
    log_agent "INFO" "Initializing UserInteractionAgent"
    write_knowledge "system" "user_interaction_state" '{"status": "initialized"}'
}

process_user_input() {
    local input_file="${DATA_BUS_DIR}/incoming/user_input.txt"
    if [ -f "${input_file}" ]; then
        local user_message=$(cat "${input_file}")
        rm "${input_file}"
        
        log_agent "INFO" "Processing user input: ${user_message}"
        
        # Use Gemini CLI to parse intent
        local intent_prompt="Analyze this user message and respond with ONLY ONE WORD from this list: training_plan, workout, strength, nutrition, meal, hydration, injury, pain, rehab, analysis, general. Message: ${user_message}"
        local intent=$(call_gemini "${intent_prompt}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | head -1)
        
        log_agent "INFO" "Detected intent: ${intent}"
        
        publish_message "user_requests" "user_message" "{
            \"intent\": \"${intent}\",
            \"message\": $(echo "${user_message}" | jq -Rs .),
            \"user_id\": \"default_user\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }"
    fi
}

present_responses() {
    local messages=$(subscribe_channel "synthesized_responses" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Presenting ${msg_count} response(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local response_file="${DATA_BUS_DIR}/processed/response_${msg_id}.txt"
            echo "${message}" | jq -r '.data | to_entries | .[] | "\(.key): \(.value)"' > "${response_file}"
            archive_message "synthesized_responses" "${msg_id}"
        done
    fi
}

main_loop() {
    while should_run; do
        process_user_input
        present_responses
        sleep_interval
    done
    log_agent "INFO" "UserInteractionAgent shutting down"
}

initialize
main_loop
