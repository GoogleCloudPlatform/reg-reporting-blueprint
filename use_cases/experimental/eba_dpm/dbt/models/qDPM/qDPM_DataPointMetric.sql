SELECT
    DataPointVersion.DataPointVID,
    100 AS DimensionID,
    DataPointVersion.MetricID AS MemberID
FROM
    {{source('dpm_model', 'v3_2_DataPointVersion')}} as DataPointVersion;
