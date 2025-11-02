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
