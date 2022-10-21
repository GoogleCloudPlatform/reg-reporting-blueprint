SELECT 
    Member.MemberID, 
    Metric.MetricID, 
    Member.MemberCode, 
    Member.MemberLabel, 
    DataType.DataTypeCode, 
    FlowType.FlowTypeCode, 
    Domain.DomainCode, 
    Hierarchy.HierarchyCode, 
    IIf(datatypecode Is Null, "", " " & datatypecode & flowtypecode) & 
    IIf(domaincode Is Null,"",":" & domaincode) & 
    IIf(hierarchycode Is Null,"",":" & hierarchycode) & 
    IIf(datatypecode Is Null,"","") AS DataType, 
    MemberLabel & DataType AS MemberName
FROM
    {{source('dpm_model', 'v3_2_Member')}} Member LEFT JOIN
    {{source('dpm_model', 'v3_2_Metric')}} Metric ON




    {{source('dpm_model', 'v3_2_FlowType')}} FlowType RIGHT JOIN
    {{source('dpm_model', 'v3_2_Hierarchy')}} Hierarchy RIGHT JOIN
    {{source('dpm_model', 'v3_2_Domain')}} Domain RIGHT JOIN
    {{source('dpm_model', 'v3_2_DataType')}} DataType RIGHT JOIN
        DataType.DataTypeID = Metric.DataTypeID AND
        Domain.DomainID = Metric.CodeDomainID AND
        Hierarchy.HierarchyID = Metric.CodeSubdomainID AND
        Member.MemberID = Metric.MetricID AND
        FlowType.FlowTypeID = Metric.FlowTypeID