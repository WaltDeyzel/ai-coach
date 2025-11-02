#!/bin/bash

# AI Running Coach - Enhanced Main System Control Script
# Complete management interface for the multi-agent system

set -e

# Configuration
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DATA_BUS_DIR="${PROJECT_ROOT}/data_bus"
export SHARED_KB_DIR="${PROJECT_ROOT}/shared_knowledge_base"
export AGENTS_DIR="${PROJECT_ROOT}/agents"
export LOGS_DIR="${PROJECT_ROOT}/logs"
export CONFIG_DIR="${PROJECT_ROOT}/config"
export PID_DIR="${PROJECT_ROOT}/pids"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Initialize directory structure
init_directories() {
    log "Initializing directory structure..."
    
    mkdir -p "${DATA_BUS_DIR}"/{incoming,processed,archive}
    mkdir -p "${DATA_BUS_DIR}/channels"/{user_requests,analysis_summaries,data_alerts,delegation_commands,synthesized_responses,training_directives,nutrition_directives,injury_directives,strength_directives,injury_assessment,sub_orchestrator_reports}
    mkdir -p "${SHARED_KB_DIR}"/{user_profile,training_plans,food_logs,daily_journals,injury_reports,processed_data,system,training,nutrition,injury,strength_workouts,rehab_plans}
    mkdir -p "${AGENTS_DIR}"
    mkdir -p "${LOGS_DIR}"
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${PID_DIR}"
    
    log "Directory structure created successfully"
}

# Initialize system configuration
init_config() {
    log "Initializing system configuration..."
    
    if [ ! -f "${CONFIG_DIR}/system_config.json" ]; then
        cat > "${CONFIG_DIR}/system_config.json" <<EOF
{
    "system": {
        "name": "AI Running Coach",
        "version": "1.0.0",
        "data_bus_poll_interval": 2,
        "max_message_age_seconds": 3600
    },
    "agents": {
        "orchestrator": {"enabled": true, "priority": 1},
        "training_orchestrator": {"enabled": true, "priority": 2},
        "nutrition_orchestrator": {"enabled": true, "priority": 2},
        "injury_orchestrator": {"enabled": true, "priority": 2},
        "user_interaction": {"enabled": true, "priority": 3},
        "data_analysis": {"enabled": true, "priority": 3},
        "training_planner": {"enabled": true, "priority": 4},
        "strength_coach": {"enabled": true, "priority": 4},
        "injury_prevention": {"enabled": true, "priority": 4},
        "nutritionist": {"enabled": true, "priority": 4}
    }
}
EOF
    fi
    
    # Initialize user profile if doesn't exist
    if [ ! -f "${SHARED_KB_DIR}/user_profile/default_user.json" ]; then
        if [ -f "${CONFIG_DIR}/user_profile_template.json" ]; then
            cp "${CONFIG_DIR}/user_profile_template.json" "${SHARED_KB_DIR}/user_profile/default_user.json"
            log "Default user profile created"
        fi
    fi
    
    log "Configuration initialized"
}

# Create all agent scripts if they don't exist
init_agents() {
    log "Checking agent scripts..."
    
    local agents_needed=(
        "orchestrator_agent.sh"
        "training_orchestrator_agent.sh"
        "nutrition_orchestrator_agent.sh"
        "injury_orchestrator_agent.sh"
        "user_interaction_agent.sh"
        "data_analysis_agent.sh"
        "training_planner_agent.sh"
        "strength_coach_agent.sh"
        "injury_prevention_agent.sh"
        "nutritionist_agent.sh"
    )
    
    local missing=0
    for agent in "${agents_needed[@]}"; do
        if [ ! -f "${AGENTS_DIR}/${agent}" ]; then
            warning "Missing: ${agent}"
            ((missing++))
        fi
    done
    
    if [ ${missing} -gt 0 ]; then
        warning "${missing} agent script(s) missing"
        echo "Run './create_agents.sh' to generate all agent scripts"
    else
        log "All agent scripts present"
    fi
}

# Start an agent
start_agent() {
    local agent_name=$1
    local agent_script="${AGENTS_DIR}/${agent_name}_agent.sh"
    local pid_file="${PID_DIR}/${agent_name}.pid"
    
    if [ -f "${pid_file}" ]; then
        local pid=$(cat "${pid_file}")
        if ps -p "${pid}" > /dev/null 2>&1; then
            warning "Agent ${agent_name} is already running (PID: ${pid})"
            return 0
        fi
    fi
    
    if [ ! -f "${agent_script}" ]; then
        error "Agent script not found: ${agent_script}"
        return 1
    fi
    
    log "Starting agent: ${agent_name}"
    nohup bash "${agent_script}" > "${LOGS_DIR}/${agent_name}.log" 2>&1 &
    echo $! > "${pid_file}"
    log "Agent ${agent_name} started (PID: $(cat ${pid_file}))"
}

