#!/bin/bash

# AI Running Coach - Complete Installation Script
# This script sets up everything you need

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
echo -e "${BLUE}       Installation & Setup${NC}"
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
check_dependency "python3" || DEPS_OK=false

if [ "$DEPS_OK" = false ]; then
    echo -e "\n${YELLOW}━━━ Missing Dependencies ━━━${NC}"
    echo -e "${YELLOW}The following dependencies are required:${NC}\n"
    
    for dep in "${MISSING_DEPS[@]}"; do
        case "$dep" in
            jq)
                echo -e "  ${CYAN}jq${NC} - JSON processor"
                echo -e "    Ubuntu/Debian: ${GREEN}sudo apt-get install jq${NC}"
                echo -e "    macOS:         ${GREEN}brew install jq${NC}"
                echo -e "    RHEL/CentOS:   ${GREEN}sudo yum install jq${NC}"
                ;;
            python3)
                echo -e "  ${CYAN}python3${NC} - Python 3.x"
                echo -e "    Ubuntu/Debian: ${GREEN}sudo apt-get install python3 python3-pip${NC}"
                echo -e "    macOS:         ${GREEN}brew install python3${NC}"
                echo -e "    RHEL/CentOS:   ${GREEN}sudo yum install python3 python3-pip${NC}"
                ;;
        esac
        echo ""
    done
    
    echo -e "${YELLOW}Please install missing dependencies and run this script again.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ All dependencies satisfied${NC}\n"

# Create directory structure
echo -e "${BLUE}━━━ Creating Directory Structure ━━━${NC}"

# Main directories
mkdir -p "${PROJECT_ROOT}"/{agents,lib,python,config,data_bus,shared_knowledge_base,logs,pids,scripts,tests,docs}

# Data bus channels
mkdir -p "${PROJECT_ROOT}/data_bus"/{incoming,processed,archive}
mkdir -p "${PROJECT_ROOT}/data_bus/channels"/{user_requests,analysis_summaries,data_alerts,delegation_commands,synthesized_responses,training_directives,nutrition_directives,injury_directives,strength_directives,injury_assessment,sub_orchestrator_reports}

# Knowledge base domains
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
        "log_level": "INFO"
    },
    "agents": {
        "orchestrator": {
            "enabled": true,
            "priority": 1,
            "description": "Main system coordinator"
        },
        "training_orchestrator": {
            "enabled": true,
            "priority": 2,
            "description": "Training activities coordinator"
        },
        "nutrition_orchestrator": {
            "enabled": true,
            "priority": 2,
            "description": "Nutrition activities coordinator"
        },
        "injury_orchestrator": {
            "enabled": true,
            "priority": 2,
            "description": "Injury management coordinator"
        },
        "user_interaction": {
            "enabled": true,
            "priority": 3,
            "description": "User interface handler"
        },
        "data_analysis": {
            "enabled": true,
            "priority": 3,
            "description": "Data processing and analysis"
        },
        "training_planner": {
            "enabled": true,
            "priority": 4,
            "description": "Training plan generation"
        },
        "strength_coach": {
            "enabled": true,
            "priority": 4,
            "description": "Strength workout provider"
        },
        "injury_prevention": {
            "enabled": true,
            "priority": 4,
            "description": "Injury prevention and rehab"
        },
        "nutritionist": {
            "enabled": true,
            "priority": 4,
            "description": "Nutrition advice provider"
        }
    },
    "storage": {
        "data_retention_days": 90,
        "archive_after_days": 7,
        "backup_enabled": true
    }
}
EOF

echo -e "${GREEN}✓${NC} System configuration created"

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
            "10k": "00:52:00",
            "half_marathon": null,
            "marathon": null
        },
        "fitness_level": "intermediate"
    },
    "goals": {
        "target_race": "10k",
        "target_time": "00:50:00",
        "race_date": "2025-06-01",
        "secondary_goals": ["improve_endurance", "prevent_injuries"]
    },
    "preferences": {
        "training_days_per_week": 4,
        "preferred_training_days": ["monday", "wednesday", "friday", "sunday"],
        "available_equipment": ["bodyweight", "resistance_bands", "dumbbells"],
        "dietary_restrictions": [],
        "dietary_preferences": []
    },
    "health": {
        "current_injuries": [],
        "injury_history": [],
        "medical_conditions": [],
        "medications": []
    }
}
EOF

