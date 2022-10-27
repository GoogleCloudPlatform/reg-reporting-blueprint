SELECT
    * ,
    REGEXP_REPLACE(DimensionLabel, r'[^a-zA-Z]', '_') as CleansedDimensionLabel,
FROM
    {{ref('qDPM_DataPointCategorisations')}}