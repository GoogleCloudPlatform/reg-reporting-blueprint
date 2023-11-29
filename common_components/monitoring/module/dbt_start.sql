-- Copyright 2023 The Reg Reporting Blueprint Authors

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     https://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- DBT Log START stage processing
--
-- Create a materialized view of JSON extracted fields for the START stage of
-- processing.

SELECT
  update_time AS start_time,
  dbt_invocation_id,

  -- DBT project
  JSON_EXTRACT_SCALAR(info, "$.project") AS project,

  -- Profile information (how to execute on BigQuery)
  STRUCT(
    JSON_EXTRACT_SCALAR(info, "$.target.database") AS data_project_id,
    JSON_EXTRACT_SCALAR(info, "$.target.dataset") AS data_dataset,
    JSON_EXTRACT_SCALAR(info, "$.target.execution_project") AS execution_project_id,
    JSON_EXTRACT_SCALAR(info, "$.target.location") AS data_location,
    JSON_EXTRACT_SCALAR(info, "$.target.project") AS project_id
  ) AS target_bigquery,

  -- Source and build information
  STRUCT(
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.source_path"), "unset") AS source_path,
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.source_ref"), "unset") AS source_ref,
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.build_ref"), "unset") AS build_ref
  ) AS build_info,

  -- Airflow execution information
  STRUCT(
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.airflow_task_id"), "unset") AS airflow_task_id,
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.airflow_dag_id"), "unset") AS airflow_dag_id,
    NULLIF(JSON_EXTRACT_SCALAR(info, "$.vars.airflow_execution_date"), "unset") AS airflow_execution_date
  ) AS airflow_info

FROM
  `${monitoring_dataset}.dbt_log`
WHERE
  stage='START'
