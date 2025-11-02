#!/bin/bash
AGENT_NAME="strength_coach"
source "./../lib/databus.sh"

log "INFO" "Starting agent: $AGENT_NAME"
write_pid

# Agent main loop
while true; do
    # Poll channels or perform tasks here
    sleep 2
done
