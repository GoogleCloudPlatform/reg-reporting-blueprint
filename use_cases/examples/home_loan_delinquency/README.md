# Example use case: Home Loan Delinquency

This folder contains an example of our Regulatory Reporting solution, built around a Home Loan Delinquency use case.

The Home Loan Delinquency use case aims to classify a portfolio of loans into buckets which determine the banding for 
the days delinquency.
This is a very simple example of a classification that may be required for reporting purposes, and is used to 
demonstrate the key features and capabilities of the solution.

This example contains the following folders:
* `data`: contains test data
* `data_load`: contains a simple containerised application to load data from GCS into BQ
* `dbt`: contains a DBT project which specifies the source to report transformation
<<<<<<< HEAD
* `model_load`: contains a Python script to save a Tensorflow model to GCS
=======
* `deploy`: contains a Composer DAG which executes the end to end pipeline
>>>>>>> main

## How to tailor the code to your need

If you wish to use this solution in a real implementation, you may want to start by tailoring the following files to 
your needs:
* `dbt/models/schema/yml`: moodify the sources to align to your data
* `dbt/models/src`: moodify the files in this folder to implement a mapping logic from your data into these structures

## Running RWA Calculations

Some example RWA calculations are included. These are designed to demonstrate
statistical calculations in PySpark and Tensorflow, and the RWA calculation may
not be correct.

### Tensorflow

Enter the model_load directory and save the RWA Tensorflow Model to GCS:

```bash
cd model_load
python3 rwa_model.py
cd ..
```

The model will be loaded into BigQuery and executed by DBT.

### PySpark

* Enable the Dataproc API.
* Inspect dbt/profiles/profile.yml. This should be changed if you want to use
  Dataproc, rather than Dataproc Serverless.
* Grant the default compute service account to the homeloan_dev dataset.
  (By default, this doesn't happen.)
* Ensure the subnet used by Dataproc (likely the default network) has Google
  Private Access enabled.

### Running

RWA models are disabled by default. This will run the DBT models (by tag), and
also enable them.

```
dbt run --var '{"enable_rwa":True}' --select tag:rwa
```

