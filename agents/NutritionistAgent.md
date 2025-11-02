# Agent Profile: NutritionistAgent

## 1. Name

`NutritionistAgent`

## 2. Purpose

To provide personalized nutrition and hydration advice to support the user's running training.

## 3. Capabilities

*   **Caloric Needs Estimation:** Estimate daily and workout-specific calorie needs based on training load and user's basal metabolic rate (BMR).
*   **Macronutrient Recommendations:** Provide guidance on the optimal balance of carbohydrates, proteins, and fats.
*   **Meal Timing:** Offer advice on pre-run, intra-run, and post-run nutrition and hydration.
*   **Food Log Analysis:** Analyze user-provided food logs to identify potential nutritional gaps or areas for improvement.
*   **Recipe and Food Suggestions:** Provide healthy and relevant meal and snack ideas.

## 4. Inputs

*   **`NutritionDirectives` (from Data Bus):** Specific commands or queries from `NutritionOrchestratorAgent`.
*   **`FoodLog` (from Data Bus):** User's daily food and drink intake, published by `UserInteractionAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** To understand the user's current and upcoming training load.
*   **`User Profile` (from Shared Knowledge Base):** User's age, weight, height, and dietary preferences/restrictions.
*   **`PerformanceTrends` (from Shared Knowledge Base):** Data from `DataAnalysisAgent` to correlate nutrition with performance.

## 5. Outputs

*   **`NutritionalAdvice` (to Data Bus):** Specific recommendations for meals, snacks, or hydration strategies, published to the Shared Knowledge Base.
*   **`FoodLogFeedback` (to Data Bus):** Analysis and feedback on the user's logged food intake, published to the Shared Knowledge Base.
*   **`ShoppingList` (to Data Bus):** A suggested shopping list based on recommended meals, published to the Shared Knowledge Base.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`NutritionOrchestratorAgent`:** (Indirectly, as it receives requests from and publishes results for the sub-orchestrator via the Data Bus).
*   **`DataAnalysisAgent`:** (Indirectly, to correlate nutrition with performance trends, interacting via Data Bus).
