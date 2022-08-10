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


-- Table 1 CRE Loans Stock over 10m report
--
-- This model selects stock of loans over 10m, for Table 1 of the report

SELECT *
FROM {{ ref('loan_level_stock_over_10m') }}