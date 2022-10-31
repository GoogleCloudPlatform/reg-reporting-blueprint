{% set dimensions = adapter.get_columns_in_relation(ref('AllDataPointsMappings')) %}


{%- for dimension in dimensions %}
    {%- if dimension['name'] not in ['DataPointVID', 'metric', 'CleansedMetric'] %}
        (mappings.{{ dimension['name'] }} = data.dimensions.{{ dimension['name'] }} OR data.dimensions.{{ dimension['name'] }} IS NULL)
        {%- if not loop.last %} AND {% endif %}
    {%- endif %}
{%- endfor %}