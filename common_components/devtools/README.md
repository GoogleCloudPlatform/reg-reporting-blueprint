
# Development Tools

## init_dbt_profiles.sh

This script will create a reg reporting DBT profiles for development purposes. It is intended to be run from a GCP virtual machine (either GCE instance, a Cloud Workstation instance, or Cloud Shell) and it will inspect the region, zone, and project the GCE instance is running in to provide sensible defaults.

## init_dev_environment.sh

This script installs DBT (and DBT BigQuery), sqlfmt, and DBT power user extension for Code OSS. This is intended to be run in a Cloud Workstation instance or Cloud Shell.

