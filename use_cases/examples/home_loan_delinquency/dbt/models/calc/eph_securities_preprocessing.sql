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


-- Securities pre-processing
--
-- This model performs the securities preprocessing.

SELECT
    SEC_NUMBER               AS sec_number,
    PROPERTY_STATE           AS property_state,
    PROPERTY_TYPE            AS property_type,
    VALUATION_DATE           AS valuation_date,
    SECURITY_VALUE           AS security_value,
    CONTRACT_OF_SALE_DATE    AS contract_of_sale_date,
    SEC_TYPE                 AS security_type,
    STATUS                   AS security_status,
    PROPERTY_POST_CODE       AS property_post_code
FROM
    {{ref('src_securities')}}
