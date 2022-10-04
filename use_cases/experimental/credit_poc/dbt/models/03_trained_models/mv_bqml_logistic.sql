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

-- Multivariate logistic regression model implemented in BQML

{{config(
        materialized='model',
        ml_config={
             'MODEL_TYPE': 'LOGISTIC_REG',
             'INPUT_LABEL_COLS': ['label'],
             'AUTO_CLASS_WEIGHTS': true,
             'DATA_SPLIT_METHOD': 'custom',
             'DATA_SPLIT_COL': 'is_test_data',
             'CALCULATE_P_VALUES': true,
             'CATEGORY_ENCODING_METHOD': 'DUMMY_ENCODING',
             'ENABLE_GLOBAL_EXPLAIN': true,
            }
        )
    }}
SELECT
  *
FROM
  {{ref('training_data')}}

