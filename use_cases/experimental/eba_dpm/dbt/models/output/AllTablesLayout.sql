SELECT
    SAFE_CAST(DataPointVID AS INT) as DataPointVID,
    TableCellDataPoints.* EXCEPT (DataPointVID),
    row_labels.RowLabel,
    column_labels.ColumnLabel,
FROM
    {{ref('qDPM_TableCellDataPoints')}} TableCellDataPoints LEFT JOIN
    {{ref('ColumnLabels')}} column_labels ON
        TableCellDataPoints.TableCode = column_labels.TableCode AND
        TableCellDataPoints.ColumnCode = column_labels.ColumnCode LEFT JOIN
    {{ref('RowLabels')}} row_labels ON
        TableCellDataPoints.TableCode = row_labels.TableCode AND
        TableCellDataPoints.RowCode = row_labels.RowCode