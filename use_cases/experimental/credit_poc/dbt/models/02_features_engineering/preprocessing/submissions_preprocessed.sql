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

-- Only process submissions with
-- - 10-Q is quarterly and 10-K is annual financial reports
-- - a rating
-- - numeric values for the current period
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
  {{ ref('submissions_split') }} s
WHERE
  form IN ('10-K', '10-Q') AND
  has_rating
