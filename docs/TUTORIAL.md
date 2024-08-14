# Standing Up a Cloud-Native Regulatory Reporting Architecture with BigQuery

## Table of contents
- [Introduction](#introduction)
- [Objectives](#objectives)
- [Costs](#costs)
- [Before you begin](#before-you-begin)
- [Prepare your environment](#prepare-your-environment)
- [Upload the sample data](#upload-the-sample-data)
- [Run the regulatory reporting pipeline](#run-the-regulatory-reporting-pipeline)
- [(Optional) Containerize the transformations](#optional-containerize-the-transformations)
- [Clean up](#clean-up)
- [Delete the individual resources](#delete-the-individual-resources)
- [What's next](#whats-next)


## Introduction
This document shows you how to get started with a regulatory
reporting solution for cloud and run a basic pipeline. It's intended for data engineers
in financial institutions who want to familiarize themselves with an architecture
and best practices for producing stable, reliable regulatory reports.

In this tutorial, you establish a working example of a regulatory data
processing platform on Google Cloud resources. The example platform demonstrates
how you can implement a data processing pipeline that maintains quality of data,
auditability, and ease of change and deployment and also meets the following
requirements of regulatory reporting:

-   Ingestion of data from source
-   Processing of large volumes of granular data
-   Aggregation of data into reports.

This document assumes that you're familiar with Terraform version 1.1.7, data
build tool (dbt) version 1.0.4, GCS, and BigQuery.
------
## Objectives
-   Create infrastructure from a cloned repository.
-   Load manufactured data into Big Query.
-   Extract regulatory metrics from granular data.
-   Containerize the extraction pipeline.

----
## Costs
This tutorial uses the following billable components of  Google Cloud :

- [BigQuery](https://cloud.google.com/bigquery/pricing)
- [Cloud Storage](https://cloud.google.com/storage/pricing)
- [Optionally, Cloud Composer](https://cloud.google.com/composer/pricing)

To generate a cost estimate based on your projected usage, use the 
[pricing calculator](https://cloud.google.com/products/calculator).

When you finish this tutorial, you can avoid continued billing by deleting the 
resources you created. For more information, see 
[Clean up](https://cloud.google.com/architecture/set-up-regulatory-reporting-architecture-bigquery#clean-up).

-----
## Before you begin
In the Google Cloud console, on the project selector page, select or 
[create a Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

Note: If you don't plan to keep the resources that you create in this procedure, create a project instead of selecting an existing project. After you finish these steps, you can delete the project, removing all resources associated with the project.

 * [Go to project selector](https://pantheon.corp.google.com/projectselector2/home/dashboard)

Make sure that billing is enabled for your Cloud project. L
earn how to [check if billing is enabled on a project](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled).

In the Google Cloud console, activate Cloud Shell.

 * [Activate Cloud Shell](https://console.cloud.google.com/?cloudshell=true&_ga=2.175791653.601714487.1648649282-1707141935.1648504534)


## Prepare your environment

1.  In Cloud Shell, specify the project that you want to use for this tutorial:

    ```
    gcloud config set project PROJECT_ID
    ```

    Replace `PROJECT_ID` with the ID of the project that
    you selected or created for this tutorial.

    If a dialog displays, click **Authorize**.

1.  Specify a default region to use for infrastructure creation:

	     gcloud config set compute/region REGION

1.  Create and activate a Python virtual environment:

    ```
    python -m venv reg-rpt-env
    source reg-rpt-env/bin/activate
    ```

    You see that your command-line prompt is prefixed with the name of the
    virtual environment.

1.  Clone the repository:

    ```
    git clone \
    "https://github.com/GoogleCloudPlatform/reg-reporting-blueprint"
    ```

1.  Install Terraform. To learn how to do this installation, see the
    [HashiCorp documentation](https://learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform).

1.  [Verify](https://learn.hashicorp.com/tutorials/terraform/install-cli#verify-the-installation)
    the installation.
1.  Install dbt:

        pip3 install dbt-bigquery --upgrade

1.   Verify the dbt installation:

         dbt --version

     You see the installation details displayed.

1.  Initialize the environment variables:

    ```
    cd reg-reporting-blueprint && source environment-variables.sh
    ```

1.  Run the setup script:

    ```
    cd common_components && ./setup_script.sh
    ```

1.  Enable the Service Usage API and Resource Manager API:

    ```
    gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com
    ```

1.  Run terraform to create the required infrastructure:

    NOTE: The APIs in the previous step sometimes take a while to enable, so it may not
    work the first few times.

    ```
    cd orchestration/infrastructure/
    terraform init -upgrade
    terraform plan
    terraform apply
    ```
    Type 'yes' when you see the confirmation prompt.

1.  To verify that an ingest bucket has been created, in the Google Cloud console,
    go to the **Cloud Storage** page and check for a bucket with a name
    that's similar to the value of `PROJECT ID`.
    
1.  Go to the **BigQuery** page and verify that the following
    datasets have been created:

    ```
    regrep
    regrep_source
    ```

## Upload the sample data

In this section, you explore the contents of the repository's `data` and
`data_load` folders, and load sample data to BigQuery.

1.  In the Cloud Shell Editor instance, navigate to the `data` folder in
    the repository:

    ```
    cd ../../../use_cases/examples/home_loan_delinquency/data/
    ```

    This folder contains two subfolders which are named `input` and `expected`.

    Inspect the contents of the `input` folder. This folder contains CSV
    files with sample input data. This sample data is provided only for test
    purposes.

    Inspect the contents of the `expected` folder. This folder contains the
    CSV files specifying the expected results once the transformations are applied.

1.  Open, and inspect, the `data_load/schema` folder, which contains
    files specifying the schema of the staging data:

    ```
    cd ../data_load
    ```
    The scripts in this folder allow the data to be loaded into
    Cloud Storage first, and then into BigQuery. The data
    conforms to the expected schema for the example regulatory reporting pipeline
    use case in this tutorial.

1.  Load the data into Cloud Storage:

    ```
    ./load_to_gcs.sh ../data/input
    ./load_to_gcs.sh ../data/expected
    ```

    The data is now available in your Cloud Storage ingest bucket.

1.  Load the data from the Cloud Storage ingest bucket to
    BigQuery:

    ```
    ./load_to_bq.sh
    ```

1.  To verify that the data has been loaded in BigQuery, in
    the Google Cloud console, go to the BigQuery page and
    select a table in the `regrep_source` dataset and open
    a table starting with `homeloan_ref` and
    starting with `homeloan_expected`.

    Select the **Preview** tab for each table, and confirm that each table has
    data.

### Run the regulatory reporting pipeline

1.  In your development environment, initialize the dependencies of dbt:
    
    ```
    cd ../dbt/
    dbt deps
    ```

    This will install any needed dbt dependencies in your dbt project.

1.  Test the connection between your local dbt installation and your
    BigQuery datasets:

    ```
    dbt debug
    ```

    At the end of the connectivity, configuration, and dependency information
    returned by the command, you should see the following message: `All checks passed!`

    In the `models` folder, open a SQL file and inspect the logic of the
    sample reporting transformations implemented in dbt.

1.  Run the reporting transformations to create the regulatory
    reporting metrics:

    ```
    dbt run
    ```

1.  Run the transformations for a date of your choice:

    ```
    dbt run --vars '{"reporting_day": "2021-09-03"}'
    ```
    Notice the variables that control the execution of the transformations.
    The variable `reporting_day` indicates the date value that the portfolio
    should have. When you run the `dbt run` command, it's a best practice to provide
    this value.

1.  In the Google Cloud console, go to the **BigQuery** page
    and inspect the `homeloan_dev` dataset. Notice how the data has been
    populated, and how the `reporting_day` variable that you passed is used in
    the **`control.reporting_day`** field of the `wh_denormalised` view.

1.  Inspect the `models/schema.yml` file:

    ```
    models:
     - <<: *src_current_accounts_attributes
       name: src_current_accounts_attributes
       columns:
         - name: ACCOUNT_KEY
           tests:
             - unique
                  - not_null
    ```
    Notice how the file defines the definitions of the columns and the associated
    data quality tests. For example,  the **`ACCOUNT_KEY`** field in the
    `src_current_accounts_attributes` table must be unique and not null.

1.  Run the data quality tests that are specified in the config files:

    ```
    dbt test -s test_type:generic
    ```

1.  Inspect the code in the `use_cases/examples/home_loan_delinquency/dbt/tests`
    folder, which contains `singular` tests. Notice that the tests in this folder
    implement a table comparison between the actual results that are output by the
    `dbt run` command, and the expected results that are saved in the `homeloan_expectedresults`
    dataset.

1.  Run the singular tests:

    ```
    dbt test -s test_type:singular
    ```

1.  Generate the documentation for the project:

    ```
    dbt docs generate && dbt docs serve
    ```
1.  In the output that you see, search for, and then click, the following URL
    text: `http://127.0.0.1:8080`

    Your browser opens a new tab that shows the dbt documentation web interface.

1.  Inspect the lineage of the models and their documentation. You see that the 
    documentation includes all of the code and the documentation for the models
    (as specified in the `models/schema.yml` files).
    
1.  In Cloud Shell, enter the following:

	    Ctrl + c

	  Cloud Shell stops hosting the dbt web interface.

## Optional: Containerize the transformations

1.  In Cloud Shell, create containers for data load and DBT and push the container to 
    Artifact Repository:

    ```
    cd ../../../../  # the gcloud command should be executed from the root 
    gcloud builds submit \
      --config use_cases/examples/home_loan_delinquency/cloudbuild.yaml \
      --substitutions "_SOURCE_URL=${SOURCE_URL},_REGISTRY_URL=${REGISTRY_URL},COMMIT_SHA=main" \
      --service-account projects/${PROJECT_ID}/serviceAccounts/builder@${PROJECT_ID}.iam.gserviceaccount.com \
      --gcs-source-staging-dir gs://${PROJECT_ID}-cloudbuild-source-staging-bucket/source
    ```
    The Dockerfile in the `dbt` and `data_load` directories enables containerization, which
    simplifies orchestration of the workflow.

1.  Retrieve the path of the Airflow page and the **Cloud Storage** bucket for dags, 
    and store them in environment variables:

    ```
    cd common_components/orchestration/infrastructure/ 
    AIRFLOW_DAG_GCS=$(terraform output --raw airflow_dag_gcs_prefix)
    AIRFLOW_UI=$(terraform output --raw airflow_uri)
    ```

1.  Upload the home loan delinquency dag:

    ```
    cd ../../../use_cases/examples/home_loan_delinquency/deploy/
    gsutil cp run_homeloan_dag.py $AIRFLOW_DAG_GCS
    ```
   
1.  Go to the Airflow page by executing the following 
    command to retrieve the UI, and clicking on the link:

    ```
    echo $AIRFLOW_UI
    ```

## Optional: Setup the Operations Dashboard

1.   From the root of the repository find out the Looker Studio template dashboard URL:

     ```
     echo "Operations Dashboard: $(cd common_components/orchestration/infrastructure; terraform output --raw lookerstudio_operations_dashboard_url)"
     ```

     Click on the URL in the terminal and investigate the dashboard. Edit and share if you want to keep and evolve the dashboard.

## Optional: Repeat for all the use cases

1.   Use a shell that has the environment variables set. Ensure that
     you have run the following in the root of the repository:
     ```
     source environment-variables.sh
     ```

1.   Build all of the use cases.
     ```
     for build in use_cases/examples/*/cloudbuild.yaml ; do
        gcloud builds submit \
          --config $build \
          --substitutions "_SOURCE_URL=${SOURCE_URL},_REGISTRY_URL=${REGISTRY_URL},COMMIT_SHA=main" \
          --service-account projects/${PROJECT_ID}/serviceAccounts/builder@${PROJECT_ID}.iam.gserviceaccount.com \
          --gcs-source-staging-dir gs://${PROJECT_ID}-cloudbuild-source-staging-bucket/source
     done
     ```

1.   Deploy all of the dags.
     ```
     AIRFLOW_DAG_GCS=$(cd common_components/orchestration/infrastructure && terraform output --raw airflow_dag_gcs_prefix)
     for dag in use_cases/examples/*/deploy/*.py ; do
       gsutil cp $dag $AIRFLOW_DAG_GCS
     done
     ```

## Clean up
To avoid incurring charges to your Google Cloud account for the resources used in this tutorial, 
either delete the project that contains the resources, or keep the project and delete the 
individual resources.

### Delete the individual resources

To avoid incurring further charges, delete the individual resources that you use
in this tutorial:

```
cd infrastructure/environment
terraform destroy
```

## What's next

- Explore more [ Google Cloud  for financial service solutions](https://cloud.google.com/solutions/financial-services#section-1).
- For more reference architectures, diagrams, tutorials, and best practices, explore the [Cloud Architecture Center](https://cloud.google.com/architecture).
