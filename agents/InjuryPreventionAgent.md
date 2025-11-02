# Agent Profile: InjuryPreventionAgent

## 1. Name

`InjuryPreventionAgent`

## 2. Purpose

To help the user prevent and manage common running-related injuries by providing information, exercises, and proactive warnings.

## 3. Capabilities

*   **Injury Information:** Provide information about common running injuries (e.g., runner's knee, shin splints, plantar fasciitis), including symptoms and causes.
*   **Rehab and Prehab Routines:** Suggest mobility, stretching, and strengthening exercises to prevent injuries or aid in recovery.
*   **Risk Assessment:** Identify potential injury risks based on:
    *   Sudden increases in training load (from `DataAnalysisAgent`).
    *   User-reported pain or soreness (from `DailyJournal`).
*   **Modification Suggestions:** Recommend modifications to the training plan (e.g., reducing intensity, cross-training) when injury risk is high.

## 4. Inputs

*   **`AnalysisSummary` and `DataAlerts` (from Data Bus):** Data indicating sudden changes in training load, published by `DataAnalysisAgent`.
*   **`DailyJournal` (from Data Bus):** User reports of pain, soreness, or discomfort, published by `UserInteractionAgent`.
*   **`InjuryAssessmentRequests` (from Data Bus):** Specific queries from `InjuryOrchestratorAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** Current training plan data.

## 5. Outputs

*   **`InjuryWarning` (to Data Bus):** An alert published when a high injury risk is detected.
*   **`RehabPlan` (to Data Bus):** A set of recommended exercises and actions, published to the Shared Knowledge Base.
*   **`InformationalContent` (to Data Bus):** Articles or videos about specific injuries, published for `UserInteractionAgent`.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`InjuryOrchestratorAgent`:** (Indirectly, as it receives requests from and publishes results for the sub-orchestrator via the Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, for data-driven risk assessment, interacting via Data Bus).
*   **`TrainingPlannerAgent`:** (Indirectly, to suggest modifications to the training plan, interacting via Data Bus).
*   **`StrengthCoachAgent`:** To request and coordinate rehab exercises.
