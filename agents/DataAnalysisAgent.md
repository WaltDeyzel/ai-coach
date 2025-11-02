# Agent Profile: DataAnalysisAgent

## 1. Name

`DataAnalysisAgent`

## 2. Purpose

To ingest, process, and analyze all quantitative and qualitative data to identify trends, measure progress, and provide actionable insights to other agents and the user.

## 3. Capabilities

*   **Data Ingestion:** Connect to data sources (e.g., Garmin API, user logs) and ingest new data as it becomes available.
*   **Data Cleaning and Processing:** Clean and structure incoming data into a consistent format.
*   **Trend Analysis:** Identify short-term and long-term trends in performance metrics (e.g., pace, heart rate, cadence), training load, and subjective feedback.
*   **Performance Correlation:** Correlate different data streams to find insights (e.g., "pace is 5% slower on days after reported poor sleep").
*   **Progress Monitoring:** Track progress towards user goals and identify periods of fitness stagnation or improvement.
*   **Anomaly Detection:** Flag anomalies in the data that might indicate overtraining, injury risk, or other issues.

## 4. Inputs

*   **`RawGarminData` (from Data Bus):** Raw data from the Garmin API, published by a dedicated ingestion service.
*   **`UserLogs` (from Data Bus):** `DailyJournal` and `FoodLog` data, published by `UserInteractionAgent`.
*   **`TrainingPlan` (from Shared Knowledge Base):** To compare planned vs. actual workouts.

## 5. Outputs

*   **`AnalysisSummary` (to Data Bus):** A summary of key findings and trends, published for relevant agents (e.g., `OrchestratorAgent`, sub-orchestrators).
*   **`DataAlert` (to Data Bus):** A specific alert triggered by an anomaly, published for relevant agents.
*   **`ProcessedData` (to Shared Knowledge Base):** Cleaned and structured data (e.g., processed Garmin activities, correlated metrics) stored for other agents to query.

## 6. Dependencies

*   **Data Bus / Shared Knowledge Base:** For all data ingestion, output publishing, and querying of shared state.
