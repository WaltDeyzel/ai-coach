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

start_agent() {
    local agent_name=$1
    local agent_script="${AGENTS_DIR}/${agent_name}_agent.sh"
    local pid_file="${PID_DIR}/${agent_name}.pid"
    
    if [ -f "${pid_file}" ] && ps -p "$(cat ${pid_file})" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC}  ${agent_name} already running"
        return 0
    fi
    
    if [ ! -f "${agent_script}" ]; then
        echo -e "${RED}✗${NC} Agent script not found: ${agent_script}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} Starting ${agent_name}..."
    nohup bash "${agent_script}" > "${LOGS_DIR}/${agent_name}.log" 2>&1 &
    echo $! > "${pid_file}"
}

stop_agent() {
    local agent_name=$1
    local pid_file="${PID_DIR}/${agent_name}.pid"
    
    if [ ! -f "${pid_file}" ]; then
        echo -e "${YELLOW}⚠${NC}  ${agent_name} not running"
        return 0
    fi
    
    local pid=$(cat "${pid_file}")
    if ps -p "${pid}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Stopping ${agent_name}..."
        kill "${pid}" 2>/dev/null || true
        sleep 1
        kill -9 "${pid}" 2>/dev/null || true
    fi
    rm -f "${pid_file}"
}

start_all() {
    echo -e "${CYAN}Starting AI Running Coach...${NC}\n"
    start_agent "orchestrator"
    sleep 1
    start_agent "training_orchestrator"
    start_agent "nutrition_orchestrator"
    start_agent "injury_orchestrator"
    sleep 1
    start_agent "user_interaction"
    start_agent "data_analysis"
    start_agent "training_planner"
    start_agent "strength_coach"
    start_agent "injury_prevention"
    start_agent "nutritionist"
    echo -e "\n${GREEN}✓${NC} All agents started!"
}

stop_all() {
    echo -e "${CYAN}Stopping all agents...${NC}\n"
    for pid_file in "${PID_DIR}"/*.pid; do
        [ -f "${pid_file}" ] || continue
        agent_name=$(basename "${pid_file}" .pid)
        stop_agent "${agent_name}"
    done
    echo -e "\n${GREEN}✓${NC} All agents stopped!"
}

status() {
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
            echo -e "${GREEN}● RUNNING${NC}"
        else
            echo -e "${RED}○ STOPPED${NC}"
        fi
    done
    echo ""
}

chat_mode() {
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     AI Running Coach - Interactive Chat Mode          ║${NC}"
    echo -e "${CYAN}║  Type 'quit' to exit, 'status' to check agents        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}\n"
    
    while true; do
        echo -ne "${GREEN}You:${NC} "
        read -r user_input
        
        case "${user_input}" in
            quit|exit)
                echo -e "\n${CYAN}Goodbye! Keep running! 🏃${NC}\n"
                break
                ;;
            status)
                status
                ;;
            "")
                continue
                ;;
            *)
                echo "${user_input}" > "${DATA_BUS_DIR}/incoming/user_input.txt"
                echo -e "${CYAN}Coach:${NC} Processing..."
                sleep 3
                
                if ls "${DATA_BUS_DIR}/processed"/response_*.txt 1> /dev/null 2>&1; then
                    cat "${DATA_BUS_DIR}/processed"/response_*.txt
                    rm -f "${DATA_BUS_DIR}/processed"/response_*.txt
                else
                    echo "No response yet. Check logs: ./running_coach.sh logs user_interaction"
                fi
                echo ""
                ;;
        esac
    done
}

view_logs() {
    local agent=$1
    if [ -z "${agent}" ]; then
        echo -e "${CYAN}Available logs:${NC}"
        ls -1 "${LOGS_DIR}"/*.log 2>/dev/null | xargs -n1 basename
        echo -e "\nUsage: ./running_coach.sh logs <agent_name>"
    else
        if [ -f "${LOGS_DIR}/${agent}.log" ]; then
            tail -f "${LOGS_DIR}/${agent}.log"
        else
            echo -e "${RED}✗${NC} Log file not found: ${agent}.log"
        fi
    fi
}

case "${1}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        stop_all
        sleep 2
        start_all
        ;;
    status)
        status
        ;;
    chat)
        chat_mode
        ;;
    logs)
        view_logs "${2}"
        ;;
    *)
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
