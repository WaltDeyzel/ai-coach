#!/bin/bash
# Data Bus Communication Library - Arch Linux Compatible

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    
    local msg_id=$(generate_message_id)
    # Arch-compatible timestamp (without milliseconds)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    mkdir -p "${channel_dir}"
    
    local message=$(cat <<EOFMSG
{
    "id": "${msg_id}",
    "type": "${msg_type}",
    "timestamp": "${timestamp}",
    "sender": "${AGENT_NAME}",
    "data": ${data}
}
EOFMSG
)
    
    echo "${message}" > "${channel_dir}/${msg_id}.json"
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
    local entry=$(cat <<EOFMSG
{
    "key": "${key}",
    "domain": "${domain}",
    "timestamp": "${timestamp}",
    "updated_by": "${AGENT_NAME}",
    "data": ${data}
}
EOFMSG
)
    
    echo "${entry}" > "${kb_dir}/${key}.json"
}

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
    echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >> "${LOGS_DIR}/${AGENT_NAME}.log"
    [ "${level}" = "ERROR" ] && echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >&2
}

should_run() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "${pid_file}" ] && [ "$$" -eq "$(cat ${pid_file})" ]
}

sleep_interval() {
    sleep "${POLL_INTERVAL:-2}"
}

# Gemini CLI integration helper
call_gemini() {
    local prompt=$1
    local output_file=$2
    
    if command -v gemini &> /dev/null; then
        gemini "${prompt}" > "${output_file}" 2>/dev/null || echo "Error calling Gemini" > "${output_file}"
    else
        echo "Gemini CLI not available" > "${output_file}"
    fi
}
