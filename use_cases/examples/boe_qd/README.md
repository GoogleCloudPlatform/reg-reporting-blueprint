# Example use case: Quarterly Derivatives

This folder contains an example of our Regulatory Reporting solution, built around the reporting requirements
for Quarterly Derivatives, as published by the Bank of England as part of the 
[Transforming the Data Collection programme](https://www.bankofengland.co.uk/news/2021/december/tdc-request-for-input-to-the-solution-design)

The Financial Derivatives return (Form DQ) is a high-level view of the value of the derivatives business done by UK banks. 
It is submitted quarterly to the Bank of England. 

This example contains the following folders: 
* `data_generator`: contains a simple containerised application that generates sample data
* `dbt`: contains a DBT project which specifies the source to report transformation
* `deploy`: an Airflow DAG that uploads the sample data and transforms it using DBT

# Pre-requisites
Make sure that you have followed the instructions in the [tutorial](../../../docs/TUTORIAL.md) to create the 
GCP infrastructure via Terraform.

# How to execute the demo
You can use the convenience script `run_demo.sh` to execute the demo.
```
./run_demo.sh
```
The script will do the following:
* Inialise the environment variables
* Create a containerised data generator application
* Create a containerised data transformation application
* Submit the DAG to Composer

## How to tailor the code to your need
If you wish to use this solution in a real implementation, you may want to start by tailoring the following files to 
your needs:
* `dbt/models/schema.yml`: moodify the sources to align to your data
* `dbt/models/preprocess`: moodify the files in this folder to implement a mapping logic from your data into these structures