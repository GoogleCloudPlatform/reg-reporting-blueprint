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
    flash.trade_date,
    flash.symbol,
    flash.order_id AS flash_order_id,
    flash.timestamp AS flash_timestamp,
    flash.side AS flash_side,
    flash.size AS flash_size,
    flash.price AS flash_price,
    flash_order_life_span,
    filled.order_id as take_order_id,
    filled.timestamp AS take_timestamp,
    filled.exec_id AS take_exec_id,
    filled.fill_size AS take_size,
    filled.fill_price AS take_price,
    TIMESTAMP_DIFF(filled.timestamp, flash.timestamp, MILLISECOND) AS sent_to_fill_timespan,
  FROM
    {{ ref('flash_events') }} as flash,
    {{ source('flashing_detection_source_order_data','orders') }} as filled
  WHERE
    1 = 1
    AND flash.trade_date = filled.trade_date
    AND flash.symbol = filled.symbol
    -- Got filled on oposite side of flashed order
    AND filled.event = 'Filled'
    AND filled.side != flash.side
    -- At a favorable price
    AND IF
    (flash.side = 'Buy',
      filled.fill_price > flash.price,
      filled.fill_price < flash.price)
    -- Within 10sec of flashed order
    AND TIMESTAMP_DIFF(filled.timestamp, flash.timestamp, MILLISECOND) BETWEEN 1 AND 10*1000
  ORDER BY
    filled.timestamp