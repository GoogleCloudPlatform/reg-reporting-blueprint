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

SELECT
    take_events.trade_date,
    take_events.symbol,
    take_exec_id,
    MAX(nbbo.timestamp) AS nbbo_time
  FROM
    {{ ref('take_events') }},
    {{ source('flashing_detection_source_market_data', 'nbbo') }} as nbbo
  WHERE
    nbbo.timestamp < take_timestamp
  GROUP BY
    take_events.trade_date,
    take_events.symbol,
    take_exec_id,
    take_timestamp