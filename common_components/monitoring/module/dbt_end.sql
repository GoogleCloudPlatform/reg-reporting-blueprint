-- Copyright 2022 The Reg Reporting Blueprint Authors

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     https://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- DBT logging END stage processing
--
-- Create a materialized view of extracted JSON fields for the END stage of processing

SELECT
  update_time AS end_time,
  dbt_invocation_id,

  -- Specific node for the result from BigQuery
  JSON_EXTRACT_SCALAR(results, "$.id") AS id,

  -- BigQuery specific information
  STRUCT(
    JSON_EXTRACT_SCALAR(results, "$.adapter_response._message") AS message,
    CAST(JSON_EXTRACT_SCALAR(results, "$.adapter_response.bytes_processed") AS INT64) AS bytes_processed,
    JSON_EXTRACT_SCALAR(results, "$.adapter_response.code") AS code,
    JSON_EXTRACT_SCALAR(results, "$.adapter_response.job_id") AS job_id,
    JSON_EXTRACT_SCALAR(results, "$.adapter_response.location") AS location,
    JSON_EXTRACT_SCALAR(results, "$.adapter_response.project_id") AS project_id,
    CAST(JSON_EXTRACT_SCALAR(results, "$.adapter_response.rows_affected") AS INT64) AS rows_affected,
    CAST(JSON_EXTRACT_SCALAR(results, "$.adapter_response.slot_ms") AS FLOAT64) AS slot_ms
  ) AS response_bigquery,

  -- DBT timings information
  JSON_EXTRACT_ARRAY(results, "$.timing") json_timings
 
FROM
  `${monitoring_dataset}.dbt_log` l
  CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(l.info)) AS results
WHERE
  stage='END' AND
  JSON_EXTRACT_SCALAR(results, "$.id") NOT LIKE '%test%'
