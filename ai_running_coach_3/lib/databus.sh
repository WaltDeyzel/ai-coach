#!/bin/bash
# Data Bus Communication Library - Multi-Agent Best Practices

# Load agent registry
AGENT_REGISTRY="${CONFIG_DIR}/agent_registry.json"

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

# Publish message with canonical schema
publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    
    local msg_id=$(generate_message_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    mkdir -p "${channel_dir}"
    
    # Validate data is valid JSON
    if ! echo "${data}" | jq empty 2>/dev/null; then
        log_agent "ERROR" "Invalid JSON data for message type ${msg_type}"
        return 1
    fi
    
    # Create canonical message envelope
    local message=$(jq -n \
        --arg id "${msg_id}" \
        --arg type "${msg_type}" \
        --arg ts "${timestamp}" \
        --arg sender "${AGENT_NAME}" \
        --argjson data "${data}" \
        '{
            id: $id,
            type: $type,
            timestamp: $ts,
            sender: $sender,
            data: $data
        }')
    
    echo "${message}" > "${channel_dir}/${msg_id}.json"
    log_agent "DEBUG" "Published ${msg_type} to ${channel}: ${msg_id}"
    echo "${msg_id}"
}

subscribe_channel() {
    local channel=$1
    local last_seen=${2:-"0"}
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    if [ ! -d "${channel_dir}" ]; then
        echo "[]"
        return
    fi
    
    local messages="["
    local first=true
    
    for msg_file in "${channel_dir}"/*.json; do
        [ -f "${msg_file}" ] || continue
        
        local msg_timestamp=$(jq -r '.timestamp' "${msg_file}" 2>/dev/null || echo "0")
        
        if [[ "${msg_timestamp}" > "${last_seen}" ]]; then
            [ "${first}" = true ] || messages="${messages},"
            first=false
            messages="${messages}$(cat ${msg_file})"
        fi
    done
    
    echo "${messages}]"
}

read_knowledge() {
    local domain=$1
    local key=$2
    local kb_file="${SHARED_KB_DIR}/${domain}/${key}.json"
    [ -f "${kb_file}" ] && cat "${kb_file}" || echo "null"
}

write_knowledge() {
    local domain=$1
    local key=$2
    local data=$3
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    mkdir -p "${kb_dir}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local entry=$(jq -n \
        --arg key "${key}" \
        --arg domain "${domain}" \
        --arg ts "${timestamp}" \
        --arg agent "${AGENT_NAME}" \
        --argjson data "${data}" \
        '{
            key: $key,
            domain: $domain,
            timestamp: $ts,
            updated_by: $agent,
            data: $data
        }')
    
    echo "${entry}" > "${kb_dir}/${key}.json"
}

archive_message() {
    local channel=$1
    local msg_id=$2
    local msg_file="${DATA_BUS_DIR}/channels/${channel}/${msg_id}.json"
    local archive_dir="${DATA_BUS_DIR}/archive/${channel}/$(date +%Y%m%d)"
    
    if [ -f "${msg_file}" ]; then
        mkdir -p "${archive_dir}"
        mv "${msg_file}" "${archive_dir}/"
        log_agent "DEBUG" "Archived message ${msg_id} from ${channel}"
    fi
}

query_knowledge() {
    local domain=$1
    local pattern=${2:-"*"}
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    
    [ ! -d "${kb_dir}" ] && echo "[]" && return
    
    local results="["
    local first=true
    
    for kb_file in "${kb_dir}"/${pattern}.json; do
        [ -f "${kb_file}" ] || continue
        [ "${first}" = true ] || results="${results},"
        first=false
        results="${results}$(cat ${kb_file})"
    done
    
    echo "${results}]"
}

log_agent() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_file="${LOGS_DIR}/${AGENT_NAME}.log"
    
    echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >> "${log_file}"
    
    # Also log to console for ERROR and WARN
    if [ "${level}" = "ERROR" ] || [ "${level}" = "WARN" ]; then
        echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >&2
    fi
}

should_run() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "${pid_file}" ] && [ "$$" -eq "$(cat ${pid_file})" ]
}

sleep_interval() {
    sleep "${POLL_INTERVAL:-2}"
}

# Get agent capabilities from registry
get_agent_capabilities() {
    local agent_name=$1
    if [ -f "${AGENT_REGISTRY}" ]; then
        jq -r ".agents.${agent_name}.capabilities[]" "${AGENT_REGISTRY}" 2>/dev/null | tr '\n' ', ' | sed 's/,$//'
    fi
}

# Get delegation type for agent
get_delegation_type() {
    local agent_name=$1
    if [ -f "${AGENT_REGISTRY}" ]; then
        jq -r ".agents.${agent_name}.delegation_type" "${AGENT_REGISTRY}" 2>/dev/null
    fi
}

# Build agent context for LLM
build_agent_context() {
    if [ ! -f "${AGENT_REGISTRY}" ]; then
        echo "No agent registry found"
        return 1
    fi
    
    local context="Available agents and their capabilities:\n\n"
    
    for agent in $(jq -r '.agents | keys[]' "${AGENT_REGISTRY}"); do
        local name=$(jq -r ".agents.${agent}.name" "${AGENT_REGISTRY}")
        local desc=$(jq -r ".agents.${agent}.description" "${AGENT_REGISTRY}")
        local caps=$(jq -r ".agents.${agent}.capabilities | join(\", \")" "${AGENT_REGISTRY}")
        
        context="${context}${agent}: ${desc}\nCapabilities: ${caps}\n\n"
    done
    
    echo -e "${context}"
}

# Gemini CLI helper with error handling
call_gemini() {
    local prompt=$1
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        local response=$(gemini "${prompt}" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ] && [ -n "$response" ]; then
            # Clean response
            response=$(echo "$response" | sed '/Loaded cached credentials/d' | sed '/^$/d' | sed 's/[^[:print:]\t]/ /g')
            echo "$response"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log_agent "WARN" "Gemini call failed (attempt ${retry_count}/${max_retries})"
        sleep 1
    done
    
    log_agent "ERROR" "Gemini call failed after ${max_retries} attempts"
    return 1
}

# Extract fields safely from message
extract_field() {
    local message=$1
    local field_path=$2
    local default=${3:-""}
    
    local value=$(echo "${message}" | jq -r "${field_path}" 2>/dev/null || echo "${default}")
    
    # Convert jq's "null" to empty string
    [ "$value" = "null" ] && value="${default}"
    
    echo "$value"
}
