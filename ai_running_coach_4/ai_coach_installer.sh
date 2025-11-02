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
mkdir -p "${PROJECT_ROOT}/shared_knowledge_base"/{user_profile,training_plans,food_logs,daily_journals,inury_reports,processed_data,system,training,nutrition,injury,strength_workouts,rehab_plans}

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

echo -e "${GREEN}✓${NC} Configuration files created"

# ============================================================================
# DATA BUS LIBRARY
# ============================================================================
echo -e "${BLUE}┌─── Creating Data Bus Library ───┐${NC}"

cat > "${PROJECT_ROOT}/lib/databus.sh" <<'EOF'
#!/bin/bash
DATA_BUS_DIR="$(dirname "$0")/../data_bus/channels"
SHARED_KB_DIR="$(dirname "$0")/../shared_knowledge_base"
LOGS_DIR="$(dirname "$0")/../logs"
PID_DIR="$(dirname "$0")/../pids"
AGENT_NAME="${AGENT_NAME:-unknown}"
POLL_INTERVAL=2

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    local msg_id=$(generate_message_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    mkdir -p "${channel_dir}"
    local message=$(cat <<MSG
{
    "id": "${msg_id}",
    "type": "${msg_type}",
    "timestamp": "${timestamp}",
    "sender": "${AGENT_NAME}",
    "data": ${data}
}
MSG
)
    echo "${message}" > "${channel_dir}/${msg_id}.json"
    echo "${msg_id}"
}

subscribe_channel() {
    local channel=$1
    local last_seen=${2:-"0"}
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    [ ! -d "$channel_dir" ] && echo "[]" && return
    local messages="["
    local first=true
    for msg_file in "${channel_dir}"/*.json; do
        [ -f "$msg_file" ] || continue
        local msg_timestamp=$(jq -r '.timestamp' "$msg_file" 2>/dev/null || echo "0")
        if [[ "$msg_timestamp" > "$last_seen" ]]; then
            [ "$first" = true ] || messages="${messages},"
            first=false
            messages="${messages}$(cat "$msg_file")"
        fi
    done
    echo "${messages}]"
}

read_knowledge() {
    local file_path="$1"
    [ -f "$file_path" ] && cat "$file_path" || echo "{}"
}

write_knowledge() {
    local domain=$1
    local key=$2
    local data=$3
    local file_path="${SHARED_KB_DIR}/${domain}/${key}.json"
    mkdir -p "$(dirname "$file_path")"
    echo "${data}" > "$file_path"
}

read_channel_message() {
    local channel=$1
    local msg_id=$2
    local msg_file="${DATA_BUS_DIR}/${channel}/${msg_id}.json"
    [ -f "$msg_file" ] && cat "$msg_file" || echo "{}"
}

list_channel_messages() {
    local channel=$1
    local channel_dir="${DATA_BUS_DIR}/${channel}"
    [ ! -d "$channel_dir" ] && return
    ls "${channel_dir}"/*.json 2>/dev/null || true
}

log() {
    local level=$1
    local msg=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp][$level][$AGENT_NAME] $msg"
}

write_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    mkdir -p "$(dirname "$pid_file")"
    echo $$ > "$pid_file"
}

read_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "$pid_file" ] && cat "$pid_file" || echo ""
}

remove_pid() {
    local pid_file="${PID_DIR}/${AGENT_NAME}.pid"
    [ -f "$pid_file" ] && rm "$pid_file"
}
EOF

chmod +x "${PROJECT_ROOT}/lib/databus.sh"
echo -e "${GREEN}✓${NC} Data Bus Library created\n"

# ============================================================================
# AGENT SKELETONS
# ============================================================================
echo -e "${BLUE}┌─── Creating Agent Scripts ───┐${NC}"

AGENTS=(
    orchestrator
    training_orchestrator
    nutrition_orchestrator
    injury_orchestrator
    user_interaction
    data_analysis
    garmin_collector
    training_planner
    strength_coach
    injury_prevention
    nutritionist
)

for agent in "${AGENTS[@]}"; do
    agent_file="${PROJECT_ROOT}/agents/${agent}_agent.sh"
    cat > "$agent_file" <<EOF
#!/bin/bash
AGENT_NAME="${agent}"
source "$(dirname "$0")/../lib/databus.sh"

log "INFO" "Starting agent: \$AGENT_NAME"
write_pid

# Agent main loop
while true; do
    # Poll channels or perform tasks here
    sleep 2
done
EOF
    chmod +x "$agent_file"
done

echo -e "${GREEN}✓${NC} Agent scripts created\n"

# ============================================================================
# MAIN START SCRIPT
# ============================================================================
cat > "${PROJECT_ROOT}/running_coach.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="${SCRIPT_DIR}/agents"

start_agent() {
    local agent_script="$1"
    if [ -f "$agent_script" ]; then
        nohup bash "$agent_script" > "${SCRIPT_DIR}/logs/$(basename $agent_script).log" 2>&1 &
        echo "Started $(basename $agent_script)"
    else
        echo "✗ Agent script not found: $agent_script"
    fi
}

echo "Starting AI Running Coach..."

for agent_script in "$AGENT_DIR"/*_agent.sh; do
    start_agent "$agent_script"
done
EOF

chmod +x "${PROJECT_ROOT}/running_coach.sh"
echo -e "${GREEN}✓${NC} Main start script created\n"

echo -e "${CYAN}Installation complete!${NC}"
echo "Run ./running_coach.sh start to launch all agents."

