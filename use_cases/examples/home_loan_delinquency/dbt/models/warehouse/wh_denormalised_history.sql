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


-- Denormalised table with all accounts data, including history
--
-- This model selects all the accounts data in a large denormalised structure,
-- which includes:
-- * Control data, in a structured format. Contains the reporting_day and the
--   execution time
-- * Account data, in a structured format with sub-fields
-- * Product data, in a structured format with sub-fields
-- * Securities data, in a structured and repeated format. Contains all the
--   securities associated to an account
-- * Primary security, in a structured format. Contains the data for the primary
--   security (rank 1) associated to an account
-- * Provisions, in a structured format. Contains data about the provisions for
--   an account.
-- * A placeholder for the regulatory calculations, in a structured format.
--   Contains reg metrics (e.g. RWA), calculated at an account granularity
-- To inspect the definition of the fields, generate the DBT documentation


SELECT
    STRUCT(
        DATE('{{ var('reporting_day') }}') AS reporting_day,
        TIMESTAMP('{{ run_started_at }}') AS run_started_at
    ) AS control,
    STRUCT(
        a.exposure_type,
        a.entity_code,
        a.entity_name,
        a.account_number,
        a.account_status,
        a.account_balance,
        a.product_code,
        a.product_subcode,
        a.cost_center,
        a.days_delinquent,
        a.days_delinquent_bucket,
        a.npl_flag,
        a.date_opened
    ) AS account, -- noqa: RF04
    STRUCT(
        p.product_code,
        p.product_subcode,
        p.description,
        p.active_flag
    ) AS product,
    ARRAY(
        SELECT AS STRUCT
            s.sec_number,
            s.property_state,
            s.property_type,
            s.valuation_date,
            s.security_value,
            s.contract_of_sale_date,
            s.security_type,
            s.security_status,
            s.security_rank,
            s.region,
            s.is_primary
        FROM
            {{ ref('stg_securities') }} AS s
        WHERE
            s.account_number = a.account_number
    ) AS securities,
    STRUCT(
        ps.sec_number,
        ps.property_state,
        ps.property_type,
        ps.valuation_date,
        ps.security_value,
        ps.contract_of_sale_date,
        ps.security_type,
        ps.security_status,
        ps.security_rank,
        ps.region,
        ps.is_primary
    ) AS primary_security,
    STRUCT(
        pr.period,
        pr.account_number,
        pr.case_reference,
        pr.reason,
        pr.provision_amount
    ) AS provisions,
    STRUCT(
        NULL AS impaired_assets,
        NULL AS rwa
    ) AS regulatory_calcs
FROM {{ ref('stg_accounts') }} AS a
LEFT OUTER JOIN {{ ref('stg_products') }} AS p
    ON (
        a.product_code = p.product_code
        AND a.product_subcode = p.product_subcode
    )
LEFT OUTER JOIN {{ ref('stg_securities') }} AS ps
    ON (
        ps.account_number = a.account_number
        AND ps.is_primary = TRUE
    )
LEFT OUTER JOIN {{ ref('eph_provisions_at_reporting_month') }} AS pr
    ON (
        pr.account_number = a.account_number
    )
