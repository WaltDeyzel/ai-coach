# Agent Profile: TrainingOrchestratorAgent

## 1. Name

`TrainingOrchestratorAgent`

## 2. Purpose

To act as a specialized sub-orchestrator responsible for coordinating all training-related activities within the AI Running Coach project. It manages the lifecycle of training plans, strength workouts, and injury prevention strategies for the user.

## 3. Capabilities

*   **Training Plan Management:** Delegates to `TrainingPlannerAgent` for plan generation and adaptation.
*   **Strength Workout Integration:** Coordinates with `StrengthCoachAgent` to schedule and provide strength training routines.
*   **Injury Prevention Oversight:** Works with `InjuryPreventionAgent` to integrate injury risk assessments and preventative measures into the training schedule.
*   **Progress Monitoring (Training Focus):** Receives training-specific insights from `DataAnalysisAgent` and uses them to inform training adjustments.
*   **Reporting to Main Orchestrator:** Provides summarized training status and alerts back to the main `OrchestratorAgent`.

## 4. Inputs

*   **`High-Level Training Directives` (from Data Bus):** Commands from the main `OrchestratorAgent`.
*   **`AnalysisSummary` and `DataAlerts` (training-specific, from Data Bus):** Performance data relevant to training, published by `DataAnalysisAgent`.
*   **`UserFeedback` (training-specific, from Data Bus):** Reports on workouts, fatigue, etc., published by `UserInteractionAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** Current training plan data.
*   **`User Profile` (from Shared Knowledge Base):** User's fitness level, goals, etc.

## 5. Outputs

*   **`DelegationCommands` (to Data Bus):** Specific commands or queries published for specialist training agents (e.g., `TrainingPlannerAgent`, `StrengthCoachAgent`, `InjuryPreventionAgent`).
*   **`TrainingStatusReport` (to Data Bus):** Summaries of training progress, plan changes, or critical alerts, published for the main `OrchestratorAgent`.
*   **`TrainingPlan` (to Data Bus):** The generated or adapted training plan, published to the Shared Knowledge Base.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`OrchestratorAgent`:** (Indirectly, as it sends directives to and receives reports from the main orchestrator via the Data Bus).
*   **`TrainingPlannerAgent`:** (Indirectly, for core training plan logic, interacting via Data Bus).
*   **`StrengthCoachAgent`:** (Indirectly, for strength training integration, interacting via Data Bus).
*   **`InjuryPreventionAgent`:** (Indirectly, for injury-related assessments and recommendations, interacting via Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, for training-relevant data insights, interacting via Data Bus).
