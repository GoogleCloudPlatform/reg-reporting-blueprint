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


-- Provisions against accounts
--
-- This model selects the provisions data.
-- To inspect the definition of the fields, generate the DBT documentation

SELECT DISTINCT
    PERIOD                   AS period,
    ACCOUNT_KEY              AS account_number,
    CASE_REFERENCE           AS case_reference,
    REASON                   AS reason,
    PROVISION_AMOUNT         AS provision_amount

FROM
    {{ref('src_provisions')}} provisions

