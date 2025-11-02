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
