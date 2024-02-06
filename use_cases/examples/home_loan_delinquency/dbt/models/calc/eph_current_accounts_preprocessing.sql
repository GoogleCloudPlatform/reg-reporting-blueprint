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
-- This model performs the current account preprocessing, including
-- joining account information and balances, renaming fields to a lower
-- case convention, and calculating the days delinquent.

SELECT -- noqa: ST06
    "Current Account" AS exposure_type,
    em.legal_entity_code AS entity_code,
    em.legal_entity_name AS entity_name,
    ca_a.account_key AS account_number,
    ca_a.act_status AS account_status,
    CASE
        WHEN ca_b.current_balance < 0
            THEN ca_b.current_balance * -1
        ELSE 0
    END AS account_balance,
    ca_a.product_code AS product_code,
    ca_a.product_subcode AS product_subcode,
    em.cost_centre_code AS cost_center,
    CASE
        WHEN
            ca_a.date_excess_began IS NOT NULL
            AND ca_b.current_balance < ca_a.current_od_limit
            THEN
                DATE_DIFF(CURRENT_DATE(), DATE(ca_a.date_excess_began), DAY) + 1
        ELSE 0
    END AS days_delinquent,
    COALESCE(ca_a.product_subcode IN ("01"), FALSE) AS npl_flag,
    ca_a.date_opened AS date_opened

FROM
    {{ ref('src_current_accounts_balances') }} AS ca_b INNER JOIN
    {{ ref('src_current_accounts_attributes') }} AS ca_a
    ON
        ca_b.account_key = ca_a.account_key
INNER JOIN
    {{ ref('ref_legal_entity_mapping') }} AS em ON
    ca_a.cost_center = em.cost_centre_code
