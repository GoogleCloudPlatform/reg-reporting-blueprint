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
-- This model performs the loans data preprocessing, including joining to the reference data to derive entity data.

select
  -- type
  "Loan" AS exposure_type,

  -- entity code
  em.LEGAL_ENTITY_CODE AS entity_code,

  -- entity name
  em.LEGAL_ENTITY_NAME AS entity_name,

  -- account_number
  loan.LOAN_NUMBER AS account_number,

  -- account_status
  loan.LOAN_STATUS AS account_status,

  -- account_balance
  loan.AMT_CURR_LOAN_BAL AS account_balance,

  -- product_code
  loan.PRODUCT_CODE AS product_code,

  -- product_subcode
  loan.PRODUCT_SUBCODE AS product_subcode,

  -- cost_center
  em.COST_CENTRE_CODE AS cost_center,

  -- days_delinquent
  loan.NUMBER_DAYS_PAST_DUE AS days_delinquent,

  -- npl_flag
  loan.NON_ACCRUAL_STATUS AS npl_flag,

  -- date_opened
  loan.DATE_LOAN_ADDED AS date_opened


FROM
  {{ref('src_loans')}} loan
INNER JOIN
  {{ref('ref_legal_entity_mapping')}} em ON
  loan.cost_center = em.cost_centre_code

