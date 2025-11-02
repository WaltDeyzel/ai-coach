#!/bin/bash
export AGENT_NAME="nutritionist"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "NutritionistAgent starting..."

initialize() {
    log_agent "INFO" "Initializing NutritionistAgent"
}

process_directives() {
    local messages=$(subscribe_channel "nutrition_directives" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} nutrition directive(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_type=$(echo "${message}" | jq -r '.type')
            
            case "${msg_type}" in
                analyze_food_log)
                    analyze_food_log "${message}"
                    ;;
                generate_meal_plan)
                    generate_meal_plan "${message}"
                    ;;
                hydration_advice)
                    provide_hydration_advice "${message}"
                    ;;
            esac
        done
    fi
}

analyze_food_log() {
    local message=$1
    local date=$(echo "${message}" | jq -r '.data.date')
    
    log_agent "INFO" "Analyzing food log for: ${date}"
    
    local food_log=$(read_knowledge "food_logs" "${date}")
    
    if [ "${food_log}" != "null" ]; then
        local analysis=$(python3 "${PROJECT_ROOT}/python/analyze_nutrition.py" <<< "${food_log}")
        
        publish_message "synthesized_responses" "nutrition_analysis" "{
            \"date\": \"${date}\",
            \"analysis\": ${analysis}
        }"
    fi
}

generate_meal_plan() {
    local message=$1
    local user_id=$(echo "${message}" | jq -r '.data.user_id')
    
    log_agent "INFO" "Generating meal plan for user: ${user_id}"
    
    local user_profile=$(read_knowledge "user_profile" "${user_id}")
    local training_plan=$(read_knowledge "training_plans" "current")
    
    local meal_plan=$(python3 "${PROJECT_ROOT}/python/generate_meal_plan.py" <<EOF
{
    "user_profile": ${user_profile},
    "training_plan": ${training_plan}
}
EOF
)
    
    publish_message "synthesized_responses" "meal_plan_ready" "{
        \"meal_plan\": ${meal_plan}
    }"
}

provide_hydration_advice() {
    local message=$1
    
    log_agent "INFO" "Providing hydration advice"
    
    local advice=$(python3 "${PROJECT_ROOT}/python/hydration_calculator.py")
    
    publish_message "synthesized_responses" "hydration_advice" "{
        \"advice\": ${advice}
    }"
}

main_loop() {
    while should_run; do
        process_directives
        sleep_interval
    done
    
    log_agent "INFO" "NutritionistAgent shutting down"
}

initialize
main_loop
