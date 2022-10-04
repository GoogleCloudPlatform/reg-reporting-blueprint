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


-- This macro splits the data in a dbt model into a train portion and a test portion.
-- Technically, this macro adds a column named is_test_data, and uses the farm fingerprint on the
-- columns listed in lst_column_ids to generate a unique row.

{#
This macro splits the data in a dbt model into a train portion and a test portion.
Technically, this macro adds a column named is_test_data, and uses the farm fingerprint on the
columns listed in lst_column_ids to generate a unique row.

Parameters:
 - base_model: the dbt model that needs to be split in train and test data
 - train_split_pct: the percentage of data in the train dataset. The test data will be 1 - train_split_pct
 - lst_column_ids: a coma separates list of columns that can be used to identify a row

The final output is a model with all the columns as the base dataset, with an additional column called
is_test_data, with value as follows:
 - TRUE for test data
 - FALSE for training data
#}

{% macro train_test_split(base_model, train_split_pct, lst_column_ids) %}
    {%- set pct_train = train_split_pct * 100 %}
    {%- set pct_test = 100 - pct_train %}

SELECT
    *,
    TRUE as is_test_data -- True: evaluation
FROM
    {{ref(base_model)}}
WHERE
  ABS(MOD(FARM_FINGERPRINT(TO_JSON_STRING(STRUCT({{lst_column_ids}}))), 100)) < {{pct_test}}

UNION ALL

SELECT
    *,
    FALSE as is_test_data -- False: train
FROM
    {{ref(base_model)}}
WHERE
  ABS(MOD(FARM_FINGERPRINT(TO_JSON_STRING(STRUCT({{lst_column_ids}}))), 100)) >= {{pct_test}}

{% endmacro %}