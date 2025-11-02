#!/bin/bash
export AGENT_NAME="user_interaction"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "UserInteractionAgent starting..."

initialize() {
    log_agent "INFO" "Initializing UserInteractionAgent"
    write_knowledge "system" "user_interaction_state" '{
        "status": "initialized",
        "active_conversations": []
    }'
}

process_user_input() {
    # Check for new user input file
    local input_file="${DATA_BUS_DIR}/incoming/user_input.txt"
    if [ -f "${input_file}" ]; then
        local user_message=$(cat "${input_file}")
        rm "${input_file}"
        
        log_agent "INFO" "Processing user input: ${user_message}"
        
        # Parse user intent using Python NLP helper
        local intent=$(python3 "${PROJECT_ROOT}/python/parse_intent.py" <<< "${user_message}")
        
        # Publish to data bus
        publish_message "user_requests" "user_message" "{
            \"intent\": \"${intent}\",
            \"message\": $(echo "${user_message}" | jq -Rs .),
            \"user_id\": \"default_user\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"
        }"
        
        log_agent "INFO" "User request published with intent: ${intent}"
    fi
}

present_responses() {
    local messages=$(subscribe_channel "synthesized_responses" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Presenting ${msg_count} response(s) to user"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local msg_type=$(echo "${message}" | jq -r '.type')
            local msg_timestamp=$(echo "${message}" | jq -r '.timestamp')
            
            # Format and display response
            local response_file="${DATA_BUS_DIR}/processed/response_${msg_id}.txt"
            echo "${message}" | jq -r '.data | to_entries | .[] | "\(.key): \(.value)"' > "${response_file}"
            
            log_agent "INFO" "Response saved to: ${response_file}"
            
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            archive_message "synthesized_responses" "${msg_id}"
        done
    fi
}

collect_daily_journal() {
    local journal_file="${DATA_BUS_DIR}/incoming/daily_journal.json"
    if [ -f "${journal_file}" ]; then
        local journal_data=$(cat "${journal_file}")
        local date=$(date +%Y-%m-%d)
        
        write_knowledge "daily_journals" "${date}" "${journal_data}"
        
        publish_message "delegation_commands" "journal_logged" "{
            \"date\": \"${date}\",
            \"journal\": ${journal_data}
        }"
        
        rm "${journal_file}"
        log_agent "INFO" "Daily journal logged for ${date}"
    fi
}

collect_food_log() {
    local food_file="${DATA_BUS_DIR}/incoming/food_log.json"
    if [ -f "${food_file}" ]; then
        local food_data=$(cat "${food_file}")
        local date=$(date +%Y-%m-%d)
        
        write_knowledge "food_logs" "${date}" "${food_data}"
        
        publish_message "delegation_commands" "food_logged" "{
            \"date\": \"${date}\",
            \"food_log\": ${food_data}
        }"
        
        rm "${food_file}"
        log_agent "INFO" "Food log saved for ${date}"
    fi
}

main_loop() {
    while should_run; do
        process_user_input
        present_responses
        collect_daily_journal
        collect_food_log
        sleep_interval
    done
    
    log_agent "INFO" "UserInteractionAgent shutting down"
}

initialize
main_loop
