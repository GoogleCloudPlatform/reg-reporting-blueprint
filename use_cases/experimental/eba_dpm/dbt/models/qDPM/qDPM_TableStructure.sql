SELECT
    *
FROM (
    SELECT
        qDPM_TableStructure_WithEditsMarked.TableCode,
        qDPM_TableStructure_WithEditsMarked.ComponentTypeName,
        qDPM_TableStructure_WithEditsMarked.ComponentCode,
        qDPM_TableStructure_WithEditsMarked.ComponentLabel,
        qDPM_TableStructure_WithEditsMarked.HeaderFlag,
        qDPM_TableStructure_WithEditsMarked.Level,
        qDPM_TableStructure_WithEditsMarked.Order,
        qDPM_TableStructure_WithEditsMarked.TaxonomyCode,
        qDPM_TableStructure_WithEditsMarked.RestrictedToHierarchy,
        qDPM_TableStructure_WithEditsMarked.RootMember,
        qDPM_TableStructure_WithEditsMarked.Change,
        qDPM_TableStructure_WithEditsMarked.LastChangedIn,
        qDPM_TableStructure_WithEditsMarked.DisplayBeforeChildren,
        qDPM_TableStructure_WithEditsMarked.OrdinateID,
        qDPM_TableStructure_WithEditsMarked.ParentOrdinateID,
    FROM
        {{ref('qDPM_TableStructure_WithEditsMarked')}} qDPM_TableStructure_WithEditsMarked

    UNION ALL

    SELECT
        qDPM_TableStructure_Deletions.TableCode,
        qDPM_TableStructure_Deletions.ComponentTypeName,
        qDPM_TableStructure_Deletions.ComponentCode,
        qDPM_TableStructure_Deletions.ComponentLabel,
        qDPM_TableStructure_Deletions.HeaderFlag,
        qDPM_TableStructure_Deletions.Level,
        qDPM_TableStructure_Deletions.Order,
        qDPM_TableStructure_Deletions.TaxonomyCode,
        qDPM_TableStructure_Deletions.RestrictedToHierarchy,
        qDPM_TableStructure_Deletions.RootMember,
        qDPM_TableStructure_Deletions.Change,
        qDPM_TableStructure_Deletions.LastChangedIn,
        qDPM_TableStructure_Deletions.DisplayBeforeChildren,
        qDPM_TableStructure_Deletions.OrdinateID,
        qDPM_TableStructure_Deletions.ParentOrdinateID,
    FROM
        {{ref('qDPM_TableStructure_Deletions')}} qDPM_TableStructure_Deletions
)  AS table_structure
--ORDER BY
--    TableCode,
--    ComponentTypeName,
--    `Order`
