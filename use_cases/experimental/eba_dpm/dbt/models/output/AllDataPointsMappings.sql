WITH data AS (
    SELECT
        DataPointVID,
         {{ dbt_utils.pivot(
              column='CleansedDimensionLabel',
              values=dbt_utils.get_column_values(
                    table=ref('DataPointCategorisationsCleansed'),
                    column='CleansedDimensionLabel',
                    order_by='CleansedDimensionLabel ASC'),
              alias=True,
              agg='ANY_VALUE',
              cmp='=',
              then_value='MemberName',
              else_value='NULL'
          )}}
    FROM
        {{ref('DataPointCategorisationsCleansed')}}
    GROUP BY
        1
)
SELECT
    LOWER(REGEXP_REPLACE(metric, r'[^a-zA-Z]', '_')) as CleansedMetric,
    *,
FROM
    data