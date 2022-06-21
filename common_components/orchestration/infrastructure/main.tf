# Copyright 2022 Google LLC

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
    "artifactregistry.googleapis.com",
  ]
}

# Create Artifactory Repository
resource "google_artifact_registry_repository" "reg-repo" {
  provider = google-beta

  project       = var.project
  location      = var.region
  repository_id = "reg-repo"
  description   = "Docker repository for regulatory reporting solution"
  format        = "DOCKER"
}

# Create GCS Buckets
# See https://github.com/terraform-google-modules/terraform-google-cloud-storage
module "gcs_buckets" {
  source = "github.com/terraform-google-modules/terraform-google-cloud-storage?ref=v3.2.0"

  project_id = module.project_services.project_id
  prefix     = module.project_services.project_id
  location   = var.gcs_location

  # List of buckets to create
  names = [
    "ingest-bucket"
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

  # List of datasets to create
  for_each = toset(var.bq_datasets)
}

# Cloud Composer for runtime if enabled
module "composer_reg_reporting" {
  source = "../modules/composer"

  enabled = var.enable_composer

  project           = module.project_services.project_id
  bq_location       = var.bq_location
  region            = var.region
  env_name          = "reg-runner"
  gcs_ingest_bucket = module.gcs_buckets.bucket.name
}
