SELECT
    datapointvid,
    dimensionid,
    memberid
FROM
    {{ref('qDPM_DataPointMetric')}} as qDPM_DataPointMetric

UNION ALL

SELECT
    datapointvid,
    dimensionid,
    memberid
FROM
    {{ref('qDPM_DataPointDimensionCoordinates')}} as qDPM_DataPointDimensionCoordinates
