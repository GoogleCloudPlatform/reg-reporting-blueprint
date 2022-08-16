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
