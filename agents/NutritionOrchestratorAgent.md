# Agent Profile: NutritionOrchestratorAgent

## 1. Name

`NutritionOrchestratorAgent`

## 2. Purpose

To act as a specialized sub-orchestrator responsible for coordinating all nutrition and hydration-related activities within the AI Running Coach project. It manages dietary recommendations, food log analysis, and hydration strategies for the user.

## 3. Capabilities

*   **Nutrition Advice Management:** Delegates to `NutritionistAgent` for generating dietary recommendations and analyzing food logs.
*   **Hydration Strategy:** Coordinates with `NutritionistAgent` to provide hydration advice based on training and environmental factors.
*   **Food Log Processing:** Receives and processes user-provided `FoodLog` data, passing it to `NutritionistAgent` for analysis and storing relevant information in the Shared Knowledge Base.
*   **Reporting to Main Orchestrator:** Provides summarized nutrition status and alerts (e.g., significant dietary imbalances) back to the main `OrchestratorAgent`.

## 4. Inputs

*   **`High-Level Nutrition Directives` (from Data Bus):** Commands from the main `OrchestratorAgent`.
*   **`FoodLog` (from Data Bus):** User's daily food and drink intake, published by `UserInteractionAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** To understand the user's current and upcoming training load.
*   **`User Profile` (from Shared Knowledge Base):** User's dietary preferences/restrictions.

## 5. Outputs

*   **`DelegationCommands` (to Data Bus):** Specific commands or queries published for the `NutritionistAgent`.
*   **`NutritionalStatusReport` (to Data Bus):** Summaries of dietary adherence, recommendations provided, or critical alerts, published for the main `OrchestratorAgent`.
*   **`NutritionalAdvice` (to Data Bus):** The generated dietary recommendations, published to the Shared Knowledge Base.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`OrchestratorAgent`:** (Indirectly, receives directives from and reports to the main orchestrator via the Data Bus).
*   **`NutritionistAgent`:** (Indirectly, for core nutrition advice logic, interacting via Data Bus).
