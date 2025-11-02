#!/bin/bash
export AGENT_NAME="training_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "TrainingOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing TrainingOrchestratorAgent"
    write_knowledge "training" "orchestrator_state" '{"status": "initialized"}'
}

generate_training_response() {
    local intent="$1"
    local message="$2"
    
    log_agent "INFO" "Generating training response for intent: ${intent}"
    
    local prompt=""
    case "${intent}" in
        training_plan)
            prompt="You are an expert running coach. Create a practical training plan based on: '${message}'.

Include:
- Weekly structure (days and workout types)
- Key workout types (easy runs, intervals, tempo, long run)
- Mileage progression
- Race-day preparation tips

Keep under 150 words."
            ;;
        workout)
            prompt="You are a running coach. Provide a specific workout for: '${message}'.

Include:
- Warm-up (10 min easy)
- Main workout with specific paces/distances
- Cool-down (5-10 min easy)
- Expected benefits

Keep under 120 words."
            ;;
        strength)
            prompt="You are a strength coach for runners. Provide a runner-specific strength workout for: '${message}'.

Include 5-6 exercises with sets/reps:
- Squats, lunges, planks, hip bridges, calf raises, core work
- Proper form cues
- Duration (30-40 minutes)

Keep under 150 words."
            ;;
        *)
            prompt="You are an experienced running coach. Respond helpfully to this training question: '${message}'

Be specific and actionable. Keep under 100 words."
            ;;
    esac
    
    log_agent "INFO" "Calling Gemini CLI"
    local response=$(call_gemini "${prompt}")
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        log_agent "ERROR" "Failed to generate response"
        echo "I apologize, but I'm having trouble generating a training response. Please try again."
        return 1
    fi
    
    # Clean response
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
    
    local processed=0
    
    while read -r message; do
        [ -z "$message" ] && continue
        
        local msg_type=$(extract_field "${message}" '.type')
        local msg_id=$(extract_field "${message}" '.id')
        local msg_timestamp=$(extract_field "${message}" '.timestamp')
        
        # Only process training delegations
        if [ "${msg_type}" != "training_delegation" ]; then
            log_agent "DEBUG" "Skipping non-training message: ${msg_type}"
            continue
        fi
        
        log_agent "INFO" "Processing training delegation ${msg_id}"
        
        # Extract data fields from canonical schema
        local request_id=$(extract_field "${message}" '.data.request_id')
        local intent=$(extract_field "${message}" '.data.intent' 'workout')
        local user_message=$(extract_field "${message}" '.data.message')
        
        # Validate required fields
        if [ -z "$request_id" ] || [ -z "$user_message" ]; then
            log_agent "WARN" "Skipping delegation ${msg_id} - missing required fields"
            archive_message "delegation_commands" "${msg_id}"
            continue
        fi
        
        log_agent "INFO" "Handling training delegation for request ${request_id}"
        log_agent "INFO" "Intent: ${intent}, Message: ${user_message}"
        
        # Generate response using Gemini
        local ai_response=$(generate_training_response "${intent}" "${user_message}")
        
        if [ -z "$ai_response" ]; then
            log_agent "ERROR" "Empty response generated"
            ai_response="I apologize, but I could not generate a training response at this time. Please try again."
        fi
        
        # Create response using canonical schema
        local response_data=$(jq -n \
            --arg rid "$request_id" \
            --arg resp "$ai_response" \
            --arg src "training_orchestrator" \
            '{
                request_id: $rid,
                response: $resp,
                source: $src
            }')
        
        # Publish to synthesized_responses
        local response_msg_id=$(publish_message "synthesized_responses" "training_response" "$response_data")
        
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
    log_agent "INFO" "TrainingOrchestratorAgent shutting down"
}

initialize
main_loop
