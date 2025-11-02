#!/bin/bash
export AGENT_NAME="strength_coach"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "StrengthCoachAgent starting..."

initialize() {
    log_agent "INFO" "Initializing StrengthCoachAgent (inactive placeholder)"
}

main_loop() {
    while should_run; do
        # This agent is inactive - training_orchestrator handles strength queries
        sleep_interval
    done
    log_agent "INFO" "StrengthCoachAgent shutting down"
}

initialize
main_loop
