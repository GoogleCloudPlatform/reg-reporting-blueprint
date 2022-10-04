{{
    dbt_ml_helpers.train_test_split(
        base_model='submissions',
        train_split_pct=var('train_split_pct'),
        lst_column_ids="adsh,cik,period"
    )
}}