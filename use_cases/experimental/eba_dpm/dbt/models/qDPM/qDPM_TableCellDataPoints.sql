SELECT
    CONCAT(mvCellLocation.TableVersionCode," - ", TableVersionLabel) AS TableCode,
    mvCellLocation.TableVersionCode,
    TableVersion.TableVersionLabel,
    mvCellLocation.RowCode,
    mvCellLocation.ColumnCode,
    mvCellLocation.SheetCode,
    CASE
      WHEN mvCellLocation.isshaded THEN "-1"
      WHEN mvCellLocation.isRowKey THEN "<Key Value>"
      WHEN TRUE THEN CAST(mvCellLocation.DataPointvid as STRING)
    END AS DataPointVID,
    CASE
      WHEN mvCellLocation.isshaded THEN "-1"
      WHEN mvCellLocation.isRowKey THEN "<Key Value>"
      WHEN TRUE THEN CAST(mvCellLocation.DataPointid as STRING)
    END AS DataPointID,
    mvCellLocation.TaxonomyCode,
    mvCellLocation.CellID,
    mvCellLocation.TaxonomyID,
    mvCellLocation.ReplacesTaxonomyID,
    mvCellLocation.TableID
FROM
    {{source('dpm_model', 'dpm_mvCellLocation')}} as mvCellLocation INNER JOIN
    {{source('dpm_model', 'dpm_TableVersion')}}  as TableVersion ON
        mvCellLocation.TableVID = TableVersion.TableVID