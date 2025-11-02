#!/bin/bash
DATA_BUS_DIR="$(dirname "$0")/../data_bus/channels"
SHARED_KB_DIR="$(dirname "$0")/../shared_knowledge_base"
LOGS_DIR="$(dirname "$0")/../logs"
PID_DIR="$(dirname "$0")/../pids"
AGENT_NAME="${AGENT_NAME:-unknown}"
POLL_INTERVAL=2

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    local msg_id=$(generate_message_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    mkdir -p "${channel_dir}"
    local message=$(cat <<MSG
{
    "id": "${msg_id}",
    "type": "${msg_type}",
    "timestamp": "${timestamp}",
    "sender": "${AGENT_NAME}",
    "data": ${data}
}
MSG
)
    echo "${message}" > "${channel_dir}/${msg_id}.json"
    echo "${msg_id}"
}

subscribe_channel() {
    local channel=$1
    local last_seen=${2:-"0"}
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    [ ! -d "$channel_dir" ] && echo "[]" && return
    local messages="["
    local first=true
    for msg_file in "${channel_dir}"/*.json; do
        [ -f "$msg_file" ] || continue
        local msg_timestamp=$(jq -r '.timestamp' "$msg_file" 2>/dev/null || echo "0")
        if [[ "$msg_timestamp" > "$last_seen" ]]; then
            [ "$first" = true ] || messages="${messages},"
            first=false
            messages="${messages}$(cat "$msg_file")"
        fi
    done
    echo "${messages}]"
}

read_knowledge() {
    local file_path="$1"
    [ -f "$file_path" ] && cat "$file_path" || echo "{}"
}

write_knowledge() {
    local domain=$1
    local key=$2
    local data=$3
    local file_path="${SHARED_KB_DIR}/${domain}/${key}.json"
    mkdir -p "$(dirname "$file_path")"
    echo "${data}" > "$file_path"
}

read_channel_message() {
    local channel=$1
    local msg_id=$2
    local msg_file="${DATA_BUS_DIR}/${channel}/${msg_id}.json"
    [ -f "$msg_file" ] && cat "$msg_file" || echo "{}"
}

list_channel_messages() {
    local channel=$1
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    [ ! -d "$channel_dir" ] && return
    ls "${channel_dir}"/*.json 2>/dev/null || true
}

log() {
    local level=$1
    local msg=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp][$level][$AGENT_NAME] $msg"
}

write_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    mkdir -p "$(dirname "$pid_file")"
    echo $$ > "$pid_file"
}

read_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "$pid_file" ] && cat "$pid_file" || echo ""
}

remove_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "$pid_file" ] && rm "$pid_file"
}
