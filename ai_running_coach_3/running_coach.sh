#!/bin/bash

export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DATA_BUS_DIR="${PROJECT_ROOT}/data_bus"
export SHARED_KB_DIR="${PROJECT_ROOT}/shared_knowledge_base"
export AGENTS_DIR="${PROJECT_ROOT}/agents"
export LOGS_DIR="${PROJECT_ROOT}/logs"
export CONFIG_DIR="${PROJECT_ROOT}/config"
export PID_DIR="${PROJECT_ROOT}/pids"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

### DEBUG: Script initialized with PROJECT_ROOT=${PROJECT_ROOT}

start_agent() {
    local agent_name=$1
    local agent_script="${AGENTS_DIR}/${agent_name}_agent.sh"
    local pid_file="${PID_DIR}/${agent_name}.pid"
    echo "### DEBUG: start_agent() called for ${agent_name}"

    if [ -f "${pid_file}" ] && ps -p "$(cat ${pid_file})" > /dev/null 2>&1; then
        echo "### DEBUG: ${agent_name} appears already running (PID=$(cat ${pid_file}))"
        echo -e "${YELLOW}⚠${NC}  ${agent_name} already running"
        return 0
    fi
    
    if [ ! -f "${agent_script}" ]; then
        echo "### DEBUG: Agent script not found: ${agent_script}"
        echo -e "${RED}✗${NC} Agent script not found: ${agent_script}"
        return 1
    fi
    
    echo "### DEBUG: Launching agent ${agent_name}"
    echo -e "${GREEN}✓${NC} Starting ${agent_name}..."
    nohup bash "${agent_script}" > "${LOGS_DIR}/${agent_name}.log" 2>&1 &
    echo $! > "${pid_file}"
    echo "### DEBUG: ${agent_name} started with PID=$(cat ${pid_file})"
}

stop_agent() {
    local agent_name=$1
    local pid_file="${PID_DIR}/${agent_name}.pid"
    echo "### DEBUG: stop_agent() called for ${agent_name}"

    if [ ! -f "${pid_file}" ]; then
        echo "### DEBUG: No PID file for ${agent_name}"
        echo -e "${YELLOW}⚠${NC}  ${agent_name} not running"
        return 0
    fi
    
    local pid=$(cat "${pid_file}")
    echo "### DEBUG: Found PID=${pid} for ${agent_name}"
    if ps -p "${pid}" > /dev/null 2>&1; then
        echo "### DEBUG: Sending SIGTERM to ${agent_name} (PID=${pid})"
        echo -e "${GREEN}✓${NC} Stopping ${agent_name}..."
        kill "${pid}" 2>/dev/null || true
        sleep 1
        kill -9 "${pid}" 2>/dev/null || true
        echo "### DEBUG: ${agent_name} terminated"
    else
        echo "### DEBUG: No active process found for ${agent_name}"
    fi
    rm -f "${pid_file}"
    echo "### DEBUG: PID file removed for ${agent_name}"
}

start_all() {
    echo "### DEBUG: start_all() initiating..."
    echo -e "${CYAN}Starting AI Running Coach...${NC}\n"
    start_agent "orchestrator"
    sleep 1
    start_agent "training_orchestrator"
    start_agent "nutrition_orchestrator"
    start_agent "injury_orchestrator"
    sleep 1
    start_agent "user_interaction"
    start_agent "data_analysis"
    start_agent "garmin_collector"
    start_agent "training_planner"
    start_agent "strength_coach"
    start_agent "injury_prevention"
    start_agent "nutritionist"
    echo -e "\n${GREEN}✓${NC} All agents started!"
    echo "### DEBUG: start_all() completed"
}

