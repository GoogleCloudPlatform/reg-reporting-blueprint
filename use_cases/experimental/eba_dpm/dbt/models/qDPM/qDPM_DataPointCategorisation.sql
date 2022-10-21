SELECT
    qDPM_DataPointCompositeDimensionMembers.DataPointVID,
    DataPointVersion.DataPointID,
    Dimension.DimensionLabel,
    qDPM_MemberNameAndDataType.MemberName
FROM
    ((
    {{source('dpm_model', 'v3_2_Dimension')}} Dimension INNER JOIN
    {{ref('qDPM_DataPointCompositeDimensionMembers')}} qDPM_DataPointCompositeDimensionMembers ON
        Dimension.DimensionID = qDPM_DataPointCompositeDimensionMembers.DimensionID) INNER JOIN
    {{ref('qDPM_MemberNameAndDataType')}} qDPM_MemberNameAndDataType ON
        qDPM_DataPointCompositeDimensionMembers.MemberID = qDPM_MemberNameAndDataType.MemberID) LEFT JOIN
    {{source('dpm_model', 'v3_2_DataPointVersion')}} DataPointVersion ON
        qDPM_DataPointCompositeDimensionMembers.datapointvid = DataPointVersion.DataPointVID
ORDER BY
  qDPM_DataPointCompositeDimensionMembers.DataPointVID,
  Dimension.DimensionCode,
  Dimension.DimensionLabel