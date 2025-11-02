#!/bin/bash
export AGENT_NAME="nutritionist"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "NutritionistAgent starting..."

initialize() {
    log_agent "INFO" "Initializing NutritionistAgent"
}

main_loop() {
    while should_run; do
        # Agent-specific logic would go here
        sleep_interval
    done
    log_agent "INFO" "NutritionistAgent shutting down"
}

initialize
main_loop
