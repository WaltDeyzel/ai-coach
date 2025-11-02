#!/bin/bash
export AGENT_NAME="injury_prevention"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "injury_prevention starting..."

initialize() {
    log_agent "INFO" "Initializing injury_prevention (inactive placeholder)"
}

main_loop() {
    while should_run; do
        sleep_interval
    done
    log_agent "INFO" "injury_prevention shutting down"
}

initialize
main_loop
