SELECT
    TableCellDataPoints.*
FROM
    {{ref('qDPM_TableCellDataPoints')}} TableCellDataPoints
    --JOIN {{ref('qDPM_TableStructure')}} TableStructure ON
    -- TableStructure.TableCode AND