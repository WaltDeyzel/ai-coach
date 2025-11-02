#!/bin/bash
export AGENT_NAME="training_planner"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "training_planner starting..."

initialize() {
    log_agent "INFO" "Initializing training_planner (inactive placeholder)"
}

main_loop() {
    while should_run; do
        sleep_interval
    done
    log_agent "INFO" "training_planner shutting down"
}

initialize
main_loop
