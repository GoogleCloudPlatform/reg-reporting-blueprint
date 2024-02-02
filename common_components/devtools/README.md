# Development Tools

## Cloud Shell quickstart

Run the Cloud Shell quickstart, including a tutorial, to get up and running with DBT in Cloud Shell.
[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ide.cloud.google.com/?cloudshell_git_branch=upgrade_to_terraform_dbt_composer&cloudshell_git_repo=https://github.com/GoogleCloudPlatform/reg-reporting-blueprint&show=ide&cloudshell_tutorial=common_components/devtools/cloudshell_tutorial.md)

## init_dbt_profiles.sh

This script will create a reg reporting DBT profiles for development purposes. It is intended to be run from a GCP virtual machine (either GCE instance, a Cloud Workstation instance, or Cloud Shell) and it will inspect the region, zone, and project the GCE instance is running in to provide sensible defaults. It will prompt the user if it cannot find the right information.

## init_dev_environment.sh

This script installs DBT (and DBT BigQuery), sqlfmt, and DBT power user extension for Code OSS. This is intended to be run in a Cloud Workstation instance or Cloud Shell.
