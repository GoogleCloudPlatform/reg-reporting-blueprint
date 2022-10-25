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
    Null AS RestrictedToHierarchy,
    Null AS RootMember,
    zzTableChanges.Change,
    zzTableChanges.LastChangedIn,
    priorTableStructure.DisplayBeforeChildren,
    priorTableStructure.OrdinateID,
    priorTableStructure.ParentOrdinateID,
FROM
    {{source('dpm_model', 'dpm_zzTableChanges')}} zzTableChanges LEFT JOIN
    {{ref('qDPM_TableStructure_a')}} qDPM_TableStructure_a ON
        qDPM_TableStructure_a.TableVersionCode = zzTableChanges.TableCode AND
        qDPM_TableStructure_a.ComponentTypeName = zzTableChanges.ComponentTypeName AND
        qDPM_TableStructure_a.ComponentCode = zzTableChanges.ComponentCode AND
        qDPM_TableStructure_a.TaxonomyCode = zzTableChanges.LastChangedIn LEFT JOIN
   {{ref('qDPM_TableStructure_a')}} priorTableStructure ON
        zzTableChanges.TableCode = priorTableStructure.TableVersionCode AND
        zzTableChanges.ComponentCode = priorTableStructure.ComponentCode AND
        zzTableChanges.ComponentTypeName = priorTableStructure.ComponentTypeName LEFT JOIN
   {{ref('qMaxOfTableVIDByTaxonomy')}} qMaxOfTableVIDByTaxonomy ON
        zzTableChanges.TableCode = qMaxOfTableVIDByTaxonomy.TableVersionCode AND
        zzTableChanges.LastChangedIn = qMaxOfTableVIDByTaxonomy.TaxonomyCode LEFT JOIN
   {{ref('qMaxOfTableVIDByPredecessorTaxonomy')}} qMaxOfTableVIDByPredecessorTaxonomy ON
        zzTableChanges.TableCode = qMaxOfTableVIDByPredecessorTaxonomy.TableVersionCode AND
        zzTableChanges.LastChangedIn = qMaxOfTableVIDByPredecessorTaxonomy.TaxonomyCode JOIN
   {{source('dpm_model', 'dpm_TableVersion')}} TableVersion ON
        TableVersion.TableVersionCode = zzTableChanges.TableCode
WHERE
    (zzTableChanges.Change)='Delete' AND
    ((qDPM_TableStructure_a.TableVersionCode) IS NULL) And
    ((IF(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,qmaxoftablevidbypredecessortaxonomy.maxoftablevid,qmaxoftablevidbytaxonomy.maxoftablevid))=tableversion.tablevid) AND
    ((priorTableStructure.TaxonomyCode) IS NULL OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode) OR (((zzTableChanges.Change)='Delete') AND
    ((qDPM_TableStructure_a.TableVersionCode) IS NULL) AND
    ((IF(qmaxoftablevidbytaxonomy.maxoftablevid IS NULL,qmaxoftablevidbypredecessortaxonomy.maxoftablevid,qmaxoftablevidbytaxonomy.maxoftablevid)) IS NULL) AND
    ((priorTableStructure.TaxonomyCode) IS NULL OR (priorTableStructure.TaxonomyCode)=qMaxOfTableVIDByPredecessorTaxonomy.ReplacesTaxonomyCode))