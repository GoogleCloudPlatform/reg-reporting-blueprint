SELECT
    qDPM_TableStructure_a.TableCode,
    qDPM_TableStructure_a.ComponentTypeName,
    qDPM_TableStructure_a.ComponentCode,
    qDPM_TableStructure_a.ComponentLabel,
    qDPM_TableStructure_a.HeaderFlag,
    qDPM_TableStructure_a.Level,
    qDPM_TableStructure_a.Order,
    qDPM_TableStructure_a.TaxonomyCode,
    qDPM_TableStructure_a.RestrictedToHierarchy,
    qDPM_TableStructure_a.RootMember,
    zzTableChanges.Change,
    zzTableChanges.LastChangedIn,
    qDPM_TableStructure_a.DisplayBeforeChildren,
    qDPM_TableStructure_a.OrdinateID,
    qDPM_TableStructure_a.ParentOrdinateID
FROM
      {{ref('qDPM_TableStructure_a')}} qDPM_TableStructure_a
    LEFT JOIN
      {{source('dpm_model', 'dpm_zzTableChanges')}} zzTableChanges
    ON
      (qDPM_TableStructure_a.TableVersionCode = zzTableChanges.TableCode)
      AND (qDPM_TableStructure_a.ComponentTypeName = zzTableChanges.ComponentTypeName)
      AND (qDPM_TableStructure_a.ComponentCode = zzTableChanges.ComponentCode)
      AND (qDPM_TableStructure_a.TaxonomyCode = zzTableChanges.LastChangedIn)
--ORDER BY
--    qDPM_TableStructure_a.TableCode,
--    qDPM_TableStructure_a.ComponentTypeName,
--    qDPM_TableStructure_a.Order
