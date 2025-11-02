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
