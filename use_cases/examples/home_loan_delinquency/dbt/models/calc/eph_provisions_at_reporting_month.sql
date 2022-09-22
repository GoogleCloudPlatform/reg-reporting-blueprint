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


-- Provisions at reporting month
--
-- This model selects the provisions for a given reporting month.
-- Note that the reporting month is selected using a parameterised variables, which is defaulted in the
-- project file, and can be overidden when executing the dbt run command.

SELECT
    *
FROM
    {{ref('stg_provisions')}} p
WHERE
    CAST(p.period AS STRING) = '{{ get_reporting_month(var('reporting_day') ) }}'

