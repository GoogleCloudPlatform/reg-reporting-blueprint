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


-- Calculate RWA with Tensorflow
--
-- The model is applied to the data. Features are input and labels are output.
--

-- Disable templating in this case to simplify working with dbt_ml.prefix
-- sqlfluff:ignore:templating


WITH
-- Ignore src_data isn't used -- it's used in the template (which is ignored)
src_data AS (  -- noqa: ST03
    SELECT
        *,
        0.01 AS probability_of_default,
        0.10 AS loss_given_default,
        account.account_balance AS exposure_at_default
    FROM
        {{ ref('wh_denormalised_history') }}
),

with_rwa AS (
    SELECT *
    FROM
        {{ dbt_ml.predict(ref('tf_rwa_model'), 'src_data') }}
)

SELECT *
FROM
    with_rwa
