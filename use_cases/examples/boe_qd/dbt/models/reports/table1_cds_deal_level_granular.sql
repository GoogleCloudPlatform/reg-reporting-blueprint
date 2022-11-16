{{ config(materialized='table') }}
SELECT *
FROM {{ ref('cds_deal_level') }}