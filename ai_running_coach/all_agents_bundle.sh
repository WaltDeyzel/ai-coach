#!/bin/bash

# Agent Scripts Generator
# This script creates all agent scripts in the agents/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="${SCRIPT_DIR}/agents"

mkdir -p "${AGENTS_DIR}"

echo "Creating all agent scripts..."

# ============================================================================
# USER INTERACTION AGENT
# ============================================================================
cat > "${AGENTS_DIR}/user_interaction_agent.sh" <<'AGENT_EOF'
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
AGENT_EOF

# ============================================================================
# DATA ANALYSIS AGENT
# ============================================================================
cat > "${AGENTS_DIR}/data_analysis_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="data_analysis"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "DataAnalysisAgent starting..."

initialize() {
    log_agent "INFO" "Initializing DataAnalysisAgent"
    write_knowledge "system" "data_analysis_state" '{
        "status": "initialized",
        "last_analysis": null
    }'
}

process_new_data() {
    # Check for new Garmin data
    local garmin_file="${DATA_BUS_DIR}/incoming/garmin_activity.json"
    if [ -f "${garmin_file}" ]; then
        log_agent "INFO" "Processing new Garmin activity"
        
        local activity_data=$(cat "${garmin_file}")
        local activity_id=$(echo "${activity_data}" | jq -r '.activityId // "unknown"')
        
        # Process with Python
        python3 "${PROJECT_ROOT}/python/process_activity.py" < "${garmin_file}"
        
        # Store processed data
        write_knowledge "processed_data" "activity_${activity_id}" "${activity_data}"
        
        rm "${garmin_file}"
        log_agent "INFO" "Garmin activity processed: ${activity_id}"
    fi
}

analyze_trends() {
    # Perform periodic trend analysis
    log_agent "INFO" "Analyzing performance trends"
    
    local activities=$(query_knowledge "processed_data" "activity_*")
    
    if [ "${activities}" != "[]" ]; then
        # Run Python analysis
        local analysis_result=$(python3 "${PROJECT_ROOT}/python/analyze_trends.py" <<< "${activities}")
        
        # Store analysis
        write_knowledge "processed_data" "latest_analysis" "${analysis_result}"
        
        # Publish summary
        publish_message "analysis_summaries" "trend_analysis" "{
            \"analysis\": ${analysis_result},
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"
        }"
        
        log_agent "INFO" "Trend analysis completed"
    fi
}

detect_anomalies() {
    local training_plan=$(read_knowledge "training_plans" "current")
    local recent_activities=$(query_knowledge "processed_data" "activity_*" | jq 'sort_by(.timestamp) | .[-7:]')
    
    if [ "${recent_activities}" != "[]" ]; then
        # Check for overtraining indicators
        local analysis=$(python3 "${PROJECT_ROOT}/python/detect_anomalies.py" <<< "${recent_activities}")
        
        local has_alerts=$(echo "${analysis}" | jq -r '.has_alerts // false')
        
        if [ "${has_alerts}" = "true" ]; then
            log_agent "WARN" "Anomalies detected, publishing alert"
            
            publish_message "data_alerts" "anomaly_detected" "{
                \"alert_type\": $(echo "${analysis}" | jq -r '.alert_type'),
                \"severity\": $(echo "${analysis}" | jq -r '.severity'),
                \"details\": $(echo "${analysis}" | jq -c '.details'),
                \"recommended_action\": $(echo "${analysis}" | jq -r '.recommended_action')
            }"
        fi
    fi
}

main_loop() {
    local counter=0
    
    while should_run; do
        process_new_data
        
        # Analyze trends every 5 iterations
        ((counter++))
        if [ $((counter % 5)) -eq 0 ]; then
            analyze_trends
            detect_anomalies
        fi
        
        sleep_interval
    done
    
    log_agent "INFO" "DataAnalysisAgent shutting down"
}

initialize
main_loop
AGENT_EOF

# ============================================================================
# TRAINING PLANNER AGENT
# ============================================================================
cat > "${AGENTS_DIR}/training_planner_agent.sh" <<'AGENT_EOF'
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
AGENT_EOF

# ============================================================================
# STRENGTH COACH AGENT
# ============================================================================
cat > "${AGENTS_DIR}/strength_coach_agent.sh" <<'AGENT_EOF'
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
AGENT_EOF

# ============================================================================
# INJURY PREVENTION AGENT
# ============================================================================
cat > "${AGENTS_DIR}/injury_prevention_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="injury_prevention"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "InjuryPreventionAgent starting..."

initialize() {
    log_agent "INFO" "Initializing InjuryPreventionAgent"
}

