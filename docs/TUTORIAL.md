# Standing Up a Cloud-Native Regulatory Reporting Architecture  with BigQuery

## Table of contents
1. [Table of contents](#table-of-contents)
1. [Introduction](#introduction)
1. [Objectives](#objectives)
1. [Costs](#costs)
1. [Before you begin](#before-you-begin)
1. [Prepare your environment](#prepare-your-environment)
1. [Upload the sample data](#upload-the-sample-data)
1. [Run the regulatory reporting pipeline](#run-the-regulatory-reporting-pipeline)
1. [(Optional) Containerize the transformations](#-optional--containerize-the-transformations)
1. [Clean up](#clean-up)
1. [Delete the project](#delete-the-project)
1. [Delete the individual resources](#delete-the-individual-resources)
1. [What's next](#what-s-next)


## Introduction
This document shows you how to get started with the cloud-native regulatory reporting solution and run a basic pipeline. It is intended for data engineers who want to familiarize themselves with an architecture and best practices for producing stable, reliable regulatory reports. 

In this tutorial, you establish a working example of a regulatory data processing platform on Google Cloud resources. The example platform demonstrates how financial institutions can implement a data processing pipeline that meets the following requirements of regulatory reporting, but still maintains quality of data, auditability, and ease of change and deployment: 

* Ingestion of data from source
* Processing of large volumes of granular data
* Aggregation into reports. 

This document assumes that you’re familiar with Terraform, data build tool (dbt), Cloud Storage, and BigQuery.

------
## Objectives
* Create infrastructure from a cloned repository
* Load manufactured data into BigQuery
* Extract regulatory metrics from granular data
* Containerize the extraction pipeline

----
## Costs
This tutorial uses the following billable components of Google Cloud:
* BigQuery
* Cloud Storage
* Optionally, Cloud Composer

Use the [Pricing Calculator](https://cloud.google.com/products/calculator) to generate a cost estimate based on your projected usage.

-----
## Before you begin
For this reference guide, you need a Google Cloud [project](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects). You can create a new one, or select a project you already created:

1. Select or create a Google Cloud project.
    [GO TO THE PROJECT SELECTOR PAGE](https://console.cloud.google.com/projectselector2/home/dashboard)

2. Enable billing for your project.
    [ENABLE BILLING](https://support.google.com/cloud/answer/6293499#enable-billing)

3. If you will be using a Cloud Shell instance as your development environment, then in the Cloud Console, activate Cloud Shell.
    [ACTIVATE CLOUD SHELL](https://console.cloud.google.com/?cloudshell=true&_ga=2.175791653.601714487.1648649282-1707141935.1648504534)

    At the bottom of the Cloud Console, a Cloud Shell session starts and displays a command-line prompt. Cloud Shell is a shell environment with the Google Cloud CLI already installed and with values already set for your current project. It can take a few seconds for the session to initialize.

When you finish this tutorial, you can avoid continued billing by deleting the resources you created. See [Clean up](#clean-up) for more detail.

---
## Prepare your environment
1. Clone the gitHub repository to your development environment
1. Install  dbt:
    ```
    sudo pip3 install dbt-bigquery
    ```

    To verify the installation of dbt, execute the following command:
    ```
    dbt --version
    ```

    You see a printed version of the installation.

2. Initialize the environment variables: 
    ```
    cd pattern-solution
    source environment-variables.sh
    ```

3. Run the setup script.
    ```
    cd common_components
    . ./setup_script.sh
    ```

4. Run terraform to create the required infrastructure
    ```
    cd orchestration/infrastructure/
    terraform init -upgrade
    terraform plan
    terraform apply
    ```

5. In the Google Cloud Console, go to the **Cloud Storage** page and check for a bucket with a name like ${project}-${region}-ingest-bucket to verify that an ingest bucket has been created.

6. Go to the **BigQuery** page and verify that the following datasets have been created:
    * homeloan_dev
    * homeloan_data
    * homeloan_expectedresults

----
## Upload the sample data
In this section, you explore  the contents of the repository’s `data `and `data_load` folders, and load sample data to BigQuery. 

1. In the Cloud Shell Editor instance, navigate to the `data` folder in the repository:
    ```
    cd ../../../use_cases/examples/home_loan_delinquency/data/
    ```
	This folder contains two subfolders which are named `input `and `expected`.

1. Look at the contents of the` input` folder. This folder contains CSV files with sample input data. This sample data is provided only for test purposes.

1. Look at the contents of the `expected` folder. This folder contains the CSV files specifying the expected results once the transformations are applied.

1. Navigate to, and explore, the `data_load/schema` folder, which contains files specifying the schema of staging data. 
    ```
    cd ../components/data_load/
    ```
    The command uses ephemeral models to transform source and reference data into physicalised models.These physicalized models conform to the schema of the ephemeral models  when you run the regulatory reporting pipeline.

1. Load the data into Cloud Storage using the `gsutil` command:
    ```
    ./load_to_gcs.sh ../../data/input
    ./load_to_gcs.sh ../../data/expected 
    ```
    The data is now available in your Cloud Storage ingest bucket. Load the data from the bucket to BigQuery using the following convenience script:
    ```
    ./load_to_bq.sh
    ```

1. To verify that the data has been loaded in BigQuery, in the Google Cloud Console, go to the BigQuery page and select a table in the `homeloan_data` and `homeloan_expectedresults` datasets. 
    Select the **Preview** tab of each table and check that data has been populated.

----
## Run the regulatory reporting pipeline
1. In your development environment test the connection between your local dbt installation and your BigQuery datasets by running the following command: 
    ```
    cd ../../dbt/
    dbt debug --profiles-dir profiles/
    ```
    At the end of the connectivity, configuration and dependency info returned by the command, you should see the following message: `All checks passed!`

1. In the `models` folder, open a SQL file to inspect the logic of the sample reporting transformations implemented in DBT. 

1. Execute the reporting transformations to create the regulatory reporting metrics:
    ```
    dbt run --profiles-dir profiles/ 
    ```

1. Try to run the transformations for a specific date:
    ```
    dbt run --profiles-dir profiles/ --vars '{"reporting_day": "2021-09-03"}'
    ```
    Notice the variables that control the execution of the transformations. One of these is `reporting_day`, which indicates the day on which the portfolio should be valued. When you run the `dbt run `command it is a best practice to  provide this value explicitly. 

1. In the Google Cloud Console, go to the BigQuery page and inspect the `homeloan_dev` dataset. Notice how the data has been populated, and how the `reporting_day` variable that you passed is used in the `control.reporting_day` field of the `wh_denormalised` view.
    Inspect the models/schema.yml file: \
    Notice how the file defines the definitions of the columns and the associated data quality tests. For example, the `ACCOUNT_KEY` field in the `src_current_accounts_attributes` table must be unique and not null.

1. Run the data quality tests that are specified in the config files:
    ```
    dbt test --profiles-dir profiles/ -s test_type:generic 
    ```
   
1. Inspect the code in the ` use_cases/examples/home_loan_delinquency/dbt/tests `folder, which contains `singular` tests.  Notice how the tests in this folder implement a table comparison between actual results as outputted by the `dbt run` command, and expected results as saved in the `homeloan_expectedresults` dataset.
    Run the singular tests:
    ```
    dbt test --profiles-dir profiles/ -s test_type:singular
    ```

1. Generate the documentation for the project:
    ```
    dbt docs generate --profiles-dir profiles && dbt docs serve --profiles-dir profiles 
    ```

1. Explore the lineage of the models, and their detailed documentation. You see that  the documentation includes all the models’ documentation as specified in the  models/schema.yml files, and all the code of the models.

----
## (Optional) Containerize the transformations
1. Create a container for the BigQuery data load step, and push the container to Google Container Repository:
    ```
    cd ../components/data_load/     # Note the Dockerfile in this folder
    gcloud builds submit --tag $GCR_DATALOAD_IMAGE  # Pushes the image to GCR     
    ```
    The Dockerfile in this directory enables this containerization, which simplifies orchestration of the workflow.

1. Containerize the DBT code for the data transformation step, and push the container to Google Container Repository. 
    ```
    cd ../../dbt
    gcloud builds submit --tag $GCR_DBT_SAMPLE_REPORTING_IMAGE
    ```
    Containerization helps you to create a package that can be easily versioned and deployed. 

----
## Clean up
To avoid incurring charges to your Google Cloud account for the resources used in this tutorial:
### Delete the project
The easiest way to eliminate billing is to delete the project you created for the tutorial.
**Caution**: Deleting a project has the following effects:
* **Everything in the project is deleted.** If you used an existing project for this tutorial, when you delete it, you also delete any otherwork you've done in the project.
* **Custom project IDs are lost.** When you created this project, you might have created a custom project ID that you want to use in thefuture. To preserve the URLs that use the project ID, such as an **<code>appspot.com</code></strong> URL, delete selected resources inside theproject instead of deleting the whole project.
If you plan to explore multiple tutorials and quickstarts, reusing projects can help you avoid exceeding project quota limits.

1. In the Cloud Console, go to the **Manage resources** page. \
[Go to the Manage resources page](https://console.cloud.google.com/iam-admin/projects)
1. In the project list, select the project that you want to delete and then click **Delete **
1. In the dialog, type the project ID and then click **Shut down** to delete the project.

----
## Delete the individual resources
To avoid incurring further charges, destroy the resources.
```
cd infrastructure/environment
terraform destroy
```

----
## What's next
* Try out other Google Cloud features for yourself. Have a look at our [tutorials](https://cloud.google.com/docs/tutorials).
* Explore more [Google Cloud for financial service solutions.](https://cloud.google.com/solutions/financial-services#section-1)
* Read about HSBC regulatory reporting use case
* Read about the ANZ use case