stop_all() {
    echo "### DEBUG: stop_all() initiating..."
    echo -e "${CYAN}Stopping all agents...${NC}\n"
    for pid_file in "${PID_DIR}"/*.pid; do
        [ -f "${pid_file}" ] || continue
        agent_name=$(basename "${pid_file}" .pid)
        echo "### DEBUG: Found running agent to stop: ${agent_name}"
        stop_agent "${agent_name}"
    done
    echo -e "\n${GREEN}✓${NC} All agents stopped!"
    echo "### DEBUG: stop_all() completed"
}

status() {
    echo "### DEBUG: status() called"
    echo -e "\n${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   AI Running Coach System Status      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}\n"
    
    local agents=(
        "orchestrator:Main Orchestrator"
        "training_orchestrator:Training Coordinator"
        "nutrition_orchestrator:Nutrition Coordinator"
        "injury_orchestrator:Injury Coordinator"
        "user_interaction:User Interface"
        "data_analysis:Data Analyzer"
        "garmin_collector:Garmin Data Sync" 
        "training_planner:Training Planner"
        "strength_coach:Strength Coach"
        "injury_prevention:Injury Prevention"
        "nutritionist:Nutritionist"
    )
    
    for agent_info in "${agents[@]}"; do
        IFS=':' read -r agent desc <<< "${agent_info}"
        local pid_file="${PID_DIR}/${agent}.pid"
        printf "  %-25s " "${desc}"
        
        if [ -f "${pid_file}" ] && ps -p "$(cat ${pid_file})" > /dev/null 2>&1; then
            echo "### DEBUG: ${agent} is running (PID=$(cat ${pid_file}))"
            echo -e "${GREEN}● RUNNING${NC}"
        else
            echo "### DEBUG: ${agent} is stopped"
            echo -e "${RED}○ STOPPED${NC}"
        fi
    done
    echo ""
}

chat_mode() {
	# Inside your chat terminal:
	echo "chat PROJECT_ROOT: $PROJECT_ROOT"
    echo "### DEBUG: chat_mode() entered"
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     AI Running Coach - Interactive Chat Mode          ║${NC}"
    echo -e "${CYAN}║  Type 'quit' to exit, 'status' to check agents        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}\n"
    
    while true; do
        echo -ne "${GREEN}You:${NC} "
        read -r user_input
        echo "### DEBUG: User input='$user_input'"
        
        case "${user_input}" in
            quit|exit)
                echo "### DEBUG: Exiting chat_mode()"
                echo -e "\n${CYAN}Goodbye! Keep running! 🏃${NC}\n"
                break
                ;;
            status)
                echo "### DEBUG: Chat requested system status"
                status
                ;;
            "")
                continue
                ;;
            *)
                timestamp=$(date +%s)
                rand=$RANDOM
                request_id="msg_${timestamp}_${rand}"
                echo "### DEBUG: Generated request_id=${request_id}"
                
                json_file="${DATA_BUS_DIR}/channels/user_requests/${request_id}.json"
                mkdir -p "${DATA_BUS_DIR}/channels/user_requests"
                
                jq -n \
                    --arg rid "$request_id" \
                    --arg msg "$user_input" \
                    --arg ts "$timestamp" \
                    '{
                        request_id: $rid,
                        message: $msg,
                        timestamp: $ts
                    }' > "$json_file"
                echo "### DEBUG: Request JSON written to ${json_file}"
                
                echo -e "${CYAN}Coach:${NC} Processing..."
                
                response_file="${DATA_BUS_DIR}/channels/user_responses/response_${request_id}.json"
                mkdir -p "${DATA_BUS_DIR}/channels/user_responses"
                counter=0
                max_wait=500
                echo "### DEBUG: Waiting for ${response_file} (timeout=${max_wait}s)"
                
                while [ ! -f "$response_file" ] && [ $counter -lt $max_wait ]; do
                    sleep 1
                    counter=$((counter + 1))
                    if [ $((counter % 3)) -eq 0 ]; then
                        echo -n "."
                    fi
                done
                
                echo ""
                if [ -f "$response_file" ]; then
                    echo "### DEBUG: Response file found for ${request_id}"
                    response_text=$(jq -r '.response' "$response_file" 2>/dev/null || echo "Error reading response")
                    source_agent=$(jq -r '.source // "unknown"' "$response_file" 2>/dev/null)
                    echo "### DEBUG: Response source='${source_agent}', text='${response_text}'"
                    
                    echo -e "${CYAN}Coach [${source_agent}]:${NC} ${response_text}"
                    rm -f "$response_file"
                    echo "### DEBUG: Response file ${response_file} removed"
                else
                    echo "### DEBUG: No response received for ${request_id} after ${max_wait}s"
                    echo -e "${YELLOW}⚠${NC}  No response received after ${max_wait} seconds."
                    echo -e "  Check: ${GREEN}./running_coach.sh logs orchestrator${NC}"
                    echo -e "  Or run: ${GREEN}./debug_system.sh${NC}"
                fi
                echo ""
                ;;
        esac
    done
}

view_logs() {
    local agent=$1
    echo "### DEBUG: view_logs() called for agent='${agent}'"
    if [ -z "${agent}" ]; then
        echo -e "${CYAN}Available logs:${NC}"
        ls -1 "${LOGS_DIR}"/*.log 2>/dev/null | xargs -n1 basename
        echo -e "\nUsage: ./running_coach.sh logs <agent_name>"
    else
        if [ -f "${LOGS_DIR}/${agent}.log" ]; then
            echo "### DEBUG: Tailing ${LOGS_DIR}/${agent}.log"
            tail -f "${LOGS_DIR}/${agent}.log"
        else
            echo "### DEBUG: Log not found: ${LOGS_DIR}/${agent}.log"
            echo -e "${RED}✗${NC} Log file not found: ${agent}.log"
        fi
    fi
}

echo "### DEBUG: Script argument: ${1}"

case "${1}" in
    start)
        echo "### DEBUG: Command=start"
        start_all
        ;;
    stop)
        echo "### DEBUG: Command=stop"
        stop_all
        ;;
    restart)
        echo "### DEBUG: Command=restart"
        stop_all
        sleep 2
        start_all
        ;;
    status)
        echo "### DEBUG: Command=status"
        status
        ;;
    chat)
        echo "### DEBUG: Command=chat"
        chat_mode
        ;;
    logs)
        echo "### DEBUG: Command=logs, target=${2}"
        view_logs "${2}"
        ;;
    *)
        echo "### DEBUG: Invalid or no command specified"
        echo -e "${CYAN}AI Running Coach - System Controller${NC}\n"
        echo "Usage: $0 {start|stop|restart|status|chat|logs [agent]}"
        echo ""
        echo "Commands:"
        echo "  start    - Start all agents"
        echo "  stop     - Stop all agents"
        echo "  restart  - Restart all agents"
        echo "  status   - Show agent status"
        echo "  chat     - Interactive chat mode"
        echo "  logs     - View agent logs"
        echo ""
        exit 1
        ;;
esac

