--SELECT
--  [tableversion].[TableVersionCode] & " - " & [TableVersionLabel] AS TableCode,
--  zzTableChanges.ComponentTypeName,
--  zzTableChanges.ComponentCode,
--  zzTableChanges.ComponentLabel,
--  zzTableChanges.HeaderFlag,
--  zzTableChanges.Level,
--  Val([zzTableChanges].[ComponentCode]) AS [ORDER],
--  zzTableChanges.LastChangedIn AS TaxonomyCode,
--  NULL AS RestrictedToHierarchy,
--  NULL AS RootMember,
--  zzTableChanges.Change,
--  zzTableChanges.LastChangedIn,
--  priorTableStructure.DisplayBeforeChildren,
--  priorTableStructure.OrdinateID,
--  priorTableStructure.ParentOrdinateID
--FROM (((TableVersion
--      INNER JOIN (qDPM_TableStructure_a
--        RIGHT JOIN
--          zzTableChanges
--        ON
--          (qDPM_TableStructure_a.TableVersionCode = zzTableChanges.TableCode)
--          AND (qDPM_TableStructure_a.ComponentTypeName = zzTableChanges.ComponentTypeName)
--          AND (qDPM_TableStructure_a.ComponentCode = zzTableChanges.ComponentCode)
--          AND (qDPM_TableStructure_a.TaxonomyCode = zzTableChanges.LastChangedIn))
--      ON
--        TableVersion.TableVersionCode = zzTableChanges.TableCode)
--    LEFT JOIN
--      qMaxOfTableVIDByTaxonomy
--    ON
--      (zzTableChanges.TableCode = qMaxOfTableVIDByTaxonomy.TableVersionCode)
--      AND (zzTableChanges.LastChangedIn = qMaxOfTableVIDByTaxonomy.TaxonomyCode))
--  LEFT JOIN
--    qMaxOfTableVIDByPredecessorTaxonomy
--  ON
--    (zzTableChanges.TableCode = qMaxOfTableVIDByPredecessorTaxonomy.TableVersionCode)
--    AND (zzTableChanges.LastChangedIn = qMaxOfTableVIDByPredecessorTaxonomy.TaxonomyCode))
--LEFT JOIN
--  qDPM_TableStructure_a AS priorTableStructure
--ON
--  (zzTableChanges.TableCode = priorTableStructure.TableVersionCode)
--  AND (zzTableChanges.ComponentCode = priorTableStructure.ComponentCode)
--  AND (zzTableChanges.ComponentTypeName = priorTableStructure.ComponentTypeName)
--WHERE
--  (((zzTableChanges.Change)='Delete')
--    AND ((qDPM_TableStructure_a.TableVersionCode) IS NULL)
--    AND ((IIf(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,
--          qmaxoftablevidbypredecessortaxonomy.maxoftablevid,
--          qmaxoftablevidbytaxonomy.maxoftablevid))=tableversion.tablevid)
--    AND ((priorTableStructure.TaxonomyCode) IS NULL
--      OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode))
--  OR (((zzTableChanges.Change)='Delete')
--    AND ((qDPM_TableStructure_a.TableVersionCode) IS NULL)
--    AND ((IIf(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,
--          qmaxoftablevidbypredecessortaxonomy.maxoftablevid,
--          qmaxoftablevidbytaxonomy.maxoftablevid)) IS NULL)
--    AND ((priorTableStructure.TaxonomyCode) IS NULL
--      OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode))
--ORDER BY
--  [tableversion].[TableVersionCode] & " - " & [TableVersionLabel],
--  zzTableChanges.ComponentTypeName,
--  Val([zzTableChanges].[ComponentCode]);

SELECT
    CONCAT(CAST (tableversion.TableVersionCode AS STRING), " - ", TableVersionLabel) AS TableCode,
    zzTableChanges.ComponentTypeName,
    zzTableChanges.ComponentCode,
    zzTableChanges.ComponentLabel,
    zzTableChanges.HeaderFlag,
    zzTableChanges.Level,
    --Val([zzTableChanges].[ComponentCode]) AS [Order],
    CAST (zzTableChanges.ComponentCode AS INT64) AS `Order`,
    zzTableChanges.LastChangedIn AS TaxonomyCode,
    CAST(NULL AS STRING) AS RestrictedToHierarchy, --casted to STRING to allow join on TableStructure_a
    CAST(NULL AS STRING) AS RootMember, --casted to STRING to allow join on TableStructure_a
    zzTableChanges.Change,
    zzTableChanges.LastChangedIn,
    priorTableStructure.DisplayBeforeChildren,
    priorTableStructure.OrdinateID,
    priorTableStructure.ParentOrdinateID,
FROM
    ((({{source('dpm_model', 'dpm_TableVersion')}} TableVersion
          INNER JOIN ({{ref('qDPM_TableStructure_a')}}
            RIGHT JOIN
              {{source('dpm_model', 'dpm_zzTableChanges')}} zzTableChanges
            ON
              (qDPM_TableStructure_a.TableVersionCode = zzTableChanges.TableCode)
              AND (qDPM_TableStructure_a.ComponentTypeName = zzTableChanges.ComponentTypeName)
              AND (qDPM_TableStructure_a.ComponentCode = zzTableChanges.ComponentCode)
              AND (qDPM_TableStructure_a.TaxonomyCode = zzTableChanges.LastChangedIn))
          ON
            TableVersion.TableVersionCode = zzTableChanges.TableCode)
        LEFT JOIN
          {{ref('qMaxOfTableVIDByTaxonomy')}} qMaxOfTableVIDByTaxonomy
        ON
          (zzTableChanges.TableCode = qMaxOfTableVIDByTaxonomy.TableVersionCode)
          AND (zzTableChanges.LastChangedIn = qMaxOfTableVIDByTaxonomy.TaxonomyCode))
      LEFT JOIN
        {{ref('qMaxOfTableVIDByPredecessorTaxonomy')}} qMaxOfTableVIDByPredecessorTaxonomy
      ON
        (zzTableChanges.TableCode = qMaxOfTableVIDByPredecessorTaxonomy.TableVersionCode)
        AND (zzTableChanges.LastChangedIn = qMaxOfTableVIDByPredecessorTaxonomy.TaxonomyCode))
    LEFT JOIN
      {{ref('qDPM_TableStructure_a')}} AS priorTableStructure
    ON
      (zzTableChanges.TableCode = priorTableStructure.TableVersionCode)
      AND (zzTableChanges.ComponentCode = priorTableStructure.ComponentCode)
      AND (zzTableChanges.ComponentTypeName = priorTableStructure.ComponentTypeName)
WHERE
  ((UPPER(zzTableChanges.Change)='DELETE')
    AND ((qDPM_TableStructure_a.TableVersionCode) IS NULL)
    AND ((IF(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,
          qmaxoftablevidbypredecessortaxonomy.maxoftablevid,
          qmaxoftablevidbytaxonomy.maxoftablevid))=tableversion.tablevid)
    AND ((priorTableStructure.TaxonomyCode) IS NULL
      OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode))
  OR ((UPPER(zzTableChanges.Change)='DELETE')
    AND ((qDPM_TableStructure_a.TableVersionCode) IS NULL)
    AND ((IF(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,
          qmaxoftablevidbypredecessortaxonomy.maxoftablevid,
          qmaxoftablevidbytaxonomy.maxoftablevid)) IS NULL)
    AND ((priorTableStructure.TaxonomyCode) IS NULL
      OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode))