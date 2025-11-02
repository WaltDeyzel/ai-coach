#!/bin/bash
export AGENT_NAME="strength_coach"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "Strength_coachAgent starting..."

initialize() {
    log_agent "INFO" "Initializing Strength_coachAgent"
}

main_loop() {
    while should_run; do
        # Agent-specific logic would go here
        sleep_interval
    done
    log_agent "INFO" "Strength_coachAgent shutting down"
}

initialize
main_loop
