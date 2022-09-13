

  create or replace view `reg-reporting-360309`.`ebadpm_dev`.`my_second_dbt_model`
  OPTIONS()
  as -- Use the `ref` function to select from other models

select *
from `reg-reporting-360309`.`ebadpm_dev`.`my_first_dbt_model`
where id = 1;

