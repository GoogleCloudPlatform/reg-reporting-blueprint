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

-- Multivariate XG Boost model implemented in BQML

{{config(
        materialized='model',
        ml_config={
             'MODEL_TYPE': 'BOOSTED_TREE_CLASSIFIER',
             'INPUT_LABEL_COLS': ['label'],
             'NUM_TRIALS': 50,
             'ENABLE_GLOBAL_EXPLAIN': true,
             'HPARAM_TUNING_ALGORITHM': 'VIZIER_DEFAULT',
             'HPARAM_TUNING_OBJECTIVES': ['roc_auc'],
             'learn_rate': dbt_ml.hparam_range(0.05, 0.3),
             'max_tree_depth': dbt_ml.hparam_range(3, 15),
             'min_tree_child_weight': dbt_ml.hparam_range(1, 7),
             'colsample_bytree': dbt_ml.hparam_range(0.3, 0.7)
        }
    )
}}
select
    *
from
    {{ref('training_data')}}