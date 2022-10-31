SELECT
    * ,
    LOWER(REGEXP_REPLACE(DimensionLabel, r'[^a-zA-Z]', '_')) as CleansedDimensionLabel,
    LOWER(REGEXP_REPLACE(MemberName, r'[^a-zA-Z]', '_')) as CleansedMemberName,
FROM
    {{ref('qDPM_DataPointCategorisations')}}