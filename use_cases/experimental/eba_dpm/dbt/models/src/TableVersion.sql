SELECT
    * EXCEPT(FromDate, ToDate)  --todo: bug in the field format of the source data
FROM
    {{ source('dpm_model', 'v3_2_TableVersion') }}