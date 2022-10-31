SELECT
    -- Generate an ID
    MD5(CONCAT(DataPointVID, "-1")) AS row_key,
    -- Get all the Dimensions, sorted alphabetically
    STRUCT(
    {{ dbt_utils.pivot(
          column='CleansedDimensionLabel',
          values=dbt_utils.get_column_values(
                table=ref('DataPointCategorisationsCleansed'),
                column='CleansedDimensionLabel',
                order_by='CleansedDimensionLabel ASC',
                where='DimensionLabel<>"Metric"'
                ),
          alias=True,
          agg='ANY_VALUE',
          cmp='=',
          then_value='MemberName',
          else_value='NULL'
      )}}
    ) as dimensions,
    -- Get all the Metrics, sorted alphabetically
    STRUCT(
        {{ dbt_utils.pivot(
            column='CleansedMemberName',
            values=dbt_utils.get_column_values(
                  table=ref('DataPointCategorisationsCleansed'),
                  column='CleansedMemberName',
                  order_by='CleansedMemberName ASC',
                  where='DimensionLabel="Metric"'
                  ),
            alias=True,
            agg='ANY_VALUE',
            cmp='=',
            then_value="100000.00*RAND()",
            else_value='NULL'
        )}}
    ) as metrics
FROM
    {{ref('DataPointCategorisationsCleansed')}}--,
--    UNNEST(GENERATE_ARRAY(1, {{var("num_datapoints_copies")}}, 1)) as row_copy
--WHERE DataPointVID IN (423953, 234804, 149631, 41764) -- uncomment to run on very small data
GROUP BY
    1