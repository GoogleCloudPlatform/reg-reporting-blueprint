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


-- Table A CRE Loans Stock Total Limits
--
-- This model aggregates the data as per Table A CRE Loans Stock Total Limits

WITH data AS (
    SELECT
         'CRE Investment, within policy' AS class,
         table_A_category,
         SUM(limit_value) AS limit_value
    FROM
        {{ ref('loan_level_stock') }}
    WHERE
        transaction_type = 'CRE Investment' AND
        within_policy_or_exception = 'Policy'
    GROUP BY
        1, 2

    UNION ALL

    SELECT
         'CRE Investment, exception to policy' AS class,
         table_A_category,
         SUM(limit_value) AS limit_value
    FROM
        {{ ref('loan_level_stock') }}
    WHERE
        transaction_type = 'CRE Investment' AND
        within_policy_or_exception = 'Exception'
    GROUP BY
        1, 2

    UNION ALL

    SELECT
         'CRE Development, within policy' AS class,
         table_A_category,
         SUM(limit_value) AS limit_value
    FROM
        {{ ref('loan_level_stock') }}
    WHERE
        transaction_type = 'CRE Development' AND
        within_policy_or_exception = 'Policy'
    GROUP BY
        1, 2

    UNION ALL

    SELECT
         'CRE Development, exception to policy' AS class,
         table_A_category,
         SUM(limit_value) AS limit_value
    FROM
        {{ ref('loan_level_stock') }}
    WHERE
        transaction_type = 'CRE Development' AND
        within_policy_or_exception = 'Exception'
    GROUP BY
        1, 2

)

SELECT
    *
FROM
    data
WHERE
    table_A_category IS NOT null
ORDER BY
    1, 2
