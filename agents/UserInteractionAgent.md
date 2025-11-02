# Agent Profile: UserInteractionAgent

## 1. Name

`UserInteractionAgent`

## 2. Purpose

To serve as the primary interface between the user and the AI coaching system, managing the conversational flow and translating user requests into actionable tasks for other agents.

## 3. Capabilities

*   **Natural Language Understanding (NLU):** Interpret user messages, questions, and commands.
*   **Dialog Management:** Maintain the context of the conversation and manage the back-and-forth interaction.
*   **Information Presentation:** Present information from other agents to the user in a clear and understandable way.
*   **Data Collection:** Prompt the user for subjective feedback (e.g., `DailyJournal` entries) and log their responses.
*   **Request Routing:** Route user requests to the appropriate agent via the `OrchestratorAgent`.

## 4. Inputs

*   **`UserMessages` (from User Interface):** Text or voice input from the user.
*   **`InformationToPresent` (from Data Bus):** Outputs from other agents (e.g., `TrainingPlan`, `NutritionalAdvice`, `RehabPlan`) published for user consumption.

## 5. Outputs

*   **`FormattedUserRequests` (to Data Bus):** Structured requests published for the `OrchestratorAgent`.
*   **`UserFacingMessages` (to User Interface):** Text, charts, and other UI elements to display to the user.
*   **`DailyJournalEntries` and `FoodLogEntries` (to Data Bus):** User-provided data published for `DataAnalysisAgent` and relevant orchestrators.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For publishing user requests and consuming information to present.
*   **User Interface:** The external system through which the user interacts.
*   **`OrchestratorAgent`:** (Indirectly, as it consumes formatted user requests from the Data Bus and publishes synthesized responses to the Data Bus).