process_directives() {
    local messages=$(subscribe_channel "injury_directives" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} injury directive(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_type=$(echo "${message}" | jq -r '.type')
            
            case "${msg_type}" in
                assess_risk)
                    assess_injury_risk "${message}"
                    ;;
                generate_rehab)
                    generate_rehab_plan "${message}"
                    ;;
            esac
        done
    fi
}

monitor_pain_reports() {
    # Check daily journals for pain mentions
    local journals=$(query_knowledge "daily_journals" "$(date +%Y-%m)*")
    
    if [ "${journals}" != "[]" ]; then
        local has_pain=$(echo "${journals}" | jq -r '.[].data | select(.pain_level > 0) | .pain_level' | head -1)
        
        if [ -n "${has_pain}" ] && [ "${has_pain}" != "null" ]; then
            log_agent "WARN" "Pain reported, initiating assessment"
            
            publish_message "injury_assessment" "pain_reported" "{
                \"pain_level\": ${has_pain},
                \"requires_assessment\": true
            }"
        fi
    fi
}

assess_injury_risk() {
    local message=$1
    
    log_agent "INFO" "Assessing injury risk"
    
    local training_data=$(query_knowledge "processed_data" "activity_*" | jq 'sort_by(.timestamp) | .[-14:]')
    
    # Run risk assessment
    local risk_assessment=$(python3 "${PROJECT_ROOT}/python/assess_injury_risk.py" <<< "${training_data}")
    
    local risk_level=$(echo "${risk_assessment}" | jq -r '.risk_level')
    
    if [ "${risk_level}" = "high" ]; then
        log_agent "WARN" "High injury risk detected"
        
        publish_message "data_alerts" "injury_risk" "{
            \"alert_type\": \"injury_risk\",
            \"severity\": \"high\",
            \"assessment\": ${risk_assessment}
        }"
    fi
}

generate_rehab_plan() {
    local message=$1
    local injury_type=$(echo "${message}" | jq -r '.data.injury_type')
    
    log_agent "INFO" "Generating rehab plan for: ${injury_type}"
    
    # Generate rehab using Python
    local rehab_plan=$(python3 "${PROJECT_ROOT}/python/generate_rehab_plan.py" <<< "{\"injury_type\": \"${injury_type}\"}")
    
    write_knowledge "rehab_plans" "${injury_type}_$(date +%Y%m%d)" "${rehab_plan}"
    
    publish_message "synthesized_responses" "rehab_plan_ready" "{
        \"injury_type\": \"${injury_type}\",
        \"plan\": ${rehab_plan}
    }"
}

main_loop() {
    local counter=0
    
    while should_run; do
        process_directives
        
        ((counter++))
        if [ $((counter % 10)) -eq 0 ]; then
            monitor_pain_reports
        fi
        
        sleep_interval
    done
    
    log_agent "INFO" "InjuryPreventionAgent shutting down"
}

initialize
main_loop
AGENT_EOF

# ============================================================================
# NUTRITIONIST AGENT
# ============================================================================
cat > "${AGENTS_DIR}/nutritionist_agent.sh" <<'AGENT_EOF'
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
AGENT_EOF

# ============================================================================
# NUTRITION ORCHESTRATOR AGENT
# ============================================================================
cat > "${AGENTS_DIR}/nutrition_orchestrator_agent.sh" <<'AGENT_EOF'
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
AGENT_EOF

# ============================================================================
# INJURY ORCHESTRATOR AGENT
# ============================================================================
cat > "${AGENTS_DIR}/injury_orchestrator_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="injury_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"

log_agent "INFO" "InjuryOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing InjuryOrchestratorAgent"
    write_knowledge "injury" "orchestrator_state" '{
        "status": "initialized",
        "active_injuries": []
    }'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        case "${msg_type}" in
            injury_delegation)
                handle_injury_delegation "${message}"
                ;;
            injury_alert)
                handle_injury_alert "${message}"
                ;;
        esac
    done
}

handle_injury_delegation() {
    local message=$1
    local original_request=$(echo "${message}" | jq -r '.data.original_request')
    
    log_agent "INFO" "Handling injury delegation"
    
    publish_message "injury_directives" "assess_risk" "{
        \"original_request\": ${original_request}
    }"
}

handle_injury_alert() {
    local message=$1
    
    log_agent "WARN" "Handling injury alert"
    
    publish_message "injury_directives" "generate_rehab" "{
        \"alert\": $(echo "${message}" | jq -c '.data.alert')
    }"
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
AGENT_EOF

# Make all agents executable
chmod +x "${AGENTS_DIR}"/*.sh

echo "✓ All agent scripts created successfully in ${AGENTS_DIR}/"
AGENT_EOF

chmod +x "${SCRIPT_DIR}/create_agents.sh"

echo "Created: create_agents.sh"
echo "Run this script to generate all agent scripts in the agents/ directory"
