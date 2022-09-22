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
      take_events.take_exec_id,
      MAX(bid) AS max_bid,
      MIN(ask) AS min_ask
    FROM
      {{ ref('take_events') }},
      {{ source('flashing_detection_source_market_data', 'nbbo') }}
    JOIN {{ ref('latest_nbbo') }} ON
      take_events.trade_date = latest_nbbo.trade_date
      AND take_events.symbol = latest_nbbo.symbol
      AND take_events.take_exec_id = latest_nbbo.take_exec_id
    WHERE
      -- NBBO within 1sec prior to take event
      -- (or last NBBO prior to the window if no NBBO published within the window)
      (
           nbbo.timestamp > DATETIME_SUB(take_timestamp, INTERVAL 1000 MILLISECOND)
        OR nbbo.timestamp >= latest_nbbo.nbbo_time
      )
      AND nbbo.timestamp < take_events.take_timestamp
    GROUP BY
      trade_date, symbol, take_exec_id