SELECT
    Member.MemberID, 
    Metric.MetricID, 
    Member.MemberCode, 
    Member.MemberLabel, 
    DataType.DataTypeCode, 
    FlowType.FlowTypeCode, 
    Domain.DomainCode, 
    Hierarchy.HierarchyCode,
    -- DataType refactored from this
    --IIf(datatypecode Is Null, "", " " & datatypecode & flowtypecode) &
    --IIf(domaincode Is Null,"",":" & domaincode) &
    --IIf(hierarchycode Is Null,"",":" & hierarchycode) &
    --IIf(datatypecode Is Null,"","") AS DataType,
    CONCAT(
        IF(datatypecode Is Null, "", CONCAT(" ", datatypecode, flowtypecode)),
        IF(domaincode Is Null,"", CONCAT(":", domaincode)),
        IF(hierarchycode Is Null,"", CONCAT(":", hierarchycode)),
        IF(datatypecode Is Null,"","")
    ) AS DataType,
    CONCAT(MemberLabel,
        CONCAT(
            IF(datatypecode Is Null, "", CONCAT(" ", datatypecode, flowtypecode)),
            IF(domaincode Is Null,"", CONCAT(":", domaincode)),
            IF(hierarchycode Is Null,"", CONCAT(":", hierarchycode)),
            IF(datatypecode Is Null,"","")
        )
    ) AS MemberName
FROM
    {{source('dpm_model', 'dpm_Member')}} Member LEFT JOIN
    {{source('dpm_model', 'dpm_Metric')}} Metric ON
        Member.MemberID = Metric.MetricID LEFT JOIN
    {{source('dpm_model', 'dpm_DataType')}} DataType ON
        DataType.DataTypeID = Metric.DataTypeID LEFT JOIN
    {{source('dpm_model', 'dpm_FlowType')}} FlowType ON
        FlowType.FlowTypeID = Metric.FlowTypeID LEFT JOIN
    {{source('dpm_model', 'dpm_Domain')}} Domain ON
        Domain.DomainID = Metric.CodeDomainID LEFT JOIN
    {{source('dpm_model', 'dpm_Hierarchy')}} Hierarchy ON
        Hierarchy.HierarchyID = Metric.CodeSubdomainID