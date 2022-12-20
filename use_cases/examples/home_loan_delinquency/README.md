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
* `deploy`: contains a Composer DAG which executes the end to end pipeline

## How to tailor the code to your need

If you wish to use this solution in a real implementation, you may want to start by tailoring the following files to 
your needs:
* `dbt/models/schema/yml`: moodify the sources to align to your data
* `dbt/models/src`: moodify the files in this folder to implement a mapping logic from your data into these structures