# Stop an agent
stop_agent() {
    local agent_name=$1
    local pid_file="${PID_DIR}/${agent_name}.pid"
    
    if [ ! -f "${pid_file}" ]; then
        warning "Agent ${agent_name} is not running"
        return 0
    fi
    
    local pid=$(cat "${pid_file}")
    if ps -p "${pid}" > /dev/null 2>&1; then
        log "Stopping agent: ${agent_name} (PID: ${pid})"
        kill "${pid}" 2>/dev/null || true
        sleep 2
        if ps -p "${pid}" > /dev/null 2>&1; then
            warning "Agent did not stop gracefully, forcing..."
            kill -9 "${pid}" 2>/dev/null || true
        fi
        rm -f "${pid_file}"
        log "Agent ${agent_name} stopped"
    else
        warning "Agent ${agent_name} PID file exists but process not found"
        rm -f "${pid_file}"
    fi
}

# Start all agents
start_all() {
    log "Starting all agents..."
    
    start_agent "orchestrator"
    sleep 1
    
    start_agent "training_orchestrator"
    start_agent "nutrition_orchestrator"
    start_agent "injury_orchestrator"
    sleep 1
    
    start_agent "user_interaction"
    start_agent "data_analysis"
    sleep 1
    
    start_agent "training_planner"
    start_agent "strength_coach"
    start_agent "injury_prevention"
    start_agent "nutritionist"
    
    log "All agents started"
    sleep 2
    status
}

