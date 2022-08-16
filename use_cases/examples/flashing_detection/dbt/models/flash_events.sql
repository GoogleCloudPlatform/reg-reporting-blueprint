SELECT
    sent.*,
    TIMESTAMP_DIFF(canceled.timestamp, sent.timestamp, MILLISECOND) AS flash_order_life_span
  FROM
    {{ source('flashing_detection_source_order_data', 'orders') }} as sent,
    {{ source('flashing_detection_source_order_data', 'orders') }} as canceled
  WHERE
    1 = 1
    AND sent.trade_date = canceled.trade_date
    AND sent.tif != 'IOC'
    AND sent.event = 'Sent'
    AND canceled.event = 'CancelSent'
    AND sent.order_id = canceled.order_id
    AND TIMESTAMP_DIFF(canceled.timestamp, sent.timestamp, MILLISECOND) <= 500
  ORDER BY
    sent.timestamp