echo -e "${GREEN}✓${NC} User profile template created"

# Create Python requirements
cat > "${PROJECT_ROOT}/requirements.txt" <<'EOF'
# Core dependencies
requests>=2.31.0
python-dateutil>=2.8.2

# Data processing
numpy>=1.24.0
pandas>=2.0.0

# Optional: For advanced features
# scipy>=1.10.0
# scikit-learn>=1.3.0
EOF

echo -e "${GREEN}✓${NC} Requirements file created"

# Install Python packages
echo -e "\n${BLUE}━━━ Installing Python Dependencies ━━━${NC}"
if command -v pip3 &> /dev/null; then
    pip3 install -r "${PROJECT_ROOT}/requirements.txt" --quiet
    echo -e "${GREEN}✓${NC} Python packages installed"
else
    echo -e "${YELLOW}⚠${NC}  pip3 not found. Please install Python packages manually:"
    echo -e "   ${CYAN}pip3 install -r requirements.txt${NC}"
fi

# Create comprehensive README
cat > "${PROJECT_ROOT}/README.md" <<'EOF'
# 🏃 AI Running Coach - Multi-Agent System

A sophisticated, extensible multi-agent system for personalized running coaching.

## 🌟 Features

- **Personalized Training Plans**: Dynamic, adaptive training schedules
- **Injury Prevention**: Proactive monitoring and rehab recommendations
- **Nutrition Guidance**: Meal planning and hydration strategies
- **Strength Training**: Complementary strength workouts
- **Performance Analytics**: Data-driven insights and progress tracking

## 🚀 Quick Start

### 1. Installation

```bash
chmod +x install.sh
./install.sh
```

### 2. First-Time Setup

```bash
# Initialize the system
./running_coach.sh init

# Configure your profile
nano shared_knowledge_base/user_profile/default_user.json
```

### 3. Start the System

```bash
# Start all agents
./running_coach.sh start

# Check status
./running_coach.sh status
```

### 4. Interact with the Coach

```bash
# Use the CLI interface
./running_coach.sh chat

# Or send direct commands
./running_coach.sh send "Create a training plan for a 10k race"
```

## 📖 Documentation

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OrchestratorAgent                        │
│              (Central Coordination Layer)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┬──────────────┐
        │             │             │              │
        ▼             ▼             ▼              ▼
┌──────────────┐ ┌─────────┐ ┌──────────┐ ┌──────────────┐
│   Training   │ │Nutrition│ │  Injury  │ │    Data      │
│ Orchestrator │ │Orchest. │ │Orchest.  │ │  Analysis    │
└──────┬───────┘ └────┬────┘ └────┬─────┘ └──────────────┘
       │              │            │
   ┌───┴────┐    ┌───┴───┐   ┌───┴────┐
   │Training│    │Nutrit-│   │ Injury │
   │Planner │    │ionist │   │Prevent.│
   └────────┘    └───────┘   └────────┘
   │Strength│
   │ Coach  │
   └────────┘
