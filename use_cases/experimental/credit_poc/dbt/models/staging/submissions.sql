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

{{
  config(
    materialized='table',
  )
}}

-- Create a denomoralised submissions table with all required data

WITH
  -- Aggregate pre into an array per submission
  PreAgg AS (
    SELECT
      adsh,
      ARRAY_AGG(p) AS pre
    FROM
      {{ ref('submissions_pre') }} p
    GROUP BY
       1
  ),
  -- Aggregate num into an array per submission
  PreNum AS (
    SELECT
      adsh,
      ARRAY_AGG(n) AS num
    FROM
      {{ ref('submissions_num') }} n
    GROUP BY
       1
  )
SELECT
  s.*,
  p.pre AS pre,
  n.num AS num
FROM
  {{ ref('submissions_defaults') }} s
  LEFT JOIN PreAgg p USING (adsh)
  LEFT JOIN PreNum n USING (adsh)
