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


-- This model adds additional features manually engineered, including ratios and logs

SELECT
    --all submissions fields
    * EXCEPT (metrics, will_default, is_test_data),
    --all bare metrics from the submissions
    metrics,
    --some ratios
    STRUCT(
        {{ dbt_ml_helpers.divide_value_pivoted(numerator='AssetsCurrent_0_USD_',
                                               denominator='LiabilitiesCurrent_0_USD_',
                                               prefix='metrics') }},
        {{ dbt_ml_helpers.divide_value_pivoted(numerator='Assets_0_USD_ParentCompany',
                                               denominator='DeferredTaxLiabilitiesUndistributedForeignEarnings_0_USD_',
                                               prefix='metrics') }}
    ) AS ratios,
    --some logs
    STRUCT(
        {{ dbt_ml_helpers.log_value_pivoted('Assets_0_USD_ParentCompany',  prefix='metrics') }},
        {{ dbt_ml_helpers.log_value_pivoted('AssetsCurrent_0_USD_',        prefix='metrics') }}
    ) as logs,
    will_default as label,
    is_test_data
FROM
    {{ref('submissions_pivot_metrics')}}