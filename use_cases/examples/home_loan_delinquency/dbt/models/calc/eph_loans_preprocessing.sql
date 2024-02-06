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


-- Loans pre-processing
--
-- This model performs the loans data preprocessing, including joining to
-- the reference data to derive entity data.

SELECT
    -- type
    "Loan" AS exposure_type,

    -- entity code
    em.legal_entity_code AS entity_code,

    -- entity name
    em.legal_entity_name AS entity_name,

    -- account_number
    loan.loan_number AS account_number,

    -- account_status
    loan.loan_status AS account_status,

    -- account_balance
    loan.amt_curr_loan_bal AS account_balance,

    -- product_code
    loan.product_code AS product_code,

    -- product_subcode
    loan.product_subcode AS product_subcode,

    -- cost_center
    em.cost_centre_code AS cost_center,

    -- days_delinquent
    loan.number_days_past_due AS days_delinquent,

    -- npl_flag
    loan.non_accrual_status AS npl_flag,

    -- date_opened
    loan.date_loan_added AS date_opened


FROM {{ ref('src_loans') }} AS loan
INNER JOIN {{ ref('ref_legal_entity_mapping') }} AS em
    ON loan.cost_center = em.cost_centre_code
