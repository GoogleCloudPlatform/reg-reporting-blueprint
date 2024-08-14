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

locals {
  registry_url = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.reg-reporting-repo.name}"
}

# Enable APIs
# See https://github.com/terraform-google-modules/terraform-google-project-factory
# The modules/project_services
module "project_services" {
  source = "github.com/terraform-google-modules/terraform-google-project-factory//modules/project_services?ref=v14.3.0"

  project_id                  = var.project
  disable_services_on_destroy = false
  disable_dependent_services  = false
  activate_apis = [
    "cloudbuild.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
  ]

  # Activate Composer API
  activate_api_identities = [{
    "api" : "cloudbuild.googleapis.com",
    "roles" : [
      "roles/bigquery.dataEditor",
      "roles/bigquery.jobUser",
    ]
  }]
}

# Create artifact registry
resource "google_artifact_registry_repository" "reg-reporting-repo" {
  project       = module.project_services.project_id
  format        = "DOCKER"
  location      = var.region
  repository_id = "reg-reporting-repository"
  description   = "Regulatory Reporting containers"
}

# Create DBT Composer setup
module "dbt_composer" {
  source                 = "github.com/GoogleCloudPlatform/terraform-google-dbt-composer-blueprint?ref=v1.1.0"
  project_id             = module.project_services.project_id
  region                 = var.region
  gcs_location           = var.region
  bq_location            = var.bq_location
  goog_packaged_solution = "gcp-reg-reporting"
  env_variables = {
    AIRFLOW_VAR_REPO : local.registry_url,
    AIRFLOW_VAR_INGEST_BUCKET : module.gcs_buckets.bucket.name
  }
}

# Create ingest & cloudbuild source staging GCS Buckets
# See https://github.com/terraform-google-modules/terraform-google-cloud-storage
module "gcs_buckets" {
  source = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=v4.0.1"

  project_id = module.project_services.project_id
  prefix     = module.project_services.project_id
  location   = var.gcs_location

  # List of buckets to create
  names = [
    "ingest-bucket",
    "cloudbuild-source-staging-bucket",
  ]
}

# Create BigQuery Datasets
# See https://github.com/terraform-google-modules/terraform-google-bigquery
module "bigquery" {
  source = "github.com/terraform-google-modules/terraform-google-bigquery?ref=v7.0.0"

  project_id                 = module.project_services.project_id
  dataset_id                 = each.value
  dataset_name               = each.value
  description                = "Dataset ${each.value} created by terraform"
  location                   = var.bq_location
  delete_contents_on_destroy = true

  # List of datasets to create
  for_each = toset(var.bq_datasets)
}

# Create Cloud Build service account
# See https://github.com/terraform-google-modules/terraform-google-service-accounts
module "composer_service_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.3.0"

  project_id = module.project_services.project_id
  names = [
    "builder"
  ]
  project_roles = [
    "${module.project_services.project_id}=>roles/logging.logWriter",
    "${module.project_services.project_id}=>roles/storage.objectUser",
    "${module.project_services.project_id}=>roles/artifactregistry.writer",
  ]
}
