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


-- Source data containing the loans information
--
-- This query selects the relevant fields from the src_loans source,
-- which contains loan information which has been artificially manufactured.
-- The scripts performs some minimum transformations and types conversions.
-- To inspect the definition of the fields, generate the DBT documentation

SELECT
    loan_number,
    loan_status,
    amt_curr_loan_bal,
    product_code,
    product_subcode,
    number_days_past_due,
    cost_center,
    non_accrual_status,
    DATE(date_loan_added) AS date_loan_added
FROM
    {{ source('sample_data', 'src_loans') }}
