#!/bin/bash
AGENT_NAME="garmin_collector"
source "./../lib/databus.sh"

log "INFO" "Starting agent: $AGENT_NAME"
write_pid

# Agent main loop
while true; do
    # Poll channels or perform tasks here
    sleep 2
done
