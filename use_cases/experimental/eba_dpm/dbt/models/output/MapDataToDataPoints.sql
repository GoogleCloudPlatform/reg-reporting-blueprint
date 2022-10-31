-- Initialise a variable with all the dimensions. These are needed for the join to the mapping data
{% set dimensions = adapter.get_columns_in_relation(ref('AllDataPointsMappings')) %}

-- Initialise a variable with all the metrics. This is needed to derive the value that is plotted in each Table/Row/Col
{% set metrics = dbt_utils.get_column_values(
          table=ref('DataPointCategorisationsCleansed'),
          column='CleansedMemberName',
          order_by='CleansedMemberName ASC',
          where='DimensionLabel="Metric"'
          )
%}

-- Map all the granular data to the templates layout
SELECT
    -- Get all layout fields, this includes the layout of each template (table, row, columns and their labels)
    layout,
    -- Get all the granular data
    data,
    -- Calculate the report value by getting the metric which matches the mappings
    CASE
    {%- for metric in metrics %}
        {%- if metric['name'] not in ['CleansedMetric'] %}
        WHEN mappings.CleansedMetric = '{{metric}}' THEN data.metrics.{{metric}}
        {%- endif %}
    {%- endfor %}
    END as value
FROM
    {{ref('AllTablesLayout')}}          layout         LEFT JOIN
    {{ref('AllDataPointsMappings')}}    mappings       ON
        layout.DataPointVID = mappings.DataPointVID    LEFT JOIN
    {{ref('TestDataGenerator')}}        data           ON
    -- Join the granular data to the mappings, using all the dimensions in the mappings
    {%- for dimension in dimensions %}
        {%- if dimension['name'] not in ['DataPointVID', 'metric', 'CleansedMetric'] %}
            (mappings.{{ dimension['name'] }} = data.dimensions.{{ dimension['name'] }} OR data.dimensions.{{ dimension['name'] }} IS NULL)
            {%- if not loop.last and dimension['name'] not in ['DataPointVID', 'metric', 'CleansedMetric'] %} AND {% endif %}
        {%- endif %}
    {%- endfor %}

