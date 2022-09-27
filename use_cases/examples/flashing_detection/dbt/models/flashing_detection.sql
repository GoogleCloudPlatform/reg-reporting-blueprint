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

WITH
  -- Flash event: Send a short lived order
  flash_events AS (
  SELECT * FROM {{ ref('flash_events') }}
  ),

  -- Take event: Get filled a short time after flashing on the other side of the market
  take_events AS (
  SELECT * FROM {{ ref('take_events') }}
  ),

  -- Helper table to get latest NBBO time prior to a take event
  -- If no NBBO updates happended within the 1sec window prior to a take event,
  -- this will allow us to carry over the last NBBO value.
  latest_nbbo AS (
  SELECT * FROM {{ ref('latest_nbbo') }}
  ),

  -- Min/Max NBBO within a 1sec window prior to a fills
  nbbo_arround_fill AS (
  SELECT * FROM {{ ref('nbbo_around_fill') }}
  ),

  -- The market moved in a favorable direction after flashing
  induced_market_movement AS (
  SELECT * FROM {{ ref('induced_market_movement') }}
  )

-- Identified Flashing exceptions
SELECT
  trade_date, symbol,
  flash_timestamp, flash_order_id, flash_side, flash_size, flash_price, flash_order_life_span,
  take_timestamp, take_order_id, take_size, take_price, sent_to_fill_timespan,
  IF(flash_side = "Buy", max_bid, min_ask) as nbbo_price
FROM
  induced_market_movement
