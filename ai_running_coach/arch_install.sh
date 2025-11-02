#!/bin/bash

# AI Running Coach - Arch Linux Installation Script
# Optimized for Arch Linux and gemini-cli integration

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
    ___    ____   ____                   _             ______                __  
   /   |  /  _/  / __ \__  ______  ____(_)___  ____ _/ ____/___  ____ ______/ /_ 
  / /| |  / /   / /_/ / / / / __ \/ __  / __ \/ __ `/ /   / __ \/ __ `/ ___/ __ \
 / ___ |_/ /   / _, _/ /_/ / / / / /_/ / / / / /_/ / /___/ /_/ / /_/ / /__/ / / /
/_/  |_/___/  /_/ |_|\__,_/_/ /_/\__,_/_/ /_/\__, /\____/\____/\__,_/\___/_/ /_/ 
                                             /____/                               
EOF
echo -e "${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Arch Linux Installation & Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo -e "${GREEN}✓${NC} Project root: ${PROJECT_ROOT}\n"

# Check dependencies
echo -e "${BLUE}━━━ Checking Dependencies ━━━${NC}"

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
    GEMINI_AVAILABLE=true
else
    echo -e "${YELLOW}⚠${NC}  gemini-cli is not installed (optional)"
    GEMINI_AVAILABLE=false
fi

if [ "$DEPS_OK" = false ]; then
    echo -e "\n${YELLOW}━━━ Missing Dependencies ━━━${NC}"
    echo -e "${YELLOW}The following dependencies are required:${NC}\n"
    
    # Build pacman install command
    PACMAN_PACKAGES=()
    for dep in "${MISSING_DEPS[@]}"; do
        case "$dep" in
            jq)
                PACMAN_PACKAGES+=("jq")
                ;;
            python)
                PACMAN_PACKAGES+=("python")
                ;;
            pip)
                PACMAN_PACKAGES+=("python-pip")
                ;;
        esac
    done
    
    if [ ${#PACMAN_PACKAGES[@]} -gt 0 ]; then
        echo -e "  ${CYAN}Install with:${NC}"
        echo -e "  ${GREEN}sudo pacman -S ${PACMAN_PACKAGES[*]}${NC}\n"
        
        read -p "Install missing packages now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --noconfirm "${PACMAN_PACKAGES[@]}"
            echo -e "\n${GREEN}✓${NC} Dependencies installed"
        else
            echo -e "${YELLOW}Please install missing dependencies and run this script again.${NC}"
            exit 1
        fi
    fi
fi

# Offer to install gemini-cli if not present
if [ "$GEMINI_AVAILABLE" = false ]; then
    echo -e "\n${CYAN}━━━ Gemini CLI Integration (Optional) ━━━${NC}"
    echo -e "Would you like to install gemini-cli for AI-powered responses?"
    echo -e "${YELLOW}Note:${NC} This requires an API key from Google AI Studio"
    echo ""
    read -p "Install gemini-cli? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing gemini-cli from npm..."
        if command -v npm &> /dev/null; then
            npm install -g gemini-cli
            echo -e "${GREEN}✓${NC} gemini-cli installed"
            GEMINI_AVAILABLE=true
        elif command -v yay &> /dev/null; then
            yay -S gemini-cli
            echo -e "${GREEN}✓${NC} gemini-cli installed"
            GEMINI_AVAILABLE=true
        else
            echo -e "${YELLOW}⚠${NC}  npm not found. Install nodejs first:"
            echo -e "  ${GREEN}sudo pacman -S nodejs npm${NC}"
        fi
    fi
fi

echo -e "\n${GREEN}✓ All required dependencies satisfied${NC}\n"

# Create directory structure
echo -e "${BLUE}━━━ Creating Directory Structure ━━━${NC}"

mkdir -p "${PROJECT_ROOT}"/{agents,lib,python,config,data_bus,shared_knowledge_base,logs,pids,scripts,tests,docs}
mkdir -p "${PROJECT_ROOT}/data_bus"/{incoming,processed,archive}
mkdir -p "${PROJECT_ROOT}/data_bus/channels"/{user_requests,analysis_summaries,data_alerts,delegation_commands,synthesized_responses,training_directives,nutrition_directives,injury_directives,strength_directives,injury_assessment,sub_orchestrator_reports,gemini_requests,gemini_responses}
mkdir -p "${PROJECT_ROOT}/shared_knowledge_base"/{user_profile,training_plans,food_logs,daily_journals,injury_reports,processed_data,system,training,nutrition,injury,strength_workouts,rehab_plans}

echo -e "${GREEN}✓${NC} Directory structure created\n"

# Create configuration files
echo -e "${BLUE}━━━ Creating Configuration Files ━━━${NC}"

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
        "enabled": false,
        "model": "gemini-pro",
        "use_for_intents": ["general", "analysis", "explanation"]
    }
}
EOF

echo -e "${GREEN}✓${NC} System configuration created"

# Create gemini integration config
cat > "${PROJECT_ROOT}/config/gemini_config.json" <<'EOF'
{
    "enabled": false,
    "api_key_env_var": "GEMINI_API_KEY",
    "model": "gemini-pro",
    "temperature": 0.7,
    "use_cases": {
        "natural_language_parsing": true,
        "training_advice": true,
        "injury_analysis": true,
        "nutrition_suggestions": true,
        "general_questions": true
    },
    "fallback_to_local": true
}
EOF

