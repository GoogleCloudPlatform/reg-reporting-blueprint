SELECT
    Taxonomy.TaxonomyID,
    Taxonomy.TaxonomyCode,
    TableVersion.TableVersionCode,
    Max(TableVersion.TableVID) AS MaxOfTableVID
FROM
    {{source('dpm_model', 'dpm_TableVersion')}} TableVersion INNER JOIN
    {{source('dpm_model', 'dpm_TaxonomyTableVersion')}} TaxonomyTableVersion ON
        TableVersion.TableVID = TaxonomyTableVersion.TableVID INNER JOIN
    {{source('dpm_model', 'dpm_Taxonomy')}} Taxonomy ON
        Taxonomy.TaxonomyID = TaxonomyTableVersion.TaxonomyID
GROUP BY
    Taxonomy.TaxonomyID,
    Taxonomy.TaxonomyCode,
    TableVersion.TableVersionCode
