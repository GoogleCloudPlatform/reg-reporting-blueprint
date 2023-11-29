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


-- DBT Dashboard
--
-- Create a view with useful metrics for an operational view of the DBT executions
-- in Airflow.

SELECT
  * EXCEPT (json_timings),

  -- Timing information (for job)
  (
    SELECT AS STRUCT
      MIN(PARSE_DATETIME("%Y-%m-%dT%H:%M:%E*S", JSON_EXTRACT_SCALAR(t, "$.completed_at"))) AS completed_at,
      MIN(PARSE_DATETIME("%Y-%m-%dT%H:%M:%E*S", JSON_EXTRACT_SCALAR(t, "$.started_at"))) AS started_at
    FROM
      UNNEST(json_timings) t
    WHERE
      JSON_EXTRACT_SCALAR(t, "$.name")="compile"
  ) AS compile_timing,
  (
    SELECT AS STRUCT
      MIN(PARSE_DATETIME("%Y-%m-%dT%H:%M:%E*S", JSON_EXTRACT_SCALAR(t, "$.completed_at"))) AS completed_at,
      MIN(PARSE_DATETIME("%Y-%m-%dT%H:%M:%E*S", JSON_EXTRACT_SCALAR(t, "$.started_at"))) AS started_at
    FROM
      UNNEST(json_timings) t
    WHERE
      JSON_EXTRACT_SCALAR(t, "$.name")="compile"
  ) AS execute_timing,

  -- NOTE: This only works if source_ref is a valid identifier, which normally
  -- requires a CI/CD triggered build from source.
  --
  -- Source
  CONCAT('${src_url}/',
    build_info.source_ref, '/', build_info.source_path)
    AS github_link,

  -- Building
  CONCAT('https://console.cloud.google.com/cloud-build/builds;region=global/',
    build_info.build_ref, '?project=${project_id}')
    AS build_link,

  -- Docs
  CONCAT("https://storage.cloud.google.com/${docs_bucket}/build/",
    build_info.build_ref, '/static_index.html')
    AS doc_link,

  -- Airflow
  CONCAT('${airflow_url}/graph?dag_id=',
    airflow_info.airflow_dag_id, '&execution_date=', airflow_info.airflow_execution_date)
    AS airflow_dag_link,
  CONCAT('${airflow_url}/log?dag_id=',
    airflow_info.airflow_dag_id, '&task_id=', airflow_info.airflow_task_id,
    '&execution_date=', airflow_info.airflow_execution_date)
    AS airflow_task_link,
  CONCAT('${airflow_url}/task?dag_id=',
    airflow_info.airflow_dag_id, '&task_id=', airflow_info.airflow_task_id,
    '&execution_date=', airflow_info.airflow_execution_date)
    AS airflow_task_info_link,

  -- Job information
  CONCAT('https://console.cloud.google.com/bigquery?project=', response_bigquery.project_id,
         '&j=bq:', response_bigquery.location, ':', response_bigquery.job_id, '&page=queryresults') AS job_link

FROM
  `${monitoring_dataset}.dbt_start`
  JOIN `${monitoring_dataset}.dbt_end` USING (dbt_invocation_id)
WHERE
  response_bigquery.job_id IS NOT NULL AND
  airflow_info.airflow_dag_id IS NOT NULL
ORDER BY
  start_time DESC
