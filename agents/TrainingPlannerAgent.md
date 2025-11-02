# Agent Profile: TrainingPlannerAgent

## 1. Name

`TrainingPlannerAgent`

## 2. Purpose

To create, manage, and dynamically adapt personalized running training plans based on the user's goals, performance data, and subjective feedback.

## 3. Capabilities

*   **Plan Generation:** Generate a multi-week training plan based on a target race distance (e.g., 5k, 10k, half-marathon, marathon) and a target completion time or goal (e.g., "finish the race," "run under 2 hours").
*   **Plan Adaptation:** Modify the training plan based on:
    *   Missed or modified workouts.
    *   User's subjective feedback (e.g., feeling fatigued, high energy).
    *   Performance trends identified by the `DataAnalysisAgent`.
*   **Workout Specification:** Define the specifics for each workout, including:
    *   Type (e.g., easy run, long run, interval training, tempo run).
    *   Duration or distance.
    *   Pace targets (e.g., heart rate zone, pace range).
*   **Taper and Recovery:** Incorporate taper periods before races and recovery weeks into the training plan.

## 4. Inputs

*   **`TrainingDirectives` (from Data Bus):** Specific commands or queries from `TrainingOrchestratorAgent`.
*   **`UserGoals` (from Shared Knowledge Base):** Target race distance, goal time, race date.
*   **`UserFitnessLevel` (from Shared Knowledge Base):** Current weekly mileage, recent race times, self-assessed fitness level.
*   **`AnalysisSummary` (from Data Bus):** Summaries of recent performance, fatigue warnings, progress trends, published by `DataAnalysisAgent`.
*   **`UserFeedback` (from Data Bus):** User's subjective feelings, reports of missed workouts, published by `UserInteractionAgent`.

## 5. Outputs

*   **`TrainingPlan` (to Data Bus):** A structured data object representing the full training plan, published to the Shared Knowledge Base.
*   **`WorkoutModification` (to Data Bus):** A notification and updated workout details, published to the Data Bus.
*   **`QueriesToDataAnalysis` (to Data Bus):** Requests for specific data points or analysis from `DataAnalysisAgent`.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`TrainingOrchestratorAgent`:** (Indirectly, as it receives requests from and publishes results for the sub-orchestrator via the Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, to receive performance data and analysis, interacting via Data Bus).
*   **`UserInteractionAgent`:** (Indirectly, to receive user feedback and goals, interacting via Data Bus).
