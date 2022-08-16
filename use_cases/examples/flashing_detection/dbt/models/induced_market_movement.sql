SELECT
    take.*,
    nbbo.max_bid,
    nbbo.min_ask
  FROM 
    {{ ref('take_events') }} AS take
    JOIN {{ ref('nbbo_around_fill') }} AS nbbo ON
        take.trade_date = nbbo.trade_date
        AND take.symbol = nbbo.symbol
        AND take.take_exec_id = nbbo.take_exec_id
  WHERE
    IF(take.flash_side = "Buy",
       nbbo.max_bid > take.flash_price AND nbbo.max_bid < take.take_price,
       nbbo.min_ask < take.flash_price AND nbbo.min_ask > take.take_price)