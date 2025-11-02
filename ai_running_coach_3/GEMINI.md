# AI Running Coach

## Project Overview

This project is a multi-agent AI running coach system. It uses a collection of shell scripts to manage and coordinate a set of specialized AI agents. The agents communicate through a file-based message bus. The core logic for data collection and other tasks is in Python. The system is designed to be interacted with via a command-line chat interface.

The architecture consists of a main `running_coach.sh` script that acts as the system controller, handling starting, stopping, and checking the status of all agents. Agents are implemented as shell scripts in the `agents/` directory. The `orchestrator_agent.sh` is the central coordinator, receiving user requests and delegating them to other agents based on intent. It uses `gemini` to determine the correct agent for a given request. Python scripts in the `python/` directory handle specific tasks like collecting data from the Garmin API. A file-based data bus in the `data_bus/` directory is used for inter-agent communication. Shared data and agent state are stored in the `shared_knowledge_base/` directory.

## Building and Running

### Dependencies

Install Python dependencies:

```bash
pip install -r requirements.txt
```

### Running the System

The main entry point for the system is the `running_coach.sh` script.

*   **Start all agents:**
    ```bash
    ./running_coach.sh start
    ```

*   **Stop all agents:**
    ```bash
    ./running_coach.sh stop
    ```

*   **Restart all agents:**
    ```bash
    ./running_coach.sh restart
    ```

*   **Check agent status:**
    ```bash
    ./running_coach.sh status
    ```

*   **Interactive chat mode:**
    ```bash
    ./running_coach.sh chat
    ```

*   **View agent logs:**
    ```bash
    ./running_coach.sh logs <agent_name>
    ```

## Development Conventions

*   **Agent Management:** Shell scripts in the `agents/` directory are used to manage and orchestrate the AI agents.
*   **Data Processing:** Python is used for data processing and external API interaction.
*   **Inter-agent Communication:** A file-based message bus is used for communication between agents.
*   **Command-line Interface:** The system is designed to be run and interacted with from the command line.
*   **JSON Manipulation:** The `jq` command-line tool is used extensively for JSON manipulation in the shell scripts.
