

  create or replace table `reg-reporting-360309`.`ebadpm_dev_ebapdm_data`.`DataType`
  
  
  OPTIONS()
  as (
    SELECT * FROM `scannell-fsi-dev`.`dpm_model`.`v3_2_DataType`
  );
  