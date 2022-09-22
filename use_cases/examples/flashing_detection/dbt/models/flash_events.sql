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