SELECT
    TableCode,
    ComponentCode as ColumnCode,
    ANY_VALUE(ComponentLabel) as ColumnLabel
FROM
    {{ref('qDPM_TableStructure')}}
WHERE
    ComponentTypeName = "Table column"
GROUP BY
    1,2
