# Example use case: Flashing Detection

This folder contains an example reporting solution for detection of Flashing activity on a stock market.
Flashing in a financial market is a type of <a href="https://en.wikipedia.org/wiki/Spoofing_(finance)">Spoofing</a>
market manipulation in which participants exhibit a pattern of submitting orders that are not intended to be fulfilled, but rather only to move ("improve") the market to benefit a subsequent order on the other side of the market. The "flashed" orders are short lived orders, which are canceled quickly after being entered and prior to getting executed. In the world of High Frequency Trading, these types of operations are done through algorithmic trading systems and typically happen within milliseconds or microseconds.

The code herein is designed to use the power of BigQuery to effortlessly scale these complex analytics to terabytes or beyond of data with no additional operational overhead.

This example was built in collaboration between Google, <a href="https://gtsx.com">GTS Securities LLC</a> and its
technology provider, Strike Technologies LLC.

This example contains the following folders:
* `data_generator`: contains a Python script that generates sample data within a predefined schema. This data is composed of two tables:
    * market_data
        * Simulate the *public* NBBO market data feed disseminated by the exchanges
    * order_data
        * Simulate the *proprietary* order activity of the market participant under review
* `dbt`: contains a DBT project which specifies the source to report transformations

This example has the following objectives:
- Generate sample market and NBBO data using python scripts
- Load manufactured data into BigQuery
- Extract regulatory metrics from granular data using BigQuery SQL Analytics
- Aggregation of data into reports
- Containerize the extraction pipeline

## How to run this example as-is

This example uses the following billable components of Google Cloud:

- BigQuery
- Cloud Storage
- Optionally, GKE, Cloud Composer

To generate a cost estimate based on your projected usage, use the pricing calculator.
When you finish this tutorial, you can avoid continued billing by deleting the resources you created. For more information, see Clean up.


## Steps to set up the environment

1. Configure the environment in your google cloud project, following the installation steps 1-10 given [here](https://cloud.google.com/architecture/set-up-regulatory-reporting-architecture-bigquery).

1. Make sure that the infrastructure has been created in terraform, using the common components. 
This example relies on a `regrepo_source` dataset in BigQuery, and optionally a Composer instance
if you plan to run this example on a schedule.  

## Generate the sample data
In this section, you explore the contents of the repository's data generation folder, and load sample data to BigQuery. For additional details regarding the data generation tool and upload steps, see [data generation](./data_generator/README.md).

1. In the Cloud Shell Editor instance, navigate to the generation folder in the repository and run the following commands.

Note that the data generation tool depends on numpy and pandas. It is recommended to install them under a virtual environment.

```bash
  $ cd use_cases/examples/flashing_detection/data_generator

  $ python3 -m pip install -r requirements.txt
  
  $ python3 datagen.py --project_id $PROJECT_ID --bq_dataset regrep_source --date 2022-08-15 --symbol ABC
```

1. To verify that the data has been loaded in BigQuery, in the Google Cloud console, go to the BigQuery page and verify that the `regrep_source` dataset contains the `flashing_nbbo` and `flashing_orders` tables.

Select the Preview tab for each table and confirm that each table has data.

1. Once the above steps are completed, run the regulatory reporting pipeline following the steps below:
```bash
  $ cd ../dbt
  $ dbt deps
  $ dbt run
```


## Customize the datasets per your requirements

To run this example, first modify (at a minimum) the following properties in [environment-variables.sh](../../../environment-variables.sh):
* PROJECT_ID - the Google Cloud project in which you will create and store your market data and the flashing detection models. **Note:** By default it will choose the output of `gcloud config get-value project`

Then, [create and export service account credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) for a service account with permissions to create datasets, views, and tables within the specified project.
Please consider the principle of least privilege in creating and securing the service account credentials file. [More information available here](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys).

Lastly, set the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to the service account credentials keyfile. e.g., `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/keyfile.json`

## How to tailor the infrastructure code to your needs

If you wish to use this solution for your implementation, you may want to start by tailoring the following files to your needs:
1. [reg-reporting-blueprint/environment-variables.sh](../../../environment-variables.sh) - Contains various environment setup variables subsequently used by Terraform and DBT
2. [reg-reporting-blueprint/use_cases/examples/flashing_detection/data_generator_](./data_generator) - Contains a data generation script using sample schemata for datasets and tables for market data and orders
3. reg-reporting-blueprint/use_cases/examples/flashing_detection/dbt/models/*.yml and *.sql - `*.sql` contains the definition of the models that lead us to finding the flashing events, while `*.yml` defines the description and constraints on the fields therein.

## (Optional) Package the application in containers and run them in Composer

The convenience script `run_demo.sh` will package the `data_generator` and `dbt` code in containers,
upload them to GCP, and upload a Composer DAG which will execute the data generation and transformations 
on a schedule.
