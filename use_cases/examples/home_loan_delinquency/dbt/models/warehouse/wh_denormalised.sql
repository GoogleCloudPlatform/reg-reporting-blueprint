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


-- Denormalised table with all accounts data (latest run)
--
-- This model selects only the latest run for each reporting day, as queried from the history table.
-- To inspect the definition of the fields, generate the DBT documentation

{{ config(materialized='view') }}

SELECT
    wh.*
FROM
    {{ref('wh_denormalised_history')}}               wh      JOIN
    {{ref('eph_latest_run_on_reporting_day')}}       lr         ON
    wh.control.reporting_day  = lr.reporting_day                AND
    wh.control.run_started_at = lr.latest_run_started_at
