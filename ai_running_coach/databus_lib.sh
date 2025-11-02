#!/bin/bash

# Data Bus Communication Library
# Provides functions for agents to communicate via the data bus

# Source this file in agent scripts: source "${PROJECT_ROOT}/lib/databus.sh"

# Generate unique message ID
generate_message_id() {
    echo "msg_$(date +%s%N)_$$_${RANDOM}"
}

# Publish message to a channel
# Usage: publish_message <channel> <message_type> <data_json>
publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    
    local msg_id=$(generate_message_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    mkdir -p "${channel_dir}"
    
    local message=$(cat <<EOF
{
    "id": "${msg_id}",
    "type": "${msg_type}",
    "timestamp": "${timestamp}",
    "sender": "${AGENT_NAME}",
    "data": ${data}
}
EOF
)
    
    local msg_file="${channel_dir}/${msg_id}.json"
    echo "${message}" > "${msg_file}"
    
    echo "${msg_id}"
}

# Subscribe to a channel and get new messages
# Usage: subscribe_channel <channel> <last_seen_timestamp>
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
        if [ -f "${msg_file}" ]; then
            local msg_timestamp=$(jq -r '.timestamp' "${msg_file}" 2>/dev/null || echo "0")
            if [[ "${msg_timestamp}" > "${last_seen}" ]]; then
                if [ "${first}" = true ]; then
                    first=false
                else
                    messages="${messages},"
                fi
                messages="${messages}$(cat ${msg_file})"
            fi
        fi
    done
    
    messages="${messages}]"
    echo "${messages}"
}

# Read from shared knowledge base
# Usage: read_knowledge <domain> <key>
read_knowledge() {
    local domain=$1
    local key=$2
    local kb_file="${SHARED_KB_DIR}/${domain}/${key}.json"
    
    if [ -f "${kb_file}" ]; then
        cat "${kb_file}"
    else
        echo "null"
    fi
}

# Write to shared knowledge base
# Usage: write_knowledge <domain> <key> <data_json>
write_knowledge() {
    local domain=$1
    local key=$2
    local data=$3
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    
    mkdir -p "${kb_dir}"
    
    local kb_file="${kb_dir}/${key}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    local entry=$(cat <<EOF
{
    "key": "${key}",
    "domain": "${domain}",
    "timestamp": "${timestamp}",
    "updated_by": "${AGENT_NAME}",
    "data": ${data}
}
EOF
)
    
    echo "${entry}" > "${kb_file}"
}

# Archive processed message
# Usage: archive_message <channel> <message_id>
archive_message() {
    local channel=$1
    local msg_id=$2
    local msg_file="${DATA_BUS_DIR}/channels/${channel}/${msg_id}.json"
    local archive_dir="${DATA_BUS_DIR}/archive/${channel}"
    
    if [ -f "${msg_file}" ]; then
        mkdir -p "${archive_dir}"
        mv "${msg_file}" "${archive_dir}/"
    fi
}

# Query knowledge base with filter
# Usage: query_knowledge <domain> [pattern]
query_knowledge() {
    local domain=$1
    local pattern=${2:-"*"}
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    
    if [ ! -d "${kb_dir}" ]; then
        echo "[]"
        return
    fi
    
    local results="["
    local first=true
    
    for kb_file in "${kb_dir}"/${pattern}.json; do
        if [ -f "${kb_file}" ]; then
            if [ "${first}" = true ]; then
                first=false
            else
                results="${results},"
            fi
            results="${results}$(cat ${kb_file})"
        fi
    done
    
    results="${results}]"
    echo "${results}"
}

# Log agent activity
# Usage: log_agent <level> <message>
log_agent() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >> "${LOGS_DIR}/${AGENT_NAME}.log"
    
    if [ "${level}" = "ERROR" ]; then
        echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >&2
    fi
}

# Check if agent should continue running
# Usage: should_run
should_run() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    if [ -f "${pid_file}" ]; then
        local stored_pid=$(cat "${pid_file}")
        if [ "$$" -eq "${stored_pid}" ]; then
            return 0
        fi
    fi
    return 1
}

# Wait for agent initialization
sleep_interval() {
    local interval=${POLL_INTERVAL:-2}
    sleep "${interval}"
}
