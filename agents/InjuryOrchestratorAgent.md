# Agent Profile: InjuryOrchestratorAgent

## 1. Name

`InjuryOrchestratorAgent`

## 2. Purpose

To act as a specialized sub-orchestrator responsible for coordinating all injury prevention and management activities within the AI Running Coach project. It manages injury risk assessment, provides preventative and rehabilitative routines, and integrates with the training schedule.

## 3. Capabilities

*   **Injury Risk Assessment:** Delegates to `InjuryPreventionAgent` to assess injury risks based on data and user reports.
*   **Routine Provision:** Coordinates with `InjuryPreventionAgent` to provide prehab and rehab routines.
*   **Training Plan Modification:** Works with `TrainingOrchestratorAgent` (via main `OrchestratorAgent`) to suggest modifications to the training plan when injury risk is high or an injury is present.
*   **User Reporting:** Processes user reports of pain or discomfort, passing them to `InjuryPreventionAgent` for analysis.
*   **Reporting to Main Orchestrator:** Provides summarized injury status and critical warnings back to the main `OrchestratorAgent`.

## 4. Inputs

*   **`High-Level Injury Directives` (from Data Bus):** Commands from the main `OrchestratorAgent`.
*   **`DailyJournal` (injury-related, from Data Bus):** User reports of pain, soreness, or discomfort, published by `UserInteractionAgent`.
*   **`AnalysisSummary` and `DataAlerts` (injury-related, from Data Bus):** Data indicating potential injury risks, published by `DataAnalysisAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** Current training plan data.

## 5. Outputs

*   **`DelegationCommands` (to Data Bus):** Specific commands or queries published for the `InjuryPreventionAgent`.
*   **`InjuryStatusReport` (to Data Bus):** Summaries of injury risk, recommendations provided, or critical warnings, published for the main `OrchestratorAgent`.
*   **`RehabPlan` (to Data Bus):** The generated rehabilitative or preventative routines, published to the Shared Knowledge Base.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`OrchestratorAgent`:** (Indirectly, receives directives from and reports to the main orchestrator via the Data Bus).
*   **`InjuryPreventionAgent`:** (Indirectly, for core injury prevention and management logic, interacting via Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, for injury-relevant data insights, interacting via Data Bus).
