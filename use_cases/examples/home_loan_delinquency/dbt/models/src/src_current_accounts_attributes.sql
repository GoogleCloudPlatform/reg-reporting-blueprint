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


-- Source data containing current accounts information
--
-- This query selects the relevant fields from the src_current_accounts_attributes source,
-- which contains current account information which has been artificially manufactured.
-- The scripts performs some minimum transformations and types conversions
-- To inspect the definition of the fields, generate the DBT documentation

SELECT
    ACCOUNT_KEY,
    ACT_STATUS,
    PRODUCT_CODE,
    PRODUCT_SUBCODE,
    COST_CENTER,
    CASE
        WHEN DATE_EXCESS_BEGAN = '0000-00-00' THEN null
        ELSE DATE(DATE_EXCESS_BEGAN)
    END AS DATE_EXCESS_BEGAN,
    CURRENT_OD_LIMIT,
    DATE(DATE_OPENED) AS DATE_OPENED
FROM
    {{ source('sample_data', 'src_current_accounts_attributes')}}
