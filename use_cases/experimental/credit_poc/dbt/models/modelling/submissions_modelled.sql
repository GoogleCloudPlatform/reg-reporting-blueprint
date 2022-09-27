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


-- Derived values being added to submissions

WITH
  -- Only process submissions with
  -- - 10-Q is quarterly and 10-K is annual financial reports
  -- - a rating
  -- - numeric values for the current period
  Submissions AS (
    SELECT
      * EXCEPT (pre, num),

      -- Extract current values only (for this period)
      ARRAY(
        SELECT AS STRUCT
          key,
          value
        FROM
          s.num
        WHERE
          ddate=period
      ) AS values
    FROM
      {{ ref('submissions') }} s
    WHERE
      form IN ('10-K', '10-Q') AND
      has_rating
  ),

  -- Add in derived values
  AddValues AS (
    SELECT
      *,
      [
        -- Some ratios
        {{ divide_value('s.values', 'AssetsOverLiabilitiesCurrent_0_USD',
                                    'AssetsCurrent_0_USD_', 'LiabilitiesCurrent_0_USD_') }},
        {{ divide_value('s.values', 'AssetsOverLiabilitiesAndStockholdersEquity_0_USD',
                                    'Assets_0_USD_', 'LiabilitiesAndStockholdersEquity_0_USD_') }},
        {{ divide_value('s.values', 'StockholdersEquityOverLiabilitiesAndStockholdersEquity_0_USD',
                                    'Assets_0_USD_', 'LiabilitiesAndStockholdersEquity_0_USD_') }},
        {{ divide_value('s.values', 'AssetsCurrentOverAssets_0_USD',
                                    'AssetsCurrent_0_USD_', 'Assets_0_USD_') }},

        -- Some logarithms
        {{ log_value('s.values', 'LogAssets_0_USD', 'Assets_0_USD_') }},
        {{ log_value('s.values', 'LogAssetsCurrent_0_USD', 'AssetsCurrent_0_USD_') }}

      ] AS derived_values
    FROM
      Submissions s
  )

-- Combine derived values and values
-- (skip derived values that are NULL)
SELECT
  * EXCEPT (values, derived_values),
  ARRAY_CONCAT(
    values,
    ARRAY(
      SELECT AS STRUCT
        key,
        value
      FROM
        s.derived_values
      WHERE
        value IS NOT NULL
    )
  ) AS values
FROM
  AddValues s
