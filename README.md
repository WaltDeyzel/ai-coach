# Project: AI Running Coach

## 1. Project Goal

To create a personalized AI-powered running coach that assists users with their training, nutrition, and overall progress. The system will analyze data from various sources to provide holistic and actionable advice.

## 2. Key Features

*   **Personalized Training Plans:** Generate and adapt running plans based on user goals, fitness level, and progress.
*   **Nutrition Guidance:** Provide dietary recommendations based on training load and user-provided food logs.
*   **Strength Training Integration:** Suggest strength workouts that complement the running plan.
*   **Progress Tracking & Analysis:** Ingest and analyze data from Garmin, user logs, and other sources to track progress and identify trends.
*   **Injury Prevention & Management:** Offer advice on preventing and managing common running-related injuries.
*   **Natural Language Interface:** Allow users to interact with the coach through a conversational interface.

## 3. Potential Agents

We can envision a multi-agent system to handle the different aspects of this project. Here is a potential breakdown:

*   **`TrainingPlannerAgent`:** Responsible for creating and adjusting running schedules.
*   **`NutritionistAgent`:** Provides advice on diet and hydration.
*   **`StrengthCoachAgent`:** Recommends strength training exercises.
*   **`DataAnalysisAgent`:** Ingests and analyzes all incoming data (Garmin, user logs).
*   **`UserInteractionAgent`:** Manages the conversational interface with the user.
*   **`InjuryPreventionAgent`:** Provides information and exercises for injury prevention.
*   **`OrchestratorAgent`:** Coordinates the other agents and manages the overall user experience.

## 4. Data Sources & Model

*   **Garmin Data:**
    *   Running activities (distance, pace, heart rate, cadence, etc.).
    *   Sleep data.
    *   Stress levels.
    *   *Action Item:* Research and document the process for Garmin data integration (e.g., via API).
*   **User-Provided Data:**
    *   **`DailyJournal`:** Structured subjective feedback. See `projects/running_coach/data/DailyJournal.json` for schema.
    *   **`FoodLog`:** Structured food intake and related subjective experiences. See `projects/running_coach/data/FoodLog.json` for schema.
    *   **`UserGoals`:** User's running goals. See `projects/running_coach/data/user_goals.json` for schema.
    *   **`UserProfile`:** User's personal details and fitness levels. See `projects/running_coach/data/user_profile.json` for schema.
*   **Cross-Agent Data Models:** All data published to and consumed from the Data Bus will adhere to formalized JSON schemas. These are defined in the `projects/running_coach/data/` directory (e.g., `TrainingPlan.json`, `NutritionalAdvice.json`).

## 5. Data Bus / Shared Knowledge Base Design

To facilitate efficient, decoupled, and scalable data exchange, the project will utilize a **Data Bus / Shared Knowledge Base**. This central hub will allow agents to publish data, subscribe to relevant events, and query for current state information without direct point-to-point dependencies.

### High-Level Design Principles:

Based on best practices for multi-agent systems and event-driven architectures:

*   **Event-Driven Communication:** Agents will primarily communicate by publishing events (e.g., `RunCompletedEvent`, `InjuryReportedEvent`) to the Data Bus and subscribing to events relevant to their responsibilities. This promotes loose coupling and real-time responsiveness.
*   **Centralized, Accessible State (Shared Knowledge Base):** Key project data (e.g., `TrainingPlan`, `User Profile`, `AnalysisSummary`, `HistoricalRunData`) will be stored in and accessible via the Shared Knowledge Base component of the bus. This ensures all agents operate on consistent, up-to-date information.
*   **Decoupling:** Agents will interact with the bus, not directly with each other, significantly reducing inter-agent dependencies and simplifying system evolution.
*   **Scalability & Resilience:** The chosen implementation will support high throughput, easy scaling, and provide mechanisms for fault tolerance and recovery (e.g., immutable event logs).
*   **Asynchronous Processing:** Agents can work in parallel, reacting to events as they occur, improving overall system performance.
*   **Clear Data Contracts:** All data published to and consumed from the bus will adhere to formalized Cross-Agent Data Models (JSON schemas) to ensure consistency and prevent misinterpretation.

### Proposed Implementation (Action Item):

*   *Action Item: Research and select a specific technology for the Data Bus (e.g., Apache Kafka for event streaming, Redis Pub/Sub for real-time events, a dedicated message queue, or a combination). Consider its capabilities for event sourcing, streaming, and knowledge graph integration.*
*   *Action Item: Define the topics/channels for key data types (e.g., `user_events`, `training_updates`, `analysis_results`, `alerts`, `commands`).*
*   *Action Item: Formalize the Cross-Agent Data Models (JSON schemas) for all data published to and consumed from the bus, ensuring clear data contracts.*

## 6. High-Level Orchestration
# ai-coach
