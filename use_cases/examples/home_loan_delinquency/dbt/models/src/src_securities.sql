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


-- Source data containing the securities information
--
-- This query selects the relevant fields from the src_securities source,
-- which contains securities information which has been artificially
-- manufactured. This script performs minimum types conversions. To inspect
-- the definition of the fields, generate the DBT documentation

SELECT -- noqa: ST06
    sec_number,
    property_state,
    property_type,
    DATE(valuation_date) AS valuation_date,
    security_value,
    DATE(contract_of_sale_date) AS contract_of_sale_date,
    sec_type,
    status,
    property_post_code
FROM
    {{ source('sample_data', 'src_securities') }}
