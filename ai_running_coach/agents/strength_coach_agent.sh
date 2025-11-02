#!/bin/bash
export AGENT_NAME="strength_coach"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "StrengthCoachAgent starting..."

initialize() {
    log_agent "INFO" "Initializing StrengthCoachAgent"
}

process_directives() {
    local messages=$(subscribe_channel "strength_directives" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} strength directive(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_type=$(echo "${message}" | jq -r '.type')
            
            case "${msg_type}" in
                generate_workout)
                    generate_strength_workout "${message}"
                    ;;
            esac
        done
    fi
}

generate_strength_workout() {
    local message=$1
    local request_id=$(echo "${message}" | jq -r '.data.request_id')
    local training_plan=$(echo "${message}" | jq -r '.data.training_plan')
    local user_id=$(echo "${message}" | jq -r '.data.user_id')
    
    log_agent "INFO" "Generating strength workout for user: ${user_id}"
    
    local user_profile=$(read_knowledge "user_profile" "${user_id}")
    
    # Generate workout using Python
    local workout=$(python3 "${PROJECT_ROOT}/python/generate_strength_workout.py" <<EOF
{
    "user_profile": ${user_profile},
    "training_plan": ${training_plan}
}
EOF
)
    
    # Store workout
    local workout_id="strength_$(date +%Y%m%d_%H%M%S)"
    write_knowledge "strength_workouts" "${workout_id}" "${workout}"
    
    # Publish response
    publish_message "synthesized_responses" "strength_workout_ready" "{
        \"request_id\": \"${request_id}\",
        \"workout_id\": \"${workout_id}\",
        \"workout\": ${workout}
    }"
    
    log_agent "INFO" "Strength workout generated: ${workout_id}"
}

main_loop() {
    while should_run; do
        process_directives
        sleep_interval
    done
    
    log_agent "INFO" "StrengthCoachAgent shutting down"
}

initialize
main_loop
