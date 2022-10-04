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


-- Join submissions with ratings to create a complete denormalised data setup.
--
-- This will contain all data with some extra-value-add.

WITH
  WithRatings AS (
    SELECT
      s.*,

      -- Find all the current ratings (if any) as of
      -- time of submission
      ARRAY(
        SELECT AS STRUCT
          c.name,
          c.cik,
          *
        FROM
          c.ratings d
        WHERE
          period >= d.rating_action_date AND
          period <  d.rating_action_end_date
        ORDER BY
          rating_action_date
      ) AS rating,

      -- Find whether any rating of default
      -- happen in the next year
      (
        SELECT AS STRUCT
          rating_action_date,
          rating
        FROM
          c.ratings d
        WHERE
          period >= DATETIME_SUB(d.rating_action_date, INTERVAL 1 YEAR) AND
          period <  d.rating_action_end_date AND
          is_default
        LIMIT 1
      ) AS future_default

    FROM
      {{ ref('submissions_sub') }} s
      LEFT JOIN {{ ref('defaults') }} c ON (
        s.name=c.name AND s.cik=c.cik
      )
  )
SELECT
  *,
  ARRAY_LENGTH(w.rating)>0 AS has_rating,
  (w.future_default.rating IS NOT NULL) AS will_default
FROM
  WithRatings w
