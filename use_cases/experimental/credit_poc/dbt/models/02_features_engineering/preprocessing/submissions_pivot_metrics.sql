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


-- As BigQuery has a limit of 10,000 columns, this will focus on the
-- the most interesting metrics according to iv_value and metric_coverage.

{{ config(materialized='ephemeral') }}


SELECT
  * EXCEPT (values),
  (
    SELECT AS STRUCT
      {{ dbt_ml_helpers.pivot_and_aggregate(
           column='key',
           values=dbt_ml_helpers.get_top_metrics(
             from_clause=
               ref('iv') ~
               " WHERE metric_coverage > 0.04 AND" ~
               " iv_value < 0.6 AND iv_value > 0.10",
             metric_column_id='metric',
           ),
           then_value='value',
           else_value=0)
      }}
    FROM
      s.values
  ) AS metrics
FROM
  {{ ref('submissions_preprocessed') }} s
