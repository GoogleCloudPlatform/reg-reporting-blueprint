{# Copyright 2022 The Reg Reporting Blueprint Authors #}

{# Licensed under the Apache License, Version 2.0 (the "License"); #}
{# you may not use this file except in compliance with the License. #}
{# You may obtain a copy of the License at

{#     https://www.apache.org/licenses/LICENSE-2.0 #}

{# Unless required by applicable law or agreed to in writing, software #}
{# distributed under the License is distributed on an "AS IS" BASIS, #}
{# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #}
{# See the License for the specific language governing permissions and #}
{# limitations under the License. #}



{# create_dbt_log -- create a dbt_log table in the target dataset if not #}
{#                   already there #}
{% macro create_dbt_log(target) %}

{%- set target_relation = api.Relation.create(
          database=var("dbt_log_project", target.project),
          schema=var("dbt_log_dataset", "monitoring"),
          identifier=var("dbt_log_table", "dbt_log"))
-%}


{# Create schema if necessary #}
{% do adapter.create_schema(target_relation) %}

{# Create table if necessary #}
CREATE TABLE IF NOT EXISTS {{ target_relation }} (
  update_time TIMESTAMP,
  dbt_invocation_id STRING,
  stage STRING,
  info JSON
);

{% endmacro %}


{# insert_dbt_log -- insert a log message in the dbt_log #}
{% macro insert_dbt_log(target, stage, json) %}

{%- set target_relation = api.Relation.create(
          database=var("dbt_log_project", target.project),
          schema=var("dbt_log_dataset", "monitoring"),
          identifier=var("dbt_log_table", "dbt_log"))
-%}

INSERT INTO {{ target_relation }} VALUES (
  CURRENT_TIMESTAMP(),
  '{{ invocation_id }}',
  '{{ stage }}',
  SAFE.PARSE_JSON(R"""{{ json }}""")
);

{% endmacro %}


{# results_to_json -- convert results into a JSON message for logging #}
{% macro results_to_json(results) %}
    {%- set results_list = [] -%}
    {%- if execute %}
      {%- for res in results -%}
        {%- set timing_list = [] -%}
        {%- for t in res.timing -%}
          {%- set new_timing = {} -%}
          {%- do new_timing.update(
            name=t.name,
            started_at=t.started_at.isoformat(),
            completed_at=t.completed_at.isoformat(),
          ) -%}
          {%- do timing_list.append(new_timing) -%}
        {% endfor %}
        {%- set result_dict = {} -%}
        {%- do result_dict.update(
          status=res.status,
          message=res.message,
          thread_id=res.thread_id,
          execution_time=res.execution_time | as_text,
          adapter_response=res.adapter_response | as_text,
          timing=timing_list,
          id=res.node.unique_id | as_text,
        ) -%}
        {%- do results_list.append(result_dict) -%}
      {% endfor %}
    {%- endif %}
    {% do return(tojson(results_list)) %}
{% endmacro %}

{# graph_to_json -- convert target and graph to JSON for logging #}
{#               -- env includes extra environment info for logging #}
{% macro graph_to_json(target, graph, env) %}
    {%- set results_list = {} -%}
    {%- if execute %}

      {%- set nodes_list = [] -%}
      {%- for unique_id, info in graph["nodes"].items()-%}
        {%- set result_dict = {} -%}
        {%- do result_dict.update(
          id=unique_id,
          depends_on=info.depends_on.nodes | as_text,
        ) -%}
        {%- do nodes_list.append(result_dict) -%}
      {% endfor %}

      {# Collect generally useful environment information if launched from Airflow #}
      {%- set execution_date = env_var('AIRFLOW_CTX_EXECUTION_DATE', 'unset') | replace(':', '%3A') | replace ('+', '%2B') -%}
      {%- set var_dict = {} -%}
      {%- do var_dict.update(
        build_ref=env_var('BUILD_REF', 'unset'),
        source_ref=env_var('SOURCE_REF', 'unset'),
        source_path=env_var('SOURCE_PATH', 'unset'),
        airflow_task_id=env_var('AIRFLOW_CTX_TASK_ID', 'unset'),
        airflow_dag_id=env_var('AIRFLOW_CTX_DAG_ID', 'unset'),
        airflow_execution_date=execution_date,
      ) -%}

      {# NOTE: graph data has a *lot* of information in it, but it #}
      {# can be too big for BigQuery in an INSERT statement. #}

      {%- do results_list.update(
        project=project_name,
        dbt_version=dbt_version,
        target=target | as_text,
        tree=nodes_list,
        vars=var_dict,
        env=env | default(''),
      ) -%}
    {%- endif %}
    {%- do return(tojson(results_list)) -%}
{% endmacro %}
