-- Copyright 2022 Google LLC

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     https://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


-- Macro for table comparison
--
-- This macro allows a full table comparison (all rows and all columns) across two tables.
-- It can be used to implement a regression test routing for actual vs expected results.


{% macro table_comparison(actual_results_model, expected_results_dataset, expected_results_table)%}
SELECT 1, x.*

FROM
(
    SELECT
      *
    FROM {{ ref(actual_results_model) }}

    EXCEPT DISTINCT

    SELECT
      *
    FROM {{ source(expected_results_dataset, expected_results_table) }}
) x
UNION ALL

SELECT 2, x.*

FROM
(
    SELECT
      *
    FROM {{ source(expected_results_dataset, expected_results_table) }}

    EXCEPT DISTINCT

    SELECT
      *
    FROM {{ ref(actual_results_model) }}
) x
ORDER BY 1
{% endmacro %}



