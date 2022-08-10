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


-- Table C CRE Loans flows over past year
--
-- Provides a breakdown of loans flows as per table C

SELECT
    main_receiver_of_distributed_loan,
    sum(limit_value) as limit_value,
    sum(amount_kept_on_balance_sheet) as amount_kept_on_balance_sheet
FROM
    {{ ref('loan_level_flow') }}
WHERE
    drawdown_date BETWEEN DATE(2019,1,1) AND DATE(2019,12,31)
GROUP BY
    1