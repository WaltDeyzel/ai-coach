# Agent Profile: OrchestratorAgent

## 1. Name

`OrchestratorAgent`

## 2. Purpose

To act as the central coordinator of the multi-agent system. It receives requests, delegates tasks to the appropriate specialist agents, and ensures a cohesive and intelligent response.

## 3. Capabilities

*   **High-Level Task Delegation:** Receive inputs from the `UserInteractionAgent` and `DataAnalysisAgent` and route them to the appropriate **Sub-Orchestrator** (e.g., `TrainingOrchestratorAgent`, `NutritionOrchestratorAgent`, `InjuryOrchestratorAgent`) or specialist agent if no sub-orchestrator exists for that domain.
*   **Global State Management:** Maintain a high-level understanding of the user's overall state, goals, and recent interactions across all domains.
*   **System-Wide Agent Coordination:** Synthesize information from multiple sub-orchestrators and specialist agents to fulfill complex, cross-domain requests. For example, to generate a daily briefing, it would query the `TrainingOrchestratorAgent` for the day's workout, the `NutritionOrchestratorAgent` for post-workout meal advice, and the `DataAnalysisAgent` for a summary of last night's sleep.
*   **Global Priority Management:** Handle system-wide alerts and warnings (e.g., `InjuryWarning`, `DataAlert`) and determine the appropriate course of action, potentially involving multiple sub-orchestrators.

### Decision/Delegation Criteria

The `OrchestratorAgent` uses the following criteria to decide which sub-orchestrator or specialist agent to delegate tasks to and how to prioritize actions:

1.  **Intent Recognition:** Analyze user requests (from `UserInteractionAgent`) to identify the primary intent (e.g., "get training plan," "ask nutrition question," "report injury").
2.  **Domain Mapping:** Map the identified intent to the appropriate sub-orchestrator (e.g., training intents -> `TrainingOrchestratorAgent`, nutrition intents -> `NutritionOrchestratorAgent`, injury intents -> `InjuryOrchestratorAgent`) or specialist agent if no sub-orchestrator exists for that domain.
3.  **Contextual Relevance:** Consider the current user state, recent activities, and goals to determine the most relevant sub-orchestrator or specialist agent.
4.  **Data Availability:** Check if necessary data is available (e.g., from `DataAnalysisAgent` or Shared Knowledge Base) before delegating a task that requires it.
5.  **Alert Priority:** Prioritize critical alerts (e.g., `InjuryWarning`, `DataAlert` indicating overtraining) over routine requests, routing them to the relevant sub-orchestrator or specialist.
6.  **Sequential Dependencies:** Understand and manage the order of operations when a request requires input from multiple sub-orchestrators or agents in sequence.
7.  **Load Balancing (Future Consideration):** In a high-volume scenario, consider distributing tasks among multiple instances of sub-orchestrators or specialist agents.

## 4. Inputs

*   **`UserRequests` (from Data Bus):** Formatted user requests published by the `UserInteractionAgent`.
*   **`AnalysisSummaries` and `DataAlerts` (from Data Bus):** Proactive triggers published by the `DataAnalysisAgent`.
*   **`SubOrchestratorReports` (from Data Bus):** Summaries and alerts published by sub-orchestrators (e.g., `TrainingOrchestratorAgent`).

## 5. Outputs

*   **`DelegationCommands` (to Data Bus):** Specific commands or queries published to sub-orchestrators or specialist agents.
*   **`SynthesizedResponses` (to Data Bus):** Cohesive answers published for the `UserInteractionAgent` to present to the user.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`UserInteractionAgent`:** (Indirectly, as it publishes user requests to the Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, as it publishes analysis results to the Data Bus).
*   **Sub-Orchestrators (e.g., `TrainingOrchestratorAgent`, `NutritionOrchestratorAgent`, `InjuryOrchestratorAgent`):** (Indirectly, as it delegates to them via the Data Bus and receives reports from them via the Data Bus).
