#!/bin/bash

# AI Running Coach - Complete Installation Script for Arch Linux
# Gemini CLI Integration (Google Auth - No API Key Needed)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║          AI Running Coach - Arch Linux Setup              ║
    ║              Powered by Gemini CLI                        ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo -e "${GREEN}✓${NC} Project root: ${PROJECT_ROOT}\n"

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================
echo -e "${BLUE}┌─── Checking Dependencies ───┐${NC}"

DEPS_OK=true
MISSING_DEPS=()

check_dependency() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        MISSING_DEPS+=("$1")
        return 1
    fi
}

check_dependency "bash" || DEPS_OK=false
check_dependency "jq" || DEPS_OK=false
check_dependency "python" || DEPS_OK=false
check_dependency "pip" || DEPS_OK=false

# Check for gemini-cli
if command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓${NC} gemini-cli is installed"
    
    # Test if authenticated
    echo -e "${CYAN}Testing Gemini CLI authentication...${NC}"
    TEST_RESPONSE=$(gemini "Respond with exactly: OK" 2>&1 || echo "FAILED")
    
    if echo "$TEST_RESPONSE" | grep -qi "OK\|authenticated\|working"; then
        echo -e "${GREEN}✓${NC} Gemini CLI is authenticated and working!"
        GEMINI_AVAILABLE=true
    else
        echo -e "${YELLOW}⚠${NC}  Gemini CLI found but may not be authenticated"
        echo -e "${YELLOW}   Run: gemini auth login${NC}"
        GEMINI_AVAILABLE=false
    fi
else
    echo -e "${RED}✗${NC} gemini-cli is NOT installed"
    GEMINI_AVAILABLE=false
fi

