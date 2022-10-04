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

-- This macro gets all features from the ml_audit table which have a roc_auc above a given threshold.
-- If a feature has been evaluated multiple times, only the last evaluation is considered.

{#
This macro gets all fetures from the ml_audit table which have a roc_auc above a given threshold.
If a feature has been evaluated multiple times, only the last evaluation is considered.
#}

{% macro get_metrics_by_auc(audit_schema=var('dbt_ml:audit_schema'),
                            audit_table=var('dbt_ml:audit_table'),
                            substitute_from='eval_metrics_',
                            substitute_to='metrics.',
                            threshold_roc_auc=0.7)
                            %}
    {%- set audit_table =
        api.Relation.create(
            database=target.database,
            schema=audit_schema,
            identifier=audit_table,
            type='table')
        -%}

    {%- set get_metrics_by_auc_query %}
        WITH
          latest_data AS (
          SELECT
            model,
            MAX(created_at) last_trained_on,
          FROM
            {{audit_table}}
          GROUP BY
            model
        )
        SELECT
            REPLACE(a.model, '{{substitute_from}}', '{{substitute_to}}') as metric
        FROM
          latest_data l LEFT JOIN
          {{audit_table}} a ON
          l.model = a.model AND
          l.last_trained_on = a.created_at CROSS JOIN
          UNNEST(a.evaluate) AS flat_evaluate
        WHERE
          STARTS_WITH(a.model, '{{substitute_from}}') is True AND
          roc_auc > {{threshold_roc_auc}}
    {% endset %}

    {% if execute %}
        {% set metrics = run_query(get_metrics_by_auc_query) %}
        {% set metrics_list = metrics.columns[0].values() %}
        {{ return (metrics_list|join(', ')) }}
    {% else %}
      {% set metrics_list = [] %}
    {% endif %}

{% endmacro %}