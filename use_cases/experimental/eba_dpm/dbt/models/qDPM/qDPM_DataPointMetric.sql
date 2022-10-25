SELECT
    DataPointVersion.DataPointVID,
    100 AS DimensionID,
    DataPointVersion.MetricID AS MemberID
FROM
    {{source('dpm_model', 'dpm_DataPointVersion')}} as DataPointVersion
