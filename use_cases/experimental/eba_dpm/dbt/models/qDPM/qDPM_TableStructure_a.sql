-- SELECT
--   [TableVersionCode] & " - " & [TableVersionLabel] AS TableCode,
--   Switch([AxisOrientation]='X',
--     "Table column",
--     [AxisOrientation]='Y',
--     "Table row",
--     [AxisOrientation]="Z",
--     "Table sheet") AS ComponentTypeName,
--   AxisOrdinate.OrdinateCode AS ComponentCode,
--   AxisOrdinate.OrdinateLabel AS ComponentLabel,
--   Switch([IsAbstractHeader]=-1,
--     "True",
--     TRUE,
--     "False") AS HeaderFlag,
--   AxisOrdinate.Level,
--   AxisOrdinate.Order,
--   Taxonomy.TaxonomyCode,
--   IIf(IsNull(hierarchy.HierarchyCode),
--     hierarchy_1.hierarchycode,
--     hierarchy.HierarchyCode) AS RestrictedToHierarchy,
--   Switch([hierarchy].[hierarchycode] IS NULL,
--     Switch([hierarchy_1].[hierarchycode] IS NULL,
--       Null,
--       [openmemberrestriction_1].[IgnoreMemberID],
--       "all members",
--       [openmemberrestriction_1].[AllowsDefaultMember],
--       "allowed",
--       TRUE,
--       "not allowed"),
--     [openmemberrestriction].[AllowsDefaultMember],
--     "allowed",
--     TRUE,
--     "not allowed") AS RootMember,
--   TableVersion.TableVersionCode,
--   AxisOrdinate.DisplayBeforeChildren,
--   AxisOrdinate.OrdinateID,
--   AxisOrdinate.ParentOrdinateID
-- FROM
--   Taxonomy
-- INNER JOIN ((TableVersion
--     INNER JOIN ((Axis
--         INNER JOIN (Hierarchy AS Hierarchy_1
--           RIGHT JOIN (OpenMemberRestriction AS OpenMemberRestriction_1
--             RIGHT JOIN (AxisOrdinate
--               LEFT JOIN (
--                 SELECT
--                   *
--                 FROM
--                   ordinatecategorisation
--                 WHERE
--                   restrictionid IS NOT NULL) AS OrdinateCategorisation
--               ON
--                 AxisOrdinate.OrdinateID = OrdinateCategorisation.OrdinateID)
--             ON
--               OpenMemberRestriction_1.RestrictionID = OrdinateCategorisation.RestrictionID)
--           ON
--             Hierarchy_1.HierarchyID = OpenMemberRestriction_1.HierarchyID)
--         ON
--           Axis.AxisID = AxisOrdinate.AxisID)
--       LEFT JOIN ((OpenAxisValueRestriction
--           LEFT JOIN
--             openmemberrestriction
--           ON
--             OpenAxisValueRestriction.restrictionid = openmemberrestriction.restrictionid)
--         LEFT JOIN
--           Hierarchy
--         ON
--           openmemberrestriction.HierarchyID = Hierarchy.HierarchyID)
--       ON
--         Axis.AxisID = OpenAxisValueRestriction.AxisID)
--     ON
--       TableVersion.TableVID = Axis.TableVID)
--   INNER JOIN
--     TaxonomyTableVersion
--   ON
--     TableVersion.TableVID = TaxonomyTableVersion.TableVID)
-- ON
--   Taxonomy.TaxonomyID = TaxonomyTableVersion.TaxonomyID;

WITH OrdinateCategorisation AS (
                SELECT
                  *
                FROM
                  {{source('dpm_model', 'dpm_OrdinateCategorisation')}}
                WHERE
                  restrictionid IS NOT NULL)

