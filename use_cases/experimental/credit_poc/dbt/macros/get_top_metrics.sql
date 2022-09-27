{#
This macro selects the top metrics based on a given threshold.

Arguments:
    table_ref: a reference to the model containing the data
    metric_column_id: the name of the column containing the name of the metric
#}

{% macro get_top_metrics(from_clause, metric_column_id) %}
    {% set select_top_metrics_query %}
    SELECT
        DISTINCT {{ metric_column_id }} AS metric_name
    FROM
        {{ from_clause }}
    {% endset %}
    {% if execute %}
      {% set top_metrics = run_query(select_top_metrics_query) %}
      {% set top_metrics_list = top_metrics.columns[0].values() %}
      {{ return (top_metrics_list) }}
    {% else %}
      {% set top_metrics = [] %}
    {% endif %}
{% endmacro %}
