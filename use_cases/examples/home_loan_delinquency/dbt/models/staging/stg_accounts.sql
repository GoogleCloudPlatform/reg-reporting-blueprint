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


-- A table containing all the accounts across the portfolio. Includes Current Accounts and Loans
--
-- This model selects the harmonised account information including current accounts and loans,
-- joins it together with provisions data, and calculates the delinquency band.
-- To inspect the definition of the fields, generate the DBT documentation

WITH unioned_data AS (
    SELECT * FROM {{ref('eph_current_accounts_preprocessing')}}

        UNION ALL

    SELECT * FROM {{ref('eph_loans_preprocessing')}}
)

SELECT
  a.exposure_type,
  a.account_number,
  a.entity_code,
  a.entity_name,
  a.account_status,
  a.account_balance,
  a.product_code,
  a.product_subcode,
  a.cost_center,
  a.days_delinquent,
  CASE
    WHEN a.days_delinquent = 0                 THEN '0'
    WHEN a.days_delinquent BETWEEN 1 AND 29    THEN '1-29'
    WHEN a.days_delinquent BETWEEN 30 AND 59   THEN '30-59'
    WHEN a.days_delinquent BETWEEN 60 AND 89   THEN '60-89'
    WHEN a.days_delinquent BETWEEN 90 AND 119  THEN '90-119'
    WHEN a.days_delinquent BETWEEN 120 AND 149 THEN '120-149'
    WHEN a.days_delinquent BETWEEN 150 AND 179 THEN '150-179'
    WHEN a.days_delinquent BETWEEN 180 AND 359 THEN '180-359'
    WHEN a.days_delinquent BETWEEN 360 AND 719 THEN '360-719'
    WHEN a.days_delinquent >= 720              THEN '720+'
  END AS days_delinquent_bucket,
  CASE
    WHEN p.account_number IS NOT NULL
    THEN True
    ELSE npl_flag
  END AS npl_flag,
  a.date_opened

FROM
    unioned_data a                                  LEFT OUTER JOIN
    {{ref('eph_provisions_at_reporting_month')}} p  ON
    a.account_number = p.account_number
