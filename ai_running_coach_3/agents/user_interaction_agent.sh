#!/bin/bash
export AGENT_NAME="user_interaction"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
REQUESTS_DIR="${PROJECT_ROOT}/data_bus/channels/user_requests"
RESPONSES_DIR="${PROJECT_ROOT}/data_bus/channels/user_responses"

log_agent "INFO" "UserInteractionAgent starting..."

initialize() {
    echo "### DEBUG: Entering initialize()"
    log_agent "INFO" "Initializing UserInteractionAgent"
    mkdir -p "$REQUESTS_DIR" "$RESPONSES_DIR"
    write_knowledge "system" "user_interaction_state" '{"status": "initialized"}'
    echo "### DEBUG: Directories prepared and initialization knowledge written"
}

detect_intent() {
    local message="$1"
    echo "### DEBUG: detect_intent() called with message='$message'"
    
    log_agent "DEBUG" "Detecting intent for: ${message}"
    
    local intent_prompt="You are an intent classifier for a running coach AI. Classify this user message into ONE category.

Categories and examples:
- training_plan: 'create a plan', 'prepare for race', 'training schedule'
- workout: 'today's workout', 'what should I run today', 'workout for tomorrow'
- strength: 'strength workout', 'gym exercises', 'weight training'
- nutrition: 'what to eat', 'meal plan', 'nutrition advice'
- meal: 'breakfast ideas', 'post-run meal', 'pre-race dinner'
- hydration: 'how much water', 'hydration strategy', 'electrolytes'
- injury: 'I have pain', 'my knee hurts', 'injury prevention'
- pain: 'sore muscles', 'it hurts when', 'aching'
- rehab: 'recovering from', 'return to running', 'rehabilitation'
- analysis: 'analyze my data', 'performance review', 'check my progress'
- general: greetings, questions about the coach, general conversation

User message: \"${message}\"

Respond with ONLY ONE WORD from the categories above. No explanation, no punctuation."

    local raw_response=$(call_gemini "${intent_prompt}")
    echo "### DEBUG: Raw intent response='$raw_response'"
    
    if [ $? -ne 0 ]; then
        echo "### DEBUG: call_gemini() failed, returning 'general'"
        log_agent "WARN" "Intent detection failed, defaulting to 'general'"
        echo "general"
        return
    fi
    
    local clean_response=$(echo "$raw_response" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z_]//g' | head -1)
    echo "### DEBUG: Cleaned intent response='$clean_response'"
    
    case "$clean_response" in
        training_plan|workout|strength|nutrition|meal|hydration|injury|pain|rehab|analysis|general)
            log_agent "INFO" "Detected intent: ${clean_response}"
            echo "$clean_response"
            ;;
        *)
            echo "### DEBUG: Invalid intent detected ('$clean_response'), defaulting to 'general'"
            log_agent "WARN" "Invalid intent '${clean_response}', defaulting to 'general'"
            echo "general"
            ;;
    esac
}

process_user_input() {
    echo "### DEBUG: Entering process_user_input()"
    for req_file in "$REQUESTS_DIR"/*.json; do
        [ -e "$req_file" ] || continue
        echo "### DEBUG: Found request file: $req_file"
        
        local lockfile="${req_file}.lock"
        (
            flock -n 200 || { echo "### DEBUG: Failed to acquire lock on $req_file"; exit 1; }
            
            [ -f "$req_file" ] || { echo "### DEBUG: $req_file no longer exists"; exit 0; }
            
            local request_id=$(jq -r '.request_id' "$req_file" 2>/dev/null || echo "")
            local user_message=$(jq -r '.message' "$req_file" 2>/dev/null || echo "")
            local timestamp=$(jq -r '.timestamp' "$req_file" 2>/dev/null || echo "$(date +%s)")
            echo "### DEBUG: request_id='$request_id', message='$user_message', timestamp='$timestamp'"
            
            [ "$request_id" = "null" ] && request_id=""
            [ "$user_message" = "null" ] && user_message=""
            [ "$timestamp" = "null" ] && timestamp="$(date +%s)"
            
            if [ -z "$request_id" ] || [ -z "$user_message" ]; then
                echo "### DEBUG: Incomplete request skipped: id='$request_id', message='$user_message'"
                log_agent "WARN" "Skipping incomplete request"
                rm -f "$req_file"
                exit 0
            fi
            
            log_agent "INFO" "Processing user request ${request_id}: ${user_message}"
            
            local intent=$(detect_intent "$user_message")
            echo "### DEBUG: Intent for $request_id='$intent'"
            
            local message_data=$(jq -n \
                --arg rid "$request_id" \
                --arg msg "$user_message" \
                --arg intent "$intent" \
                --arg ts "$timestamp" \
                '{
                    request_id: $rid,
                    message: $msg,
                    intent: $intent,
                    timestamp: $ts,
                    user_id: "default_user"
                }')
            
            rm -f "$req_file"
            echo "### DEBUG: Request file $req_file removed after processing"
            
            local msg_id=$(publish_message "user_requests" "user_message" "$message_data")
            echo "### DEBUG: Published message id='$msg_id' intent='$intent'"
            
        ) 200>"$lockfile"
        rm -f "$lockfile"
        echo "### DEBUG: Lockfile $lockfile removed"
    done
}

present_responses() {
    echo "### DEBUG: Entering present_responses()"
    local messages=$(subscribe_channel "synthesized_responses" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    echo "### DEBUG: Received $msg_count messages"
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Presenting ${msg_count} response(s)"
    fi
    
    local processed=0
    
    while read -r message; do
        [ -z "$message" ] && continue
        echo "### DEBUG: Processing response message: $message"
        
        local msg_id=$(extract_field "${message}" '.id')
        local msg_timestamp=$(extract_field "${message}" '.timestamp')
        local request_id=$(extract_field "${message}" '.data.request_id')
        local response_text=$(extract_field "${message}" '.data.response' 'No response generated')
        local source=$(extract_field "${message}" '.data.source' 'unknown')
        
        echo "### DEBUG: Response details id='$msg_id', request_id='$request_id', source='$source'"
        
        if [ -z "$request_id" ] || [ "$request_id" = "null" ]; then
            echo "### DEBUG: Skipping invalid response (missing request_id)"
            archive_message "synthesized_responses" "${msg_id}"
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            continue
        fi
        
        local response_file="${RESPONSES_DIR}/response_${request_id}.json"
        jq -n \
            --arg rid "$request_id" \
            --arg resp "$response_text" \
            --arg src "$source" \
            '{request_id: $rid, response: $resp, source: $src}' > "$response_file"
        
        echo "### DEBUG: Response saved to $response_file"
        
        LAST_SEEN_TIMESTAMP="${msg_timestamp}"
        archive_message "synthesized_responses" "${msg_id}"
        processed=$((processed + 1))
        
    done < <(echo "${messages}" | jq -c '.[]')
    
    if [ $processed -gt 0 ]; then
        echo "### DEBUG: Completed presenting $processed responses"
        log_agent "INFO" "Successfully presented ${processed} response(s)"
    fi
}

main_loop() {
    echo "### DEBUG: Starting main_loop()"
    while should_run; do
        echo "### DEBUG: Loop tick start"
        process_user_input
        present_responses
        echo "### DEBUG: Loop tick complete, sleeping..."
        sleep_interval
    done
    log_agent "INFO" "UserInteractionAgent shutting down"
    echo "### DEBUG: Exiting main_loop()"
}

initialize
main_loop

