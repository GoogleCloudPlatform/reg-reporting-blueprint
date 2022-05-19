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


-- A mapping between cost centre codes and legal entities
--
-- This query selects the relevant fields from ref_legal_entity_mapping, which contains a
-- source to target mapping between cost centres and legal entity codes.
-- To inspect the definition of the fields, generate the DBT documentation

SELECT
    COST_CENTRE_CODE,
    LEGAL_ENTITY_CODE,
    LEGAL_ENTITY_NAME
FROM
    {{ source('sample_data', 'ref_legal_entity_mapping')}}
