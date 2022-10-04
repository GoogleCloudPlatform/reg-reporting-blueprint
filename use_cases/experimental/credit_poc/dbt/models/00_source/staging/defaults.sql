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


--
-- Prepare ratings to be joined with submissions data
--

WITH
  -- Aggregate the ratings and prepare for joining
  --
  -- One row per rated entity with a sub-array of ratings
  -- of form (rating_action_date, rating).
  RatingsAggregated AS (
    SELECT
      CAST(central_index_key AS INT64) AS cik,
      REGEXP_REPLACE(UPPER(obligor_name), '[\\.,]', '') as name,
      ARRAY_AGG(
        STRUCT(
          DATETIME(rating_action_date) AS rating_action_date,
          rating_type,
          rating_sub_type,
          instrument_name,
          rating
        )
      ) AS ratings
    FROM
      {{ ref('ratings') }}
    WHERE
      obligor_name IS NOT NULL OR
      central_index_key IS NOT NULL
    GROUP BY
      1,2
  ),

  -- Re-format ratings to include is_default and rating_action_end_date
  RatingsAnalysis AS (
    SELECT
      * EXCEPT (ratings),
      ARRAY(
        SELECT AS STRUCT
          *,
          LEAD(rating_action_date) OVER (ORDER BY rating_action_date) AS rating_action_end_date,
          rating IN ('D', 'NR') AS is_default
        FROM
          r.ratings
      ) AS ratings
    FROM
      RatingsAggregated r
  ),

  -- Unique submissions
  UniqueSubmissions AS (
    SELECT DISTINCT
      cik,
      name
    FROM
      {{ ref('submissions_sub') }}
  )

-- Re-aggregated by joined submissions
SELECT
  s.name,
  s.cik,
  ARRAY_CONCAT_AGG(ratings) AS ratings
FROM
  UniqueSubmissions s
  LEFT JOIN RatingsAnalysis c ON (
    REGEXP_REPLACE(s.name, '[\\.,]| */[^/]*/ *| *\\[^\\]\\ *', '')=c.name OR
    s.cik=c.cik
  )
GROUP BY
  1, 2