SELECT
  CONCAT(CAST(TableVersionCode AS STRING), " - ", CAST(TableVersionLabel AS STRING)) AS TableCode,
  --Switch([AxisOrientation]='X',
  --  "Table column",
  --  [AxisOrientation]='Y',
  --  "Table row",
  --  [AxisOrientation]="Z",
  --  "Table sheet") AS ComponentTypeName,
  CASE
    WHEN AxisOrientation='X' THEN "Table column"
    WHEN AxisOrientation='Y' THEN "Table row"
    WHEN AxisOrientation='Z' THEN "Table sheet"
  END as ComponentTypeName,
  AxisOrdinate.OrdinateCode AS ComponentCode,
  AxisOrdinate.OrdinateLabel AS ComponentLabel,
  --Switch([IsAbstractHeader]=-1,
  --  "True",
  --  TRUE,
  --  "False") AS HeaderFlag,
  IF(IsAbstractHeader, True, False) as HeaderFlag, --set as a proper type, it's a string in the DPM
  AxisOrdinate.Level,
  AxisOrdinate.OrderKey as `Order`,
  Taxonomy.TaxonomyCode,
  --IIf(isnull(hierarchy.HierarchyCode),
  --  hierarchy_1.hierarchycode,
  --  hierarchy.HierarchyCode) AS RestrictedToHierarchy,
  IF(
    hierarchy.HierarchyCode is null,
    hierarchy_1.hierarchycode,
    hierarchy.HierarchyCode
  ) AS RestrictedToHierarchy,
  --switch([hierarchy].[hierarchycode] IS NULL,
  --  Switch([hierarchy_1].[hierarchycode] IS NULL,
  --    null,
  --    [openmemberrestriction_1].[IgnoreMemberID],
  --    "all members",
  --    [openmemberrestriction_1].[AllowsDefaultMember],
  --    "allowed",
  --    TRUE,
  --    "not allowed"),
  --  [openmemberrestriction].[AllowsDefaultMember],
  --  "allowed",
  --  TRUE,
  --  "not allowed") AS RootMember,
  CASE
    WHEN hierarchy.hierarchycode IS NULL THEN
        CASE
            WHEN hierarchy_1.hierarchycode IS NULL THEN null
            WHEN openmemberrestriction_1.IgnoreMemberID THEN "all members"
            WHEN openmemberrestriction_1.AllowsDefaultMember THEN "allowed"
            ELSE "not allowed"
        END
    WHEN openmemberrestriction.AllowsDefaultMember THEN "allowed"
    ELSE "not allowed"
  END as RootMember,
  TableVersion.TableVersionCode,
  AxisOrdinate.DisplayBeforeChildren,
  AxisOrdinate.OrdinateID,
  AxisOrdinate.ParentOrdinateID
FROM
 {{source('dpm_model', 'dpm_Axis')}}                        Axis                        JOIN
 {{source('dpm_model', 'dpm_AxisOrdinate')}}                AxisOrdinate                ON Axis.AxisID = AxisOrdinate.AxisID LEFT JOIN
                                                            OrdinateCategorisation      ON AxisOrdinate.OrdinateID = OrdinateCategorisation.OrdinateID LEFT JOIN
 {{source('dpm_model', 'dpm_OpenMemberRestriction')}}       OpenMemberRestriction_1     ON OpenMemberRestriction_1.RestrictionID = OrdinateCategorisation.RestrictionID LEFT JOIN
 {{source('dpm_model', 'dpm_Hierarchy')}}                   Hierarchy_1                 ON Hierarchy_1.HierarchyID = OpenMemberRestriction_1.HierarchyID LEFT JOIN
 {{source('dpm_model', 'dpm_OpenAxisValueRestriction')}}    OpenAxisValueRestriction    ON Axis.AxisID = OpenAxisValueRestriction.AxisID LEFT JOIN
 {{source('dpm_model', 'dpm_OpenMemberRestriction')}}       openmemberrestriction       ON OpenAxisValueRestriction.restrictionid = openmemberrestriction.restrictionid LEFT JOIN
 {{source('dpm_model', 'dpm_Hierarchy')}}                   Hierarchy                   ON openmemberrestriction.HierarchyID = Hierarchy.HierarchyID JOIN
 {{source('dpm_model', 'dpm_TableVersion')}}                TableVersion                ON TableVersion.TableVID = Axis.TableVID JOIN
 {{source('dpm_model', 'dpm_TaxonomyTableVersion')}}        TaxonomyTableVersion        ON TableVersion.TableVID = TaxonomyTableVersion.TableVID JOIN
 {{source('dpm_model', 'dpm_Taxonomy')}}                    Taxonomy                    ON Taxonomy.TaxonomyID = TaxonomyTableVersion.TaxonomyID
