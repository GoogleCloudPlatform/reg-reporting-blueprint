{{
  config(
    materialized='model',
    labels={},
    ml_config={
      'MODEL_TYPE': 'tensorflow',
      'MODEL_PATH': 'gs://' ~ env_var('GCS_INGEST_BUCKET', database.target ~ '-ingest-bucket') ~ '/models/homeloan/rwa/*',
    }
  )
}}

