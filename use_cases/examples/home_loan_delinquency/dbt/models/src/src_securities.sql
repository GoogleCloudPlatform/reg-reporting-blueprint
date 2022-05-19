-- Copyright 2022 Google LLC

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
-- which contains securities information which has been artificially manufactured.
-- This script performs minimum types conversions.
-- To inspect the definition of the fields, generate the DBT documentation

SELECT
    SEC_NUMBER,
    PROPERTY_STATE,
    PROPERTY_TYPE,
    DATE(VALUATION_DATE) as VALUATION_DATE,
    SECURITY_VALUE,
    DATE(CONTRACT_OF_SALE_DATE) as CONTRACT_OF_SALE_DATE,
    SEC_TYPE,
    STATUS,
    PROPERTY_POST_CODE
FROM
    {{ source('sample_data', 'src_securities')}}
