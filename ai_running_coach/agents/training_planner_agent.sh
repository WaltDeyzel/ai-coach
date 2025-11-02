#!/bin/bash
export AGENT_NAME="training_planner"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "TrainingPlannerAgent starting..."

initialize() {
    log_agent "INFO" "Initializing TrainingPlannerAgent"
}

process_directives() {
    local messages=$(subscribe_channel "training_directives" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} training directive(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_type=$(echo "${message}" | jq -r '.type')
            local msg_id=$(echo "${message}" | jq -r '.id')
            
            case "${msg_type}" in
                generate_plan)
                    generate_training_plan "${message}"
                    ;;
                adjust_plan)
                    adjust_training_plan "${message}"
                    ;;
                reduce_load)
                    reduce_training_load "${message}"
                    ;;
            esac
            
            archive_message "training_directives" "${msg_id}"
        done
    fi
}

generate_training_plan() {
    local message=$1
    local user_profile=$(echo "${message}" | jq -r '.data.user_profile')
    local request_id=$(echo "${message}" | jq -r '.data.request_id')
    
    log_agent "INFO" "Generating new training plan"
    
    # Generate plan using Python
    local training_plan=$(python3 "${PROJECT_ROOT}/python/generate_training_plan.py" <<< "${user_profile}")
    
    # Store plan
    write_knowledge "training_plans" "current" "${training_plan}"
    
    # Publish response
    publish_message "synthesized_responses" "training_plan_created" "{
        \"request_id\": \"${request_id}\",
        \"plan\": ${training_plan},
        \"status\": \"success\"
    }"
    
    log_agent "INFO" "Training plan generated and stored"
}

adjust_training_plan() {
    local message=$1
    local current_plan=$(echo "${message}" | jq -r '.data.current_plan')
    local reason=$(echo "${message}" | jq -r '.data.reason')
    
    log_agent "INFO" "Adjusting training plan, reason: ${reason}"
    
    # Adjust using Python
    local adjusted_plan=$(python3 "${PROJECT_ROOT}/python/adjust_training_plan.py" <<< "${current_plan}")
    
    write_knowledge "training_plans" "current" "${adjusted_plan}"
    
    publish_message "synthesized_responses" "plan_adjusted" "{
        \"plan\": ${adjusted_plan},
        \"reason\": \"${reason}\"
    }"
}

reduce_training_load() {
    local message=$1
    local duration_days=$(echo "${message}" | jq -r '.data.duration_days // 7')
    
    log_agent "WARN" "Reducing training load for ${duration_days} days"
    
    local current_plan=$(read_knowledge "training_plans" "current")
    
    # Reduce load using Python
    local reduced_plan=$(python3 "${PROJECT_ROOT}/python/reduce_training_load.py" "${duration_days}" <<< "${current_plan}")
    
    write_knowledge "training_plans" "current" "${reduced_plan}"
    
    log_agent "INFO" "Training load reduced"
}

main_loop() {
    while should_run; do
        process_directives
        sleep_interval
    done
    
    log_agent "INFO" "TrainingPlannerAgent shutting down"
}

initialize
main_loop