# Stop all agents
stop_all() {
    log "Stopping all agents..."
    
    for pid_file in "${PID_DIR}"/*.pid; do
        if [ -f "${pid_file}" ]; then
            agent_name=$(basename "${pid_file}" .pid)
            stop_agent "${agent_name}"
        fi
    done
    
    log "All agents stopped"
}

# Show status
status() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   AI Running Coach System Status      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    
    local running=0
    local stopped=0
    
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
        
        if [ -f "${pid_file}" ]; then
            local pid=$(cat "${pid_file}")
            if ps -p "${pid}" > /dev/null 2>&1; then
                echo -e "${GREEN}● RUNNING${NC} (PID: ${pid})"
                ((running++))
            else
                echo -e "${RED}○ STOPPED${NC} (stale PID)"
                ((stopped++))
            fi
        else
            echo -e "${RED}○ STOPPED${NC}"
            ((stopped++))
        fi
    done
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Summary: ${GREEN}${running} running${NC} │ ${RED}${stopped} stopped${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Send message to the system
send_message() {
    local message="$1"
    
    if [ -z "${message}" ]; then
        error "Message cannot be empty"
        return 1
    fi
    
    info "Sending message to AI Running Coach..."
    echo "${message}" > "${DATA_BUS_DIR}/incoming/user_input.txt"
    
    log "Message sent. Waiting for response..."
    
    # Wait for response (max 10 seconds)
    local timeout=10
    local elapsed=0
    
    while [ ${elapsed} -lt ${timeout} ]; do
        if ls "${DATA_BUS_DIR}/processed"/response_*.txt 1> /dev/null 2>&1; then
            echo -e "\n${CYAN}━━━ Response ━━━${NC}\n"
            cat "${DATA_BUS_DIR}/processed"/response_*.txt
            rm -f "${DATA_BUS_DIR}/processed"/response_*.txt
            echo ""
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    warning "No response received within ${timeout} seconds"
    echo "Check logs for more details: ./running_coach.sh logs user_interaction"
}

# Interactive chat mode
chat_mode() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ╔═══════════════════════════════════════════════════════════╗
   ║                                                           ║
   ║          AI Running Coach - Interactive Chat             ║
   ║                                                           ║
   ║  Type your questions or commands below.                  ║
   ║  Type 'quit' or 'exit' to leave chat mode.              ║
   ║  Type 'help' for available commands.                     ║
   ║                                                           ║
   ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    while true; do
        echo -ne "${GREEN}You:${NC} "
        read -r user_input
        
        case "${user_input}" in
            quit|exit)
                echo -e "\n${CYAN}Goodbye! Keep running! 🏃${NC}\n"
                break
                ;;
            help)
                show_chat_help
                ;;
            status)
                status
                ;;
            "")
                continue
                ;;
            *)
                echo -ne "${BLUE}Coach:${NC} "
                send_message "${user_input}"
                ;;
        esac
        
        echo ""
    done
}

# Show chat help
show_chat_help() {
    echo -e "\n${CYAN}Available Commands:${NC}"
    echo -e "  ${YELLOW}help${NC}     - Show this help message"
    echo -e "  ${YELLOW}status${NC}   - Show system status"
    echo -e "  ${YELLOW}quit${NC}     - Exit chat mode"
    echo -e "\n${CYAN}Example Questions:${NC}"
    echo -e "  • Create a training plan for a 10k race"
    echo -e "  • What should I eat after my long run?"
    echo -e "  • I have knee pain, what should I do?"
    echo -e "  • Show me today's workout"
    echo -e "  • Generate a strength workout"
    echo ""
}

# Cleanup old messages
cleanup() {
    log "Cleaning up old messages..."
    
    find "${DATA_BUS_DIR}/channels" -name "*.json" -mmin +60 -delete 2>/dev/null || true
    find "${DATA_BUS_DIR}/archive" -name "*.json" -mtime +7 -delete 2>/dev/null || true
    find "${DATA_BUS_DIR}/processed" -name "*.txt" -mmin +60 -delete 2>/dev/null || true
    
    log "Cleanup complete"
}

# Backup user data
backup_data() {
    local backup_dir="${PROJECT_ROOT}/backups"
    local backup_file="${backup_dir}/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p "${backup_dir}"
    
    log "Creating backup..."
    
    tar -czf "${backup_file}" \
        -C "${PROJECT_ROOT}" \
        shared_knowledge_base/user_profile \
        shared_knowledge_base/training_plans \
        shared_knowledge_base/food_logs \
        shared_knowledge_base/daily_journals \
        shared_knowledge_base/injury_reports \
        2>/dev/null || true
    
    if [ -f "${backup_file}" ]; then
        log "Backup created: ${backup_file}"
    else
        error "Backup failed"
    fi
}

# Run system tests
run_tests() {
    log "Running system tests..."
    
    if [ -f "${PROJECT_ROOT}/scripts/test_system.sh" ]; then
        bash "${PROJECT_ROOT}/scripts/test_system.sh"
    else
        warning "Test script not found"
    fi
}

# View logs
view_logs() {
    local agent=$1
    
    if [ -z "${agent}" ]; then
        echo -e "${CYAN}Available logs:${NC}"
        ls -1 "${LOGS_DIR}"/*.log 2>/dev/null | xargs -n1 basename | sed 's/^/  /'
        echo ""
        echo "Usage: ./running_coach.sh logs <agent_name>"
    else
        if [ -f "${LOGS_DIR}/${agent}.log" ]; then
            tail -f "${LOGS_DIR}/${agent}.log"
        else
            error "Log file not found: ${agent}.log"
        fi
    fi
}

# Show system info
show_info() {
    echo -e "\n${CYAN}━━━ System Information ━━━${NC}\n"
    echo -e "  Project Root:    ${PROJECT_ROOT}"
    echo -e "  Data Bus:        ${DATA_BUS_DIR}"
    echo -e "  Knowledge Base:  ${SHARED_KB_DIR}"
    echo -e "  Logs:            ${LOGS_DIR}"
    echo ""
    
    if [ -f "${CONFIG_DIR}/system_config.json" ]; then
        echo -e "${CYAN}━━━ Configuration ━━━${NC}\n"
        jq -r '
            "  System: \(.system.name) v\(.system.version)",
            "  Poll Interval: \(.system.data_bus_poll_interval)s",
            "  Enabled Agents: \([.agents | to_entries[] | select(.value.enabled == true) | .key] | length)"
        ' "${CONFIG_DIR}/system_config.json"
        echo ""
    fi
    
    echo -e "${CYAN}━━━ Storage Usage ━━━${NC}\n"
    du -sh "${SHARED_KB_DIR}" 2>/dev/null | awk '{print "  Knowledge Base: "$1}'
    du -sh "${DATA_BUS_DIR}" 2>/dev/null | awk '{print "  Data Bus: "$1}'
    du -sh "${LOGS_DIR}" 2>/dev/null | awk '{print "  Logs: "$1}'
    echo ""
}

# Main command handler
case "${1}" in
    init)
        init_directories
        init_config
        init_agents
        ;;
    start)
        if [ -z "${2}" ]; then
            start_all
        else
            start_agent "${2}"
        fi
        ;;
    stop)
        if [ -z "${2}" ]; then
            stop_all
        else
            stop_agent "${2}"
        fi
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
    send)
        shift
        send_message "$*"
        ;;
    cleanup)
        cleanup
        ;;
    backup)
        backup_data
        ;;
    test)
        run_tests
        ;;
    logs)
        view_logs "${2}"
        ;;
    info)
        show_info
        ;;
    *)
        echo -e "${CYAN}"
        cat << "EOF"
   ╔═══════════════════════════════════════════════════════════╗
   ║                                                           ║
   ║          AI Running Coach - System Controller             ║
   ║                                                           ║
   ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        echo "Usage: $0 {command} [options]"
        echo ""
        echo -e "${CYAN}System Commands:${NC}"
        echo "  init              - Initialize directory structure and config"
        echo "  start [agent]     - Start all agents or a specific agent"
        echo "  stop [agent]      - Stop all agents or a specific agent"
        echo "  restart           - Restart all agents"
        echo "  status            - Show status of all agents"
        echo ""
        echo -e "${CYAN}Interaction Commands:${NC}"
        echo "  chat              - Start interactive chat mode"
        echo "  send \"message\"    - Send a single message"
        echo ""
        echo -e "${CYAN}Maintenance Commands:${NC}"
        echo "  cleanup           - Clean old messages from data bus"
        echo "  backup            - Backup user data"
        echo "  logs [agent]      - Show logs (all or specific agent)"
        echo "  test              - Run system tests"
        echo "  info              - Show system information"
        echo ""
        echo -e "${CYAN}Available Agents:${NC}"
        echo "  orchestrator, training_orchestrator, nutrition_orchestrator,"
        echo "  injury_orchestrator, user_interaction, data_analysis,"
        echo "  training_planner, strength_coach, injury_prevention, nutritionist"
        echo ""
        exit 1
        ;;
esac
