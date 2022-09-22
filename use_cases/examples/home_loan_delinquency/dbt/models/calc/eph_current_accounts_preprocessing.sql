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


-- Current account pre-processing
--
-- This model performs the current account preprocessing, including joining account information and balances,
-- renaming fields to a lower case convention, and calculating the days delinquent.

SELECT
  -- Type
  "Current Account" AS exposure_type,

  -- entity code
  em.LEGAL_ENTITY_CODE AS entity_code,

  -- entity name
  em.LEGAL_ENTITY_NAME AS entity_name,

  -- account_number
  ca_a.ACCOUNT_KEY AS account_number,

  -- account_status
  ca_a.ACT_STATUS AS account_status,

  -- account_balance
  CASE
    WHEN ca_b.CURRENT_BALANCE < 0
    THEN ca_b.CURRENT_BALANCE * -1
    ELSE 0
  END AS account_balance,

  -- product_code
  ca_a.PRODUCT_CODE AS product_code,

  -- product_subcode
  ca_a.PRODUCT_SUBCODE AS product_subcode,

  -- cost_center
  em.COST_CENTRE_CODE AS cost_center,

  -- days_delinquent
  CASE
    WHEN
        ca_a.DATE_EXCESS_BEGAN is not null AND
        ca_b.CURRENT_BALANCE < ca_a.CURRENT_OD_LIMIT
    THEN
        DATE_DIFF(CURRENT_DATE(), DATE(ca_a.DATE_EXCESS_BEGAN), DAY) + 1
    ELSE 0
  END AS days_delinquent,

  -- npl_flag
  CASE
    WHEN ca_a.PRODUCT_SUBCODE in ('01')
    THEN True
    ELSE False
  END AS npl_flag,

   -- date_opened
  ca_a.DATE_OPENED AS date_opened

FROM
  {{ref('src_current_accounts_balances')}}   ca_b   INNER JOIN
  {{ref('src_current_accounts_attributes')}} ca_a       ON
  ca_b.ACCOUNT_KEY = ca_a.ACCOUNT_KEY               INNER JOIN
  {{ref('ref_legal_entity_mapping')}} em                ON
  em.COST_CENTRE_CODE = ca_a.COST_CENTER
