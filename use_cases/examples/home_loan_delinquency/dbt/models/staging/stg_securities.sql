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


-- Security (collateral) details (broadly split between property security
-- and other)
--
-- This model selects security data. The business logic to identify the
-- primary security is implemented in this model. The data is enriched
-- with reference data coming from the region reference data, which is
-- joined via the accounts linkage table.
--
-- To inspect the definition of the fields, generate the DBT documentation

WITH data AS (
    SELECT
        s.sec_number,
        s.property_state,
        s.property_type,
        s.valuation_date,
        s.security_value,
        s.contract_of_sale_date,
        s.security_type,
        s.security_status,
        a.account_number,
        mc.region AS region,
        DENSE_RANK() OVER (
            PARTITION BY
                a.account_number
            ORDER BY
                CASE
                    WHEN
                        DATE_DIFF(
                            a.date_opened,
                            s.contract_of_sale_date,
                            DAY
                        ) < 8
                        THEN 1
                    ELSE 2
                END ASC,
                s.valuation_date DESC,
                s.security_value DESC,
                s.sec_number DESC
        ) AS security_rank
    FROM {{ ref('eph_securities_preprocessing') }} AS s
    INNER JOIN {{ ref('src_link_securities_accounts') }} AS x
        ON s.sec_number = x.sec_number
    INNER JOIN {{ ref('stg_accounts') }} AS a
        ON x.account_number = a.account_number
    INNER JOIN {{ ref('ref_region_codes') }} AS mc
        ON s.property_post_code = mc.property_post_code

)

SELECT DISTINCT
    *,
    COALESCE(security_rank = 1, FALSE) AS is_primary
FROM
    data