```

### Data Storage

All your data is stored locally in the `shared_knowledge_base/` directory:

- **User Profile**: `user_profile/default_user.json`
- **Training Plans**: `training_plans/current.json`
- **Food Logs**: `food_logs/YYYY-MM-DD.json`
- **Daily Journals**: `daily_journals/YYYY-MM-DD.json`
- **Injury Reports**: `injury_reports/*.json`
- **Performance Data**: `processed_data/*.json`

### Adding New Agents

1. Create agent script in `agents/` directory:

```bash
#!/bin/bash
export AGENT_NAME="my_new_agent"
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/databus.sh"

initialize() {
    log_agent "INFO" "MyNewAgent starting..."
    # Your initialization code
}

main_loop() {
    while should_run; do
        # Your agent logic
        sleep_interval
    done
}

initialize
main_loop
```

2. Register in `config/system_config.json`
3. Restart the system

## 🔧 Commands

```bash
# System control
./running_coach.sh start           # Start all agents
./running_coach.sh stop            # Stop all agents
./running_coach.sh restart         # Restart system
./running_coach.sh status          # Show agent status

# Monitoring
./running_coach.sh logs            # View all logs
./running_coach.sh logs <agent>    # View specific agent log

# Interaction
./running_coach.sh chat            # Interactive chat
./running_coach.sh send "message"  # Send single message

# Maintenance
./running_coach.sh cleanup         # Clean old messages
./running_coach.sh backup          # Backup user data
./running_coach.sh test            # Run system tests
```

## 📊 Data Flow

1. **User Input** → UserInteractionAgent → Data Bus
2. **OrchestratorAgent** reads from Data Bus → Routes to Sub-Orchestrator
3. **Sub-Orchestrator** delegates to Specialist Agents
4. **Specialist Agents** process & write to Knowledge Base
5. **Response** flows back through orchestrators to user

## 🔒 Privacy & Data

- All data stored locally on your machine
- No external API calls by default
- Full control over your information
- Easy backup and export

## 📝 Configuration

Edit `config/system_config.json` to customize:
- Agent behavior
- Polling intervals
- Data retention policies
- Logging levels

## 🐛 Troubleshooting

**Agents won't start?**
- Check logs: `./running_coach.sh logs`
- Verify dependencies: `jq --version` and `python3 --version`
- Re-initialize: `./running_coach.sh init`

**Messages not processing?**
- Check data bus: `ls -la data_bus/channels/user_requests/`
- Verify agent status: `./running_coach.sh status`

**Need help?**
- Run tests: `./running_coach.sh test`
- Check documentation in `docs/`

## 📄 License

MIT License - See LICENSE file for details
EOF

echo -e "${GREEN}✓${NC} README created\n"

# Create .gitignore
cat > "${PROJECT_ROOT}/.gitignore" <<'EOF'
# Logs
logs/*.log

# PID files
pids/*.pid

# Data bus runtime
data_bus/channels/*/*.json
data_bus/archive/*/*.json
data_bus/incoming/*
data_bus/processed/*

# User data (comment out if you want to version control)
shared_knowledge_base/user_profile/*.json
shared_knowledge_base/food_logs/*.json
shared_knowledge_base/daily_journals/*.json
shared_knowledge_base/injury_reports/*.json

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv
*.egg-info/

# OS
.DS_Store
Thumbs.db
*.swp
*.swo

# IDE
.vscode/
.idea/
*.sublime-*
EOF

echo -e "${GREEN}✓${NC} .gitignore created"

# Make all scripts executable
chmod +x "${PROJECT_ROOT}"/*.sh 2>/dev/null || true
find "${PROJECT_ROOT}/agents" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "${PROJECT_ROOT}/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "${PROJECT_ROOT}/python" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Installation Complete! 🎉${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${CYAN}📋 Next Steps:${NC}\n"
echo -e "  ${YELLOW}1.${NC} Initialize the system:"
echo -e "     ${GREEN}./running_coach.sh init${NC}\n"
echo -e "  ${YELLOW}2.${NC} Configure your profile:"
echo -e "     ${GREEN}nano config/user_profile_template.json${NC}"
echo -e "     ${GREEN}cp config/user_profile_template.json shared_knowledge_base/user_profile/default_user.json${NC}\n"
echo -e "  ${YELLOW}3.${NC} Start the system:"
echo -e "     ${GREEN}./running_coach.sh start${NC}\n"
echo -e "  ${YELLOW}4.${NC} Check status:"
echo -e "     ${GREEN}./running_coach.sh status${NC}\n"
echo -e "  ${YELLOW}5.${NC} Start chatting:"
echo -e "     ${GREEN}./running_coach.sh chat${NC}\n"

echo -e "${CYAN}📚 For more information:${NC}"
echo -e "  - Read ${GREEN}README.md${NC} for detailed documentation"
echo -e "  - Check ${GREEN}docs/${NC} for guides and examples"
echo -e "  - Run ${GREEN}./running_coach.sh test${NC} to verify installation\n"
