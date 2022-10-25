SELECT
    DataPointVersion.DataPointVID,
    DimensionalCoordinate.DimensionID,
    DimensionalCoordinate.MemberID
FROM
    {{source('dpm_model', 'dpm_DimensionalCoordinate')}} DimensionalCoordinate INNER JOIN
        (({{source('dpm_model', 'dpm_ContextOfDataPoints')}} ContextOfDataPoints INNER JOIN
          {{source('dpm_model', 'dpm_ContextDefinition')}} ContextDefinition ON
          ContextOfDataPoints.ContextID = ContextDefinition.ContextID) INNER JOIN
    {{source('dpm_model', 'dpm_DataPointVersion')}} DataPointVersion ON
        ContextOfDataPoints.ContextID = DataPointVersion.ContextID) ON
  (DimensionalCoordinate.MemberID = ContextDefinition.MemberID)
  AND (DimensionalCoordinate.DimensionID = ContextDefinition.DimensionID)
