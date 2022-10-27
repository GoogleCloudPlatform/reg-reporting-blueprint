SELECT
    TableCode,
    ComponentCode as RowCode,
    ANY_VALUE(ComponentLabel) as RowLabel
FROM
    {{ref('qDPM_TableStructure')}}
WHERE
    ComponentTypeName = "Table row"
GROUP BY
    1,2
