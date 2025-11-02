#!/bin/bash
export AGENT_NAME="orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

    

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "OrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing OrchestratorAgent"
    write_knowledge "system" "orchestrator_state" '{"status": "initialized", "active_delegations": []}'
    echo "### DEBUG: orchestrator ${PROJECT_ROOT}"
}

# Route request to appropriate agent using LLM
route_request() {
    local request_id="$1"
    local user_message="$2"
    local intent="$3"
    
    log_agent "INFO" "Routing request ${request_id} with intent: ${intent}"
    
    # Build agent context from registry
    local agent_context=$(build_agent_context)
    
    # Ask LLM which agent should handle this
    local routing_prompt="You are the orchestrator of a multi-agent running coach system.

${agent_context}

User request: \"${user_message}\"
Detected intent: ${intent}

Based on the agent capabilities above, which agent should handle this request?
Respond with ONLY the agent identifier (e.g., 'training_orchestrator', 'nutrition_orchestrator', 'injury_orchestrator', 'data_analysis').
If no specialized agent is needed, respond with 'general'."

    local selected_agent=$(call_gemini "${routing_prompt}")
    
    if [ $? -ne 0 ] || [ -z "$selected_agent" ]; then
        log_agent "ERROR" "Failed to get routing decision from LLM"
        echo "general"
        return 1
    fi
    
    # Clean the response
    selected_agent=$(echo "$selected_agent" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | head -1)
    
    log_agent "INFO" "LLM selected agent: ${selected_agent}"
    echo "$selected_agent"
}

# Generate general response for non-delegated queries
generate_general_response() {
    local request_id="$1"
    local user_message="$2"
    
    log_agent "INFO" "Generating general response for request ${request_id}"
    
    local prompt="You are an AI running coach assistant. Respond helpfully and encouragingly to: '${user_message}'

Keep your response under 120 words. Be supportive and knowledgeable about running."

    local response=$(call_gemini "${prompt}")
    
    if [ -z "$response" ]; then
        response="Hello! I'm your AI running coach. I can help you with training plans, workouts, nutrition, injury prevention, and performance analysis. What would you like to know?"
    fi
    
    echo "$response"
}

process_user_requests() {
    local messages=$(subscribe_channel "user_requests" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} user request(s)"
    fi
    
    local processed=0
    
    while read -r message; do
        [ -z "$message" ] && continue
        
        local msg_id=$(extract_field "${message}" '.id')
        local msg_timestamp=$(extract_field "${message}" '.timestamp')
        
        # Extract data fields using the canonical schema
        local request_id=$(extract_field "${message}" '.data.request_id')
        local user_message=$(extract_field "${message}" '.data.message')
        local intent=$(extract_field "${message}" '.data.intent' 'general')
        
        # Validate required fields
        if [ -z "$request_id" ] || [ -z "$user_message" ]; then
            log_agent "WARN" "Skipping message ${msg_id} - missing required fields"
            archive_message "user_requests" "${msg_id}"
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            continue
        fi
        
        log_agent "INFO" "Processing request ${request_id}: ${user_message}"
        
        # Route to appropriate agent
        local selected_agent=$(route_request "${request_id}" "${user_message}" "${intent}")
        
        if [ "$selected_agent" = "general" ] || [ -z "$selected_agent" ]; then
            # Handle general queries directly
            log_agent "INFO" "Handling as general query"
            
            local ai_response=$(generate_general_response "${request_id}" "${user_message}")
            
            local response_data=$(jq -n \
                --arg rid "$request_id" \
                --arg resp "$ai_response" \
                --arg src "orchestrator" \
                '{
                    request_id: $rid,
                    response: $resp,
                    source: $src
                }')
            
            publish_message "synthesized_responses" "general_response" "$response_data"
        else
            # Get delegation type from registry
            local delegation_type=$(get_delegation_type "${selected_agent}")
            
            if [ -z "$delegation_type" ] || [ "$delegation_type" = "null" ]; then
                log_agent "ERROR" "Unknown agent: ${selected_agent}, falling back to general"
                
                local ai_response=$(generate_general_response "${request_id}" "${user_message}")
                local response_data=$(jq -n \
                    --arg rid "$request_id" \
                    --arg resp "$ai_response" \
                    --arg src "orchestrator" \
                    '{request_id: $rid, response: $resp, source: $src}')
                publish_message "synthesized_responses" "general_response" "$response_data"
            else
                # Delegate to specialized agent
                log_agent "INFO" "Delegating to ${selected_agent} via ${delegation_type}"
                
                local delegation_data=$(jq -n \
                    --arg rid "$request_id" \
                    --arg msg "$user_message" \
                    --arg intent "$intent" \
                    '{
                        request_id: $rid,
                        message: $msg,
                        intent: $intent
                    }')
                
                publish_message "delegation_commands" "$delegation_type" "$delegation_data"
            fi
        fi
        
        LAST_SEEN_TIMESTAMP="${msg_timestamp}"
        archive_message "user_requests" "${msg_id}"
        
        processed=$((processed + 1))
        
    done < <(echo "${messages}" | jq -c '.[]')
    
    if [ $processed -gt 0 ]; then
        log_agent "INFO" "Successfully processed ${processed} request(s)"
    fi
}

main_loop() {
    while should_run; do
        process_user_requests
        sleep_interval
    done
    log_agent "INFO" "OrchestratorAgent shutting down"
}

initialize
main_loop
