# Credit Modelling Example

## Installation setups

### Source the environment variables 

```
source ../../../environment-variables.sh
```

### Create the financial_data (for external data) dataset

```
bq mk --data_location=${BQ_LOCATION} --project_id=${PROJECT_ID} financial_data
```

### Download the data

Download and copy the data into a GCS bucket:
```
cd data_load
download.sh
```

Check the data:
```
ls -l rating_data
ls -l sec_data
gsutil ls -l gs://${GCS_INGEST_BUCKET}/
```

Return to use case directory:
```
cd ..
```

You should see all of the data in the buckets and locally.

Optionally delete the downloaded data:
```
rm -rf sec_data rating_data
```

### Initialize and run DBT

Start using dbt:
```
cd dbt
```

Update dependencies:
```
dbt deps
```

Stage external tables:
```
dbt run-operation stage_external_sources --vars 'ext_full_refresh: true'
```

## Running DBT

### Data preparation
Execute the data transformations that create the basic training data set.
```
dbt run -m +tag:modelling
```

### Univariate analysis
Analise the predictive power of the basic features against the label.

First, make sure the documentation JSON file is generated, as this is required to create the univariate 
analysis script.
```
dbt docs generate
```

Then, run this scrip to generate a BQML model running a logistic regression for each feature.
```
python3 generate_metrics_uv_eval.py
```

Now, run the univariate analysis for all the features
```
dbt run -m tag:uv_eval
```
