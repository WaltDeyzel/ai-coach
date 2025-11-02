# Agent Profile: StrengthCoachAgent

## 1. Name

`StrengthCoachAgent`

## 2. Purpose

To recommend strength training workouts that complement the user's running plan, with a focus on improving running economy, preventing injuries, and building overall strength.

## 3. Capabilities

*   **Workout Generation:** Create personalized strength training routines based on the user's fitness level, available equipment, and the phase of their running plan.
*   **Exercise Library:** Maintain a library of exercises with instructions, images, or videos.
*   **Workout Scheduling:** Suggest optimal days and times for strength training to avoid conflicts with key running workouts.
*   **Form and Technique Guidance:** Provide tips on proper form for recommended exercises.

## 4. Inputs

*   **`StrengthDirectives` (from Data Bus):** Specific commands or queries from `TrainingOrchestratorAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** To understand the user's running schedule and intensity.
*   **`User Profile` (from Shared Knowledge Base):** User's experience with strength training, available equipment.
*   **`InjuryReports` (from Shared Knowledge Base):** To modify routines to avoid aggravating existing injuries.

## 5. Outputs

*   **`StrengthWorkout` (to Data Bus):** A structured data object containing a list of exercises, sets, reps, and rest periods, published to the Shared Knowledge Base.
*   **`ExerciseDemonstration` (to Data Bus):** Links or embedded content showing how to perform an exercise, published to the Shared Knowledge Base.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all communication and state management.
*   **`TrainingOrchestratorAgent`:** (Indirectly, as it receives requests from and publishes results for the sub-orchestrator via the Data Bus).
*   **`InjuryPreventionAgent`:** (Indirectly, to get information about the user's injuries, interacting via Data Bus).
