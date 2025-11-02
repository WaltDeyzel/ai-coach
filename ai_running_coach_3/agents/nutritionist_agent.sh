#!/bin/bash
export AGENT_NAME="nutritionist"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "nutritionist starting..."

initialize() {
    log_agent "INFO" "Initializing nutritionist (inactive placeholder)"
}

main_loop() {
    while should_run; do
        sleep_interval
    done
    log_agent "INFO" "nutritionist shutting down"
}

initialize
main_loop
