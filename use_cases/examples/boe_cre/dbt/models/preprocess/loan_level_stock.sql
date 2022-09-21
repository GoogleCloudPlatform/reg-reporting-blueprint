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


-- Loan level stock
--
-- This model reads the loan level stock data from the source dataset, and creates the bucketised LTV and ICR.

SELECT
    *,
    CASE
        WHEN deal_type IN ('New client', 'Existing client, new transaction')  THEN 'New_client_or_transaction'
        WHEN deal_type = 'Existing client, refinance of existing transaction' THEN 'Refinance_of_existing_transaction'
    END AS table_A_category,
    CASE
        WHEN transaction_type = 'CRE Investment'   THEN
            CASE
                WHEN                                ltv_at_origination < 0.50 THEN 'A. <50%'
                WHEN ltv_at_origination >= 0.50 AND ltv_at_origination < 0.60 THEN 'B. 50.00 - 59.99%'
                WHEN ltv_at_origination >= 0.60 AND ltv_at_origination < 0.65 THEN 'C. 60.00 - 64.99%'
                WHEN ltv_at_origination >= 0.65 AND ltv_at_origination < 0.70 THEN 'D. 65.00 – 69.99%'
                WHEN ltv_at_origination >= 0.70 AND ltv_at_origination < 0.75 THEN 'E. 70.00 – 74.99%'
                WHEN ltv_at_origination >= 0.75 AND ltv_at_origination < 0.80 THEN 'F. 75.00 – 79.99%'
                WHEN ltv_at_origination >= 0.80                               THEN 'G. >79.99%'
            END
        WHEN transaction_type = 'CRE Development'   THEN
            CASE
                WHEN                  ltev < 0.50 THEN 'A. <50%'
                WHEN ltev >= 0.50 AND ltev < 0.60 THEN 'B. 50.00 - 59.99%'
                WHEN ltev >= 0.60 AND ltev < 0.65 THEN 'C. 60.00 - 64.99%'
                WHEN ltev >= 0.65 AND ltev < 0.70 THEN 'D. 65.00 – 69.99%'
                WHEN ltev >= 0.70 AND ltev < 0.75 THEN 'E. 70.00 – 74.99%'
                WHEN ltev >= 0.75 AND ltev < 0.80 THEN 'F. 75.00 – 79.99%'
                WHEN ltev >= 0.80                 THEN 'G. >79.99%'
            END
    END AS ltv_band,
    CASE
        WHEN                icr <= 1.25 THEN 'A. <= 1.25'
        WHEN icr > 1.25 AND icr <= 1.50 THEN 'B. <= 1.50'
        WHEN icr > 1.50 AND icr <= 2.00 THEN 'C. <= 2.00'
        WHEN icr > 2.00 AND icr <= 3.00 THEN 'D. <= 3.00'
        WHEN icr > 3.00 AND icr <= 4.00 THEN 'E. <= 4.00'
        WHEN icr > 4.00                 THEN 'F. > 4.00'
    END AS icr_band
FROM
    {{ source('input_data', 'loan_level_stock_granular') }}
