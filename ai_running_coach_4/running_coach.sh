#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="${SCRIPT_DIR}/agents"

start_agent() {
    local agent_script="$1"
    if [ -f "$agent_script" ]; then
        nohup bash "$agent_script" > "${SCRIPT_DIR}/logs/$(basename $agent_script).log" 2>&1 &
        echo "Started $(basename $agent_script)"
    else
        echo "✗ Agent script not found: $agent_script"
    fi
}

echo "Starting AI Running Coach..."

for agent_script in "$AGENT_DIR"/*_agent.sh; do
    start_agent "$agent_script"
done
