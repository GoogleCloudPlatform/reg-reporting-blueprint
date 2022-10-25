SELECT
    Taxonomy.TaxonomyCode,
    TaxonomyHistory.TaxonomyID,
    TaxonomyHistory.Replaces AS ReplacesTaxonomyID,
    Taxonomy_1.TaxonomyCode AS ReplacesTaxonomyCode,
    TableVersion.TableVersionCode,
    Max(TaxonomyTableVersion.TableVID) AS MaxOfTableVID
FROM
    {{source('dpm_model', 'dpm_TaxonomyHistory')}} TaxonomyHistory INNER JOIN
    {{source('dpm_model', 'dpm_Taxonomy')}} Taxonomy ON
        Taxonomy.TaxonomyID = TaxonomyHistory.TaxonomyID INNER JOIN
    {{source('dpm_model', 'dpm_Taxonomy')}} Taxonomy_1 ON
        Taxonomy_1.TaxonomyID = TaxonomyHistory.Replaces INNER JOIN
    {{source('dpm_model', 'dpm_TaxonomyTableVersion')}} TaxonomyTableVersion ON
        TaxonomyTableVersion.TaxonomyID = TaxonomyHistory.Replaces INNER JOIN
    {{source('dpm_model', 'dpm_TableVersion')}} TableVersion ON
        TableVersion.TableVID = TaxonomyTableVersion.TableVID
GROUP BY
    Taxonomy.TaxonomyCode,
    TaxonomyHistory.TaxonomyID,
    TaxonomyHistory.Replaces,
    Taxonomy_1.TaxonomyCode,
    TableVersion.TableVersionCode
