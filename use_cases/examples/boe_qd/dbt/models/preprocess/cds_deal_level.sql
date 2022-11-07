{{ config(materialized='table') }}
SELECT
    *
FROM
{{ source('input_data', 'cds_deal_level_granular') }}