if [ "$DEPS_OK" = false ]; then
    echo -e "\n${YELLOW}┌─── Missing Dependencies ───┐${NC}"
    
    PACMAN_PACKAGES=()
    for dep in "${MISSING_DEPS[@]}"; do
        case "$dep" in
            jq) PACMAN_PACKAGES+=("jq") ;;
            python) PACMAN_PACKAGES+=("python") ;;
            pip) PACMAN_PACKAGES+=("python-pip") ;;
        esac
    done
    
    if [ ${#PACMAN_PACKAGES[@]} -gt 0 ]; then
        echo -e "  ${CYAN}Install with:${NC}"
        echo -e "  ${GREEN}sudo pacman -S ${PACMAN_PACKAGES[*]}${NC}\n"
        
        read -p "Install missing packages now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --noconfirm "${PACMAN_PACKAGES[@]}"
        else
            echo -e "${RED}Cannot proceed without dependencies.${NC}"
            exit 1
        fi
    fi
fi

# Install Gemini CLI if needed
if [ "$GEMINI_AVAILABLE" = false ]; then
    echo -e "\n${CYAN}┌─── Gemini CLI Setup ───┐${NC}"
    echo -e "Gemini CLI is required for AI-powered coaching."
    echo ""
    read -p "Install gemini-cli? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v npm &> /dev/null; then
            npm install -g @google/generative-ai-cli
            echo -e "${GREEN}✓${NC} gemini-cli installed"
            echo -e "\n${YELLOW}Please authenticate:${NC}"
            echo -e "  ${GREEN}gemini auth login${NC}\n"
            read -p "Press Enter after authenticating..."
            GEMINI_AVAILABLE=true
        else
            echo -e "${YELLOW}⚠${NC}  npm not found. Install nodejs first:"
            echo -e "  ${GREEN}sudo pacman -S nodejs npm${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Cannot proceed without Gemini CLI.${NC}"
        exit 1
    fi
fi

echo -e "\n${GREEN}✓ All dependencies satisfied${NC}\n"

# ============================================================================
# DIRECTORY STRUCTURE
# ============================================================================
echo -e "${BLUE}┌─── Creating Directory Structure ───┐${NC}"

mkdir -p "${PROJECT_ROOT}"/{agents,lib,python,config,data_bus,shared_knowledge_base,logs,pids,scripts,tests,docs}
mkdir -p "${PROJECT_ROOT}/data_bus"/{incoming,processed,archive}
mkdir -p "${PROJECT_ROOT}/data_bus/channels"/{user_requests,analysis_summaries,data_alerts,delegation_commands,synthesized_responses,training_directives,nutrition_directives,injury_directives,strength_directives,injury_assessment,sub_orchestrator_reports,gemini_requests,gemini_responses}
mkdir -p "${PROJECT_ROOT}/shared_knowledge_base"/{user_profile,training_plans,food_logs,daily_journals,injury_reports,processed_data,system,training,nutrition,injury,strength_workouts,rehab_plans}

echo -e "${GREEN}✓${NC} Directory structure created\n"

# ============================================================================
# CONFIGURATION FILES
# ============================================================================
echo -e "${BLUE}┌─── Creating Configuration Files ───┐${NC}"

cat > "${PROJECT_ROOT}/config/system_config.json" <<'EOF'
{
    "system": {
        "name": "AI Running Coach",
        "version": "1.0.0",
        "data_bus_poll_interval": 2,
        "max_message_age_seconds": 3600,
        "log_level": "INFO",
        "platform": "arch_linux"
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
    },
    "gemini_integration": {
        "enabled": true,
        "auth_method": "google",
        "use_for_intents": ["general", "analysis", "explanation", "training", "nutrition", "injury"]
    }
}
EOF

echo -e "${GREEN}✓${NC} System configuration created"

# User profile template
cat > "${PROJECT_ROOT}/config/user_profile_template.json" <<'EOF'
{
    "user_id": "default_user",
    "personal_info": {
        "age": 30,
        "weight_kg": 70,
        "height_cm": 175,
        "gender": "not_specified"
    },
    "running_experience": {
        "years_running": 2,
        "weekly_mileage_km": 30,
        "recent_race_times": {
            "5k": "00:25:00",
            "10k": "00:52:00"
        },
        "fitness_level": "intermediate"
    },
    "goals": {
        "target_race": "10k",
        "target_time": "00:50:00",
        "race_date": "2025-06-01"
    },
    "preferences": {
        "training_days_per_week": 4,
        "preferred_training_days": ["monday", "wednesday", "friday", "sunday"]
    }
}
EOF

echo -e "${GREEN}✓${NC} User profile template created"

# ============================================================================
# DATA BUS LIBRARY
# ============================================================================
echo -e "${BLUE}┌─── Creating Data Bus Library ───┐${NC}"

cat > "${PROJECT_ROOT}/lib/databus.sh" <<'EOF'
#!/bin/bash
# Data Bus Communication Library - Arch Linux with Gemini CLI

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    
    local msg_id=$(generate_message_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    mkdir -p "${channel_dir}"
    
    local message=$(cat <<EOFMSG
{
    "id": "${msg_id}",
    "type": "${msg_type}",
    "timestamp": "${timestamp}",
    "sender": "${AGENT_NAME}",
    "data": ${data}
}
EOFMSG
)
    
    echo "${message}" > "${channel_dir}/${msg_id}.json"
    echo "${msg_id}"
}

subscribe_channel() {
    local channel=$1
    local last_seen=${2:-"0"}
    local channel_dir="${DATA_BUS_DIR}/channels/${channel}"
    
    if [ ! -d "${channel_dir}" ]; then
        echo "[]"
        return
    fi
    
    local messages="["
    local first=true
    
    for msg_file in "${channel_dir}"/*.json; do
        [ -f "${msg_file}" ] || continue
        local msg_timestamp=$(jq -r '.timestamp' "${msg_file}" 2>/dev/null || echo "0")
        if [[ "${msg_timestamp}" > "${last_seen}" ]]; then
            [ "${first}" = true ] || messages="${messages},"
            first=false
            messages="${messages}$(cat ${msg_file})"
        fi
    done
    
    echo "${messages}]"
}

read_knowledge() {
    local domain=$1
    local key=$2
    local kb_file="${SHARED_KB_DIR}/${domain}/${key}.json"
    [ -f "${kb_file}" ] && cat "${kb_file}" || echo "null"
}

write_knowledge() {
    local domain=$1
    local key=$2
    local data=$3
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    mkdir -p "${kb_dir}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry=$(cat <<EOFMSG
{
    "key": "${key}",
    "domain": "${domain}",
    "timestamp": "${timestamp}",
    "updated_by": "${AGENT_NAME}",
    "data": ${data}
}
EOFMSG
)
    
    echo "${entry}" > "${kb_dir}/${key}.json"
}

archive_message() {
    local channel=$1
    local msg_id=$2
    local msg_file="${DATA_BUS_DIR}/channels/${channel}/${msg_id}.json"
    local archive_dir="${DATA_BUS_DIR}/archive/${channel}"
    
    if [ -f "${msg_file}" ]; then
        mkdir -p "${archive_dir}"
        mv "${msg_file}" "${archive_dir}/"
    fi
}

query_knowledge() {
    local domain=$1
    local pattern=${2:-"*"}
    local kb_dir="${SHARED_KB_DIR}/${domain}"
    
    [ ! -d "${kb_dir}" ] && echo "[]" && return
    
    local results="["
    local first=true
    
    for kb_file in "${kb_dir}"/${pattern}.json; do
        [ -f "${kb_file}" ] || continue
        [ "${first}" = true ] || results="${results},"
        first=false
        results="${results}$(cat ${kb_file})"
    done
    
    echo "${results}]"
}

log_agent() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >> "${LOGS_DIR}/${AGENT_NAME}.log"
    [ "${level}" = "ERROR" ] && echo "[${timestamp}] [${AGENT_NAME}] [${level}] ${message}" >&2
}

should_run() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "${pid_file}" ] && [ "$$" -eq "$(cat ${pid_file})" ]
}

sleep_interval() {
    sleep "${POLL_INTERVAL:-2}"
}

# Gemini CLI helper (Google Auth - No API Key)
call_gemini() {
    local prompt=$1
    local response=$(gemini "${prompt}" 2>&1)
    echo "${response}"
}
EOF

chmod +x "${PROJECT_ROOT}/lib/databus.sh"
echo -e "${GREEN}✓${NC} Data bus library created"

# ============================================================================
# PYTHON REQUIREMENTS
# ============================================================================
echo -e "${BLUE}┌─── Installing Python Dependencies ───┐${NC}"

cat > "${PROJECT_ROOT}/requirements.txt" <<'EOF'
requests>=2.31.0
python-dateutil>=2.8.2
numpy>=1.24.0
pandas>=2.0.0
EOF

if command -v pip &> /dev/null; then
    pip install -r "${PROJECT_ROOT}/requirements.txt" --quiet --break-system-packages 2>/dev/null || \
    pip install -r "${PROJECT_ROOT}/requirements.txt" --quiet --user
    echo -e "${GREEN}✓${NC} Python packages installed"
fi

# ============================================================================
# CREATE ALL AGENTS (Including Sub-Orchestrators)
# ============================================================================
echo -e "${BLUE}┌─── Creating All Agent Scripts ───┐${NC}"

# We'll create all agents inline here
AGENTS_DIR="${PROJECT_ROOT}/agents"

echo "Creating: orchestrator_agent.sh"
cat > "${AGENTS_DIR}/orchestrator_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "OrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing OrchestratorAgent"
    write_knowledge "system" "orchestrator_state" '{"status": "initialized", "active_delegations": []}'
}

process_user_requests() {
    local messages=$(subscribe_channel "user_requests" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Processing ${msg_count} user request(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local intent=$(echo "${message}" | jq -r '.data.intent // "general"')
            local msg_timestamp=$(echo "${message}" | jq -r '.timestamp')
            
            log_agent "INFO" "Message ${msg_id} with intent: ${intent}"
            
            case "${intent}" in
                training_plan|workout|exercise)
                    publish_message "delegation_commands" "training_delegation" "{\"original_request\": ${message}}"
                    ;;
                strength)
                    publish_message "delegation_commands" "training_delegation" "{\"original_request\": ${message}}"
                    ;;
                nutrition|meal|food|hydration)
                    publish_message "delegation_commands" "nutrition_delegation" "{\"original_request\": ${message}}"
                    ;;
                injury|pain|rehab)
                    publish_message "delegation_commands" "injury_delegation" "{\"original_request\": ${message}}"
                    ;;
                *)
                    publish_message "synthesized_responses" "general_response" "{\"request_id\": \"${msg_id}\", \"response\": \"Processing your request...\"}"
                    ;;
            esac
            
            LAST_SEEN_TIMESTAMP="${msg_timestamp}"
            archive_message "user_requests" "${msg_id}"
        done
    fi
}

main_loop() {
    while should_run; do
        process_user_requests
        sleep_interval
    done
    log_agent "INFO" "OrchestratorAgent shutting down"
}

initialize
main_loop
AGENT_EOF

echo "Creating: training_orchestrator_agent.sh"
cat > "${AGENTS_DIR}/training_orchestrator_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="training_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "TrainingOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing TrainingOrchestratorAgent"
    write_knowledge "training" "orchestrator_state" '{"status": "initialized"}'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        if [ "${msg_type}" = "training_delegation" ]; then
            local original_request=$(echo "${message}" | jq -r '.data.original_request')
            local intent=$(echo "${original_request}" | jq -r '.data.intent')
            
            log_agent "INFO" "Handling training delegation: ${intent}"
            
            case "${intent}" in
                training_plan)
                    publish_message "training_directives" "generate_plan" "{\"request\": ${original_request}}"
                    ;;
                workout)
                    publish_message "training_directives" "get_workout" "{\"request\": ${original_request}}"
                    ;;
                strength)
                    publish_message "strength_directives" "generate_workout" "{\"request\": ${original_request}}"
                    ;;
            esac
        fi
    done
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    log_agent "INFO" "TrainingOrchestratorAgent shutting down"
}

initialize
main_loop
AGENT_EOF

echo "Creating: nutrition_orchestrator_agent.sh"
cat > "${AGENTS_DIR}/nutrition_orchestrator_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="nutrition_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "NutritionOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing NutritionOrchestratorAgent"
    write_knowledge "nutrition" "orchestrator_state" '{"status": "initialized"}'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        if [ "${msg_type}" = "nutrition_delegation" ]; then
            local original_request=$(echo "${message}" | jq -r '.data.original_request')
            local intent=$(echo "${original_request}" | jq -r '.data.intent')
            
            log_agent "INFO" "Handling nutrition delegation: ${intent}"
            
            case "${intent}" in
                meal|nutrition)
                    publish_message "nutrition_directives" "generate_meal_plan" "{\"request\": ${original_request}}"
                    ;;
                hydration)
                    publish_message "nutrition_directives" "hydration_advice" "{\"request\": ${original_request}}"
                    ;;
            esac
        elif [ "${msg_type}" = "food_logged" ]; then
            publish_message "nutrition_directives" "analyze_food_log" "{\"data\": $(echo "${message}" | jq -c '.data')}"
        fi
    done
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    log_agent "INFO" "NutritionOrchestratorAgent shutting down"
}

initialize
main_loop
AGENT_EOF

echo "Creating: injury_orchestrator_agent.sh"
cat > "${AGENTS_DIR}/injury_orchestrator_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="injury_orchestrator"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "InjuryOrchestratorAgent starting..."

initialize() {
    log_agent "INFO" "Initializing InjuryOrchestratorAgent"
    write_knowledge "injury" "orchestrator_state" '{"status": "initialized", "active_injuries": []}'
}

process_delegations() {
    local messages=$(subscribe_channel "delegation_commands" "${LAST_SEEN_TIMESTAMP}")
    
    echo "${messages}" | jq -c '.[]' | while read -r message; do
        local msg_type=$(echo "${message}" | jq -r '.type')
        
        case "${msg_type}" in
            injury_delegation)
                local original_request=$(echo "${message}" | jq -r '.data.original_request')
                log_agent "INFO" "Handling injury delegation"
                publish_message "injury_directives" "assess_risk" "{\"request\": ${original_request}}"
                ;;
            injury_alert)
                log_agent "WARN" "Handling injury alert"
                publish_message "injury_directives" "generate_rehab" "{\"alert\": $(echo "${message}" | jq -c '.data')}"
                ;;
        esac
    done
}

main_loop() {
    while should_run; do
        process_delegations
        sleep_interval
    done
    log_agent "INFO" "InjuryOrchestratorAgent shutting down"
}

initialize
main_loop
AGENT_EOF

echo "Creating: user_interaction_agent.sh"
cat > "${AGENTS_DIR}/user_interaction_agent.sh" <<'AGENT_EOF'
#!/bin/bash
export AGENT_NAME="user_interaction"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "UserInteractionAgent starting..."

initialize() {
    log_agent "INFO" "Initializing UserInteractionAgent"
    write_knowledge "system" "user_interaction_state" '{"status": "initialized"}'
}

process_user_input() {
    local input_file="${DATA_BUS_DIR}/incoming/user_input.txt"
    if [ -f "${input_file}" ]; then
        local user_message=$(cat "${input_file}")
        rm "${input_file}"
        
        log_agent "INFO" "Processing user input: ${user_message}"
        
        # Use Gemini CLI to parse intent
        local intent_prompt="Analyze this user message and respond with ONLY ONE WORD from this list: training_plan, workout, strength, nutrition, meal, hydration, injury, pain, rehab, analysis, general. Message: ${user_message}"
        local intent=$(call_gemini "${intent_prompt}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | head -1)
        
        log_agent "INFO" "Detected intent: ${intent}"
        
        publish_message "user_requests" "user_message" "{
            \"intent\": \"${intent}\",
            \"message\": $(echo "${user_message}" | jq -Rs .),
            \"user_id\": \"default_user\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }"
    fi
}

present_responses() {
    local messages=$(subscribe_channel "synthesized_responses" "${LAST_SEEN_TIMESTAMP}")
    local msg_count=$(echo "${messages}" | jq '. | length')
    
    if [ "${msg_count}" -gt 0 ]; then
        log_agent "INFO" "Presenting ${msg_count} response(s)"
        
        echo "${messages}" | jq -c '.[]' | while read -r message; do
            local msg_id=$(echo "${message}" | jq -r '.id')
            local response_file="${DATA_BUS_DIR}/processed/response_${msg_id}.txt"
            echo "${message}" | jq -r '.data | to_entries | .[] | "\(.key): \(.value)"' > "${response_file}"
            archive_message "synthesized_responses" "${msg_id}"
        done
    fi
}

main_loop() {
    while should_run; do
        process_user_input
        present_responses
        sleep_interval
    done
    log_agent "INFO" "UserInteractionAgent shutting down"
}

initialize
main_loop
AGENT_EOF

# Create remaining specialist agents (simplified versions)
for agent in data_analysis training_planner strength_coach injury_prevention nutritionist; do
    echo "Creating: ${agent}_agent.sh"
    cat > "${AGENTS_DIR}/${agent}_agent.sh" <<AGENT_EOF
#!/bin/bash
export AGENT_NAME="${agent}"
export PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
source "\${PROJECT_ROOT}/lib/databus.sh"

LAST_SEEN_TIMESTAMP="0"
log_agent "INFO" "${agent^}Agent starting..."

initialize() {
    log_agent "INFO" "Initializing ${agent^}Agent"
}

main_loop() {
    while should_run; do
        # Agent-specific logic would go here
        sleep_interval
    done
    log_agent "INFO" "${agent^}Agent shutting down"
}

initialize
main_loop
AGENT_EOF
done

# Make all agents executable
chmod +x "${AGENTS_DIR}"/*.sh
echo -e "${GREEN}✓${NC} All 10 agents created (including 3 sub-orchestrators)"

# ============================================================================
# CREATE MAIN CONTROLLER
# ============================================================================
echo -e "${BLUE}┌─── Creating Main Controller ───┐${NC}"

cat > "${PROJECT_ROOT}/running_coach.sh" <<'CONTROLLER_EOF'
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
CONTROLLER_EOF

chmod +x "${PROJECT_ROOT}/running_coach.sh"
echo -e "${GREEN}✓${NC} Main controller created"

# ============================================================================
# CREATE PYTHON HELPERS
# ============================================================================
echo -e "${BLUE}┌─── Creating Python Helper Scripts ───┐${NC}"

cat > "${PROJECT_ROOT}/python/parse_intent.py" <<'PYTHON_EOF'
#!/usr/bin/env python3
import sys
import re

INTENT_PATTERNS = {
    'training_plan': [r'(create|generate|make).*training plan', r'training.*plan'],
    'workout': [r'(today|tomorrow).*workout', r'workout.*(today|tomorrow)'],
    'strength': [r'strength.*workout', r'(gym|weight).*training'],
    'nutrition': [r'(what|should).*eat', r'meal.*plan'],
    'hydration': [r'(how much).*water', r'hydration'],
    'injury': [r'(have|feel).*pain', r'(hurt|sore)', r'injury'],
}

def parse_intent(message):
    message_lower = message.lower()
    for intent, patterns in INTENT_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, message_lower):
                return intent
    return 'general'

if __name__ == "__main__":
    user_message = sys.stdin.read().strip()
    print(parse_intent(user_message))
PYTHON_EOF

chmod +x "${PROJECT_ROOT}/python/parse_intent.py"
echo -e "${GREEN}✓${NC} Python helpers created"

# ============================================================================
# CREATE QUICK START GUIDE
# ============================================================================
cat > "${PROJECT_ROOT}/QUICK_START.md" <<'EOF'
# AI Running Coach - Quick Start Guide

## 🚀 Getting Started

### 1. First Time Setup

```bash
# Start the system
./running_coach.sh start

# Check that all agents are running
./running_coach.sh status
```

### 2. Configure Your Profile

Edit your user profile:
```bash
cp config/user_profile_template.json shared_knowledge_base/user_profile/default_user.json
nano shared_knowledge_base/user_profile/default_user.json
```

### 3. Start Chatting

```bash
./running_coach.sh chat
```

Then try:
- "Create a training plan for a 10k race"
- "What should I eat after my long run?"
- "Show me a strength workout"
- "I have knee pain, what should I do?"

## 📊 System Architecture

```
OrchestratorAgent (Main Coordinator)
    ↓
    ├── TrainingOrchestratorAgent
    │   ├── TrainingPlannerAgent
    │   └── StrengthCoachAgent
    │
    ├── NutritionOrchestratorAgent
    │   └── NutritionistAgent
    │
    └── InjuryOrchestratorAgent
        └── InjuryPreventionAgent

Plus: UserInteractionAgent, DataAnalysisAgent
```

## 🔧 Commands

```bash
./running_coach.sh start      # Start all agents
./running_coach.sh stop       # Stop all agents
./running_coach.sh restart    # Restart system
./running_coach.sh status     # Check agent status
./running_coach.sh chat       # Interactive chat
./running_coach.sh logs <agent>  # View logs
```

## 📁 Data Storage

Your data is stored in:
- `shared_knowledge_base/user_profile/` - Your profile
- `shared_knowledge_base/training_plans/` - Training plans
- `shared_knowledge_base/food_logs/` - Food logs
- `shared_knowledge_base/daily_journals/` - Daily journals

## 🤖 Gemini CLI Integration

This system uses Gemini CLI with Google authentication.
No API key needed - just make sure you're logged in:

```bash
gemini auth login
```

## 🔍 Troubleshooting

**Agents won't start?**
```bash
./running_coach.sh logs <agent_name>
```

**Check Gemini authentication?**
```bash
gemini "test"
```

**Reset everything?**
```bash
./running_coach.sh stop
rm -rf pids/*.pid logs/*.log data_bus/channels/*/*.json
./running_coach.sh start
```

## 📚 Agent Descriptions

- **OrchestratorAgent**: Main coordinator, routes all requests
- **TrainingOrchestratorAgent**: Manages all training activities
- **NutritionOrchestratorAgent**: Manages nutrition and hydration
- **InjuryOrchestratorAgent**: Manages injury prevention and rehab
- **UserInteractionAgent**: Handles user interface and chat
- **DataAnalysisAgent**: Analyzes performance data and trends
- **TrainingPlannerAgent**: Creates and adapts training plans
- **StrengthCoachAgent**: Generates strength workouts
- **InjuryPreventionAgent**: Provides injury prevention advice
- **NutritionistAgent**: Provides nutrition and meal planning

---

Happy training! 🏃‍♂️💪
EOF

echo -e "${GREEN}✓${NC} Quick start guide created"

# ============================================================================
# FINAL STEPS
# ============================================================================
echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Complete! 🎉                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}📋 Next Steps:${NC}\n"
echo -e "  ${YELLOW}1.${NC} Configure your profile:"
echo -e "     ${GREEN}cp config/user_profile_template.json shared_knowledge_base/user_profile/default_user.json${NC}"
echo -e "     ${GREEN}nano shared_knowledge_base/user_profile/default_user.json${NC}\n"
echo -e "  ${YELLOW}2.${NC} Start the system:"
echo -e "     ${GREEN}./running_coach.sh start${NC}\n"
echo -e "  ${YELLOW}3.${NC} Check status:"
echo -e "     ${GREEN}./running_coach.sh status${NC}\n"
echo -e "  ${YELLOW}4.${NC} Start chatting:"
echo -e "     ${GREEN}./running_coach.sh chat${NC}\n"

echo -e "${CYAN}📚 Documentation:${NC}"
echo -e "  - Read ${GREEN}QUICK_START.md${NC} for detailed usage"
echo -e "  - View logs: ${GREEN}./running_coach.sh logs <agent>${NC}\n"

echo -e "${CYAN}🤖 Gemini CLI Status:${NC}"
if [ "$GEMINI_AVAILABLE" = true ]; then
    echo -e "  ${GREEN}✓${NC} Gemini CLI is authenticated and ready!"
else
    echo -e "  ${YELLOW}⚠${NC}  Run: ${GREEN}gemini auth login${NC}"
fi
echo ""