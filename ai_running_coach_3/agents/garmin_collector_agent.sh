#!/bin/bash
# GarminCollectorAgent - Bash wrapper for scheduled operation

export AGENT_NAME="garmin_collector"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

PYTHON_SCRIPT="${PROJECT_ROOT}/python/garmin_collector.py"

log_agent "INFO" "GarminCollectorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing GarminCollectorAgent"
    
    # Check if Python script exists
    if [ ! -f "${PYTHON_SCRIPT}" ]; then
        log_agent "ERROR" "Python collector script not found: ${PYTHON_SCRIPT}"
        exit 1
    fi
    
    # Check credentials
    if [ ! -f "${PROJECT_ROOT}/.env" ]; then
        log_agent "ERROR" ".env file not found - cannot authenticate with Garmin"
        exit 1
    fi
}

check_sync_schedule() {
    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    
    # Default sync time: 23:00
    if [ "${current_hour}" = "23" ] && [ "${current_minute}" = "00" ]; then
        return 0  # Time to sync
    fi
    return 1  # Not time yet
}

run_sync() {
    log_agent "INFO" "Running scheduled sync..."
    
    python3 "${PYTHON_SCRIPT}"
    local exit_code=$?
    
    if [ ${exit_code} -eq 0 ]; then
        log_agent "INFO" "Sync completed successfully"
    else
        log_agent "ERROR" "Sync failed with exit code ${exit_code}"
    fi
}

main_loop() {
    # Run initial sync on startup
    log_agent "INFO" "Running initial sync..."
    run_sync
    
    while should_run; do
        # Check every minute if it's time for scheduled sync
        if check_sync_schedule; then
            run_sync
        fi
        
        sleep 60  # Check every minute
    done
    
    log_agent "INFO" "GarminCollectorAgent shutting down"
}

initialize
main_loop
