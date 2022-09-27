# Example use case: Flashing Detection

This folder contains an example reporting solution for detection of Flashing activity on a stock market.
Flashing in a financial market is a type of <a href="https://en.wikipedia.org/wiki/Spoofing_(finance)">Spoofing</a>
market manipulation in which participants exhibit a patten of submitting orders that are not intended to be fulfilled, but rather only to move ("improve") the market to benefit a subsequent order on the other side of the market. The "flashed" orders are short lived orders, which are canceled quickly after being entered and prior to getting executed. In the world of High Frequency Trading, these types of operations are done through algorithmic trading systems and typically happen within milliseconds or microseconds.

The code herein is designed to use the power of BigQuery to effortlessly scale these complex analytics to terabytes or beyond of data with no additional operational overhead.

This example was built in collaboration between Google, <a href="https://gtsx.com">GTS Securities LLC</a> and its
technology provider, Strike Technologies LLC.

This example contains the following folders:
* `data`: contains an [example schema codified in Terraform](./data/schema/example.tf), as well as a Python script to generate sample data within that schema. This data is composed of two datasets:
    * market_data
        * Simulate the *public* NBBO market data feed disseminated by the exchanges
    * order_data
        * Simulate the *proprietary* order activity of the market participant under review
* `dbt`: contains a DBT project which specifies the source to report transformations

This example has the following objectives:
- Create infrastructure using terraform
- Generate sample market and NBBO data using python scripts
- Load manufactured data into BigQuery
- Extract regulatory metrics from granular data using BigQuery SQL Analytics
- Containerize the extraction pipeline
- Aggregation of data into reports

## How to run this example as-is

This example uses the following billable components of Google Cloud:

- BigQuery
- Cloud Storage
- Optionally, GKE, Cloud Composer

To generate a cost estimate based on your projected usage, use the pricing calculator.
When you finish this tutorial, you can avoid continued billing by deleting the resources you created. For more information, see Clean up.


## Steps to set up the environment

1. Configure the environment in your google cloud project, following the installation steps 1-10 given [here](https://cloud.google.com/architecture/set-up-regulatory-reporting-architecture-bigquery).

2. Once the setup scripts are executed from the previous step, run the following commands in your cloud shell:

---
    $ cd use_cases/examples/flashing_detection/data/schema

    $ terraform init -upgrade

    $ terraform plan

    $ terraform apply

---

Type **yes** when you see the confirmation prompt.

To verify that an ingest bucket has been created, in the Google Cloud console, go to the Cloud Storage page and check for a bucket with a name that's similar to the value of PROJECT ID.

3. Go to the BigQuery page and verify that the following datasets have been created:

- market_data
- order_data

## Upload the sample data
In this section, you explore the contents of the repository's data and generation folders, and load sample data to BigQuery. For additional details regarding the data generation tool and upload steps, see [data generation](./data/generation/README.md).

4. In the Cloud Shell Editor instance, navigate to the generation folder in the repository and run the following commands.

Note that the data generation tool depends on numpy and pandas. It is recommended to install them under a virtual environment.

```bash
  $ cd use_cases/examples/flashing_detection/data/generation

  $ pip3 install numpy pandas

  $ python3 datagen.py --date 2022-08-15 --symbol ABC --output_dir /tmp

  $ gsutil cp \
    /tmp/market_data_2022-08-15_ABC.csv \
    /tmp/orders_log_2022-08-15_ABC.csv \
    gs://$GCS_INGEST_BUCKET


  $ bq load \
    --source_format=CSV --skip_leading_rows=1 \
    $PROJECT_ID:$TF_VAR_FLASHING_BQ_MARKET_DATA.nbbo \
    gs://$GCS_INGEST_BUCKET/market_data_2022-08-15_ABC.csv


  $ bq load \
    --source_format=CSV --skip_leading_rows=1 \
    $PROJECT_ID:$TF_VAR_FLASHING_BQ_ORDER_DATA.orders \
    gs://$GCS_INGEST_BUCKET/orders_log_2022-08-15_ABC.csv
```


5. To verify that the data has been loaded in BigQuery, in the Google Cloud console, go to the BigQuery page and select a table in both the market_data and order_data datasets.

Select the Preview tab for each table and confirm that each table has data.

6. Once the above steps are completed, run the regulatory reporting pipeline following the steps [here](https://cloud.google.com/architecture/set-up-regulatory-reporting-architecture-bigquery#run_the_regulatory_reporting_pipeline).


## Customize the datasets per your requirements

To run this example, first modify (at a minimum) the following properties in [environment-variables.sh](../../../environment-variables.sh):
* TF_VAR_FLASHING_BQ_MARKET_DATA - set this to be the name of the dataset in which you will store market data
* TF_VAR_FLASHING_BQ_ORDER_DATA - set this to be the name of the dataset in which you will store order data
* PROJECT_ID - the Google Cloud project in which you will create and store your market data and the flashing detection models. **Note:** By default it will choose the output of `gcloud config get-value project`

Then, [create and export service account credentials](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) for a service account with permissions to create datasets, views, and tables within the specified project.
Please consider the principle of least privilege in creating and securing the service account credentials file. [More information available here](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys).

Lastly, set the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to the service account credentials keyfile. e.g., `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/keyfile.json`

## How to tailor the infrastructure code to your needs

If you wish to use this solution for your implementation, you may want to start by tailoring the following files to your needs:
1. [reg-reporting-blueprint/environment-variables.sh](../../../environment-variables.sh) - Contains various environment setup variables subsequently used by Terraform and DBT
2. [reg-reporting-blueprint/use_cases/examples/flashing_detection/data/schema/example.tf](./data/schema/example.tf) - Contains sample schemata for datasets and tables for market data and orders
3. reg-reporting-blueprint/use_cases/examples/flashing_detection/dbt/models/*.yml and *.sql - `*.sql` contains the definition of the models that lead us to finding the flashing events, while `*.yml` defines the description and constraints on the fields therein.