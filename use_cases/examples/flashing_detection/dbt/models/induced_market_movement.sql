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