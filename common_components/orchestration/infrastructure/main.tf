# Copyright 2022 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Enable APIs
# See https://github.com/terraform-google-modules/terraform-google-project-factory
# The modules/project_services
module "project_services" {
  source  = "github.com/terraform-google-modules/terraform-google-project-factory//modules/project_services?ref=v12.0.0"

  project_id                  = var.project
  disable_services_on_destroy = false
  disable_dependent_services  = false
  activate_apis               = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
  ]

  # Activate Composer API
  activate_api_identities = [{
    "api": "cloudbuild.googleapis.com",
    "roles": [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
    ]
  }]
}

# Create ingest & cloudbuild source staging GCS Buckets
# See https://github.com/terraform-google-modules/terraform-google-cloud-storage
module "gcs_buckets" {
  source = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=v3.2.0"

  project_id = module.project_services.project_id
  prefix     = module.project_services.project_id
  location   = var.gcs_location

  # List of buckets to create
  names = [
    "ingest-bucket",
    "cloudbuild-source-staging-bucket",
    "docs-bucket"
  ]
}

# Create BigQuery Datasets
# See https://github.com/terraform-google-modules/terraform-google-bigquery
module "bigquery" {
  source = "github.com/terraform-google-modules/terraform-google-bigquery?ref=v5.4.0"

  project_id   = module.project_services.project_id
  dataset_id   = each.value
  dataset_name = each.value
  description  = "Dataset ${each.value} created by terraform"
  location     = var.bq_location
  delete_contents_on_destroy = true

  # List of datasets to create
  for_each = toset(var.bq_datasets)
}

# Cloud Composer for runtime if enabled
module "composer_reg_reporting" {
  source = "../modules/composer"

  enabled = var.enable_composer

  project           = module.project_services.project_id
  bq_location       = var.bq_location
  gcr_hostname      = var.gcr_hostname
  region            = var.region
  env_name          = "reg-runner"
  gcs_ingest_bucket = module.gcs_buckets.bucket.name
}

# DBT log monitoring
module "dbt_log_monitoring" {
  source = "../../monitoring/module"

  project_id        = module.project_services.project_id
  bq_location       = var.bq_location
  airflow_url       = module.composer_reg_reporting.airflow_uri
  src_url           = var.src_url
  docs_bucket       = module.gcs_buckets.names_list[2]
}