echo -e "${GREEN}✓${NC} Gemini configuration created"

# Create Arch-specific databus library
cat > "${PROJECT_ROOT}/lib/databus.sh" <<'EOF'
#!/bin/bash
# Data Bus Communication Library - Arch Linux Compatible

generate_message_id() {
    echo "msg_$(date +%s)_$$_${RANDOM}"
}

publish_message() {
    local channel=$1
    local msg_type=$2
    local data=$3
    
    local msg_id=$(generate_message_id)
    # Arch-compatible timestamp (without milliseconds)
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

# Gemini CLI integration helper
call_gemini() {
    local prompt=$1
    local output_file=$2
    
    if command -v gemini &> /dev/null; then
        gemini "${prompt}" > "${output_file}" 2>/dev/null || echo "Error calling Gemini" > "${output_file}"
    else
        echo "Gemini CLI not available" > "${output_file}"
    fi
}
EOF

chmod +x "${PROJECT_ROOT}/lib/databus.sh"
echo -e "${GREEN}✓${NC} Arch-compatible data bus library created"

# Create user profile template
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

# Create Python requirements
cat > "${PROJECT_ROOT}/requirements.txt" <<'EOF'
requests>=2.31.0
python-dateutil>=2.8.2
numpy>=1.24.0
pandas>=2.0.0
EOF

echo -e "${GREEN}✓${NC} Requirements file created"

# Install Python packages
echo -e "\n${BLUE}━━━ Installing Python Dependencies ━━━${NC}"
if command -v pip &> /dev/null; then
    pip install -r "${PROJECT_ROOT}/requirements.txt" --quiet --break-system-packages 2>/dev/null || \
    pip install -r "${PROJECT_ROOT}/requirements.txt" --quiet --user
    echo -e "${GREEN}✓${NC} Python packages installed"
else
    echo -e "${YELLOW}⚠${NC}  pip not found. Please install Python packages manually:"
    echo -e "   ${CYAN}pip install -r requirements.txt --user${NC}"
fi

# Create .gitignore
cat > "${PROJECT_ROOT}/.gitignore" <<'EOF'
logs/*.log
pids/*.pid
data_bus/channels/*/*.json
data_bus/archive/*/*.json
data_bus/incoming/*
data_bus/processed/*
__pycache__/
*.py[cod]
.DS_Store
*.swp
.vscode/
.idea/
EOF

echo -e "${GREEN}✓${NC} .gitignore created"

# Create Arch-specific README
cat > "${PROJECT_ROOT}/README_ARCH.md" <<'EOF'
# AI Running Coach - Arch Linux Edition

## Arch-Specific Notes

### Installation
```bash
# Install dependencies
sudo pacman -S jq python python-pip

# Optional: Install gemini-cli
sudo pacman -S nodejs npm
npm install -g gemini-cli
```

### Gemini CLI Integration

If you have gemini-cli installed, you can enable AI-powered responses:

1. Get API key from https://makersuite.google.com/app/apikey
2. Set environment variable:
```bash
export GEMINI_API_KEY="your-api-key-here"
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
```

3. Enable in config:
```bash
nano config/gemini_config.json
# Set "enabled": true
```

### Differences from Ubuntu Version
- Uses `pacman` instead of `apt-get`
- Date command doesn't use milliseconds
- Python packages installed with `--break-system-packages` flag if needed

### Running on Arch
Everything else works the same:
```bash
./running_coach.sh start
./running_coach.sh chat
```
EOF

echo -e "${GREEN}✓${NC} Arch-specific README created"

# Make scripts executable
chmod +x "${PROJECT_ROOT}"/*.sh 2>/dev/null || true

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Installation Complete! 🎉${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${CYAN}📋 Next Steps:${NC}\n"
echo -e "  ${YELLOW}1.${NC} Initialize the system:"
echo -e "     ${GREEN}./running_coach.sh init${NC}\n"
echo -e "  ${YELLOW}2.${NC} Generate agents and Python helpers:"
echo -e "     ${GREEN}./create_agents.sh${NC}"
echo -e "     ${GREEN}python create_python_helpers.py${NC}\n"
echo -e "  ${YELLOW}3.${NC} Configure your profile:"
echo -e "     ${GREEN}cp config/user_profile_template.json shared_knowledge_base/user_profile/default_user.json${NC}"
echo -e "     ${GREEN}nano shared_knowledge_base/user_profile/default_user.json${NC}\n"
echo -e "  ${YELLOW}4.${NC} Start the system:"
echo -e "     ${GREEN}./running_coach.sh start${NC}\n"

if [ "$GEMINI_AVAILABLE" = true ]; then
    echo -e "${CYAN}🤖 Gemini CLI Detected!${NC}"
    echo -e "  To enable AI-powered responses:"
    echo -e "  ${GREEN}export GEMINI_API_KEY='your-key-here'${NC}"
    echo -e "  ${GREEN}nano config/gemini_config.json${NC} (set enabled: true)\n"
fi

echo -e "${CYAN}📚 For more information:${NC}"
echo -e "  - Read ${GREEN}README_ARCH.md${NC} for Arch-specific notes"
echo -e "  - Read ${GREEN}README.md${NC} for general documentation\n"
