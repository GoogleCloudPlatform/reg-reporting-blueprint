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


-- Latest run on reporting day
--
-- This calculates the latest run on a given reporting day.
-- This is required to select the latest snapshot from the warehouse history table.

SELECT
  control.reporting_day,
  MAX(control.run_started_at) AS latest_run_started_at
FROM
  {{ref('wh_denormalised_history')}}
GROUP BY
  1
