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


######
#
# Build Cloud Composer and its dependencies
#

# Enable Composer API and configure the roles
# See https://github.com/terraform-google-modules/terraform-google-project-factory
module "project_services" {
  source  = "github.com/terraform-google-modules/terraform-google-project-factory//modules/project_services?ref=v12.0.0"
  count = var.enabled ? 1 : 0

  project_id = var.project

  # Activate Composer API
  activate_api_identities = [{
    "api": "composer.googleapis.com",
    "roles": [
      "roles/composer.ServiceAgentV2Ext",
      "roles/composer.serviceAgent",
    ]
  }]
}

# Create a Cloud Composer specific service account
# See https://github.com/terraform-google-modules/terraform-google-service-accounts
module "composer_service_account" {
  source = "github.com/terraform-google-modules/terraform-google-service-accounts?ref=v4.1.1"

  count = var.enabled ? 1 : 0

  project_id    = var.project
  prefix        = var.env_name
  names         = ["runner"]
  project_roles = [
    "${var.project}=>roles/composer.worker",
    "${var.project}=>roles/iam.serviceAccountUser",
    "${var.project}=>roles/bigquery.dataEditor",
    "${var.project}=>roles/bigquery.jobUser",
  ]
}

# Create a new network and subnet
# See https://github.com/terraform-google-modules/terraform-google-network
module "vpc" {
  source = "github.com/terraform-google-modules/terraform-google-network?ref=v5.0.0"

  count = var.enabled ? 1 : 0

  project_id   = var.project
  network_name = "${var.env_name}-network"
  routing_mode = "GLOBAL"

  subnets = [{
    subnet_name           = "composer-subnet"
    subnet_ip             = "10.10.10.0/24"
    subnet_region         = var.region
    subnet_private_access = true
  }]

  secondary_ranges = {
    composer-subnet = [
      {
        range_name    = "composer-subnet-cluster"
        ip_cidr_range = "10.154.0.0/17"
      },
      {
        range_name    = "composer-subnet-services"
        ip_cidr_range = "10.154.128.0/22"
      },
    ]
  }

  # TODO: Explicitly define firewall rules
}

# Create Composer 2 environment.
resource "google_composer_environment" "composer_env" {
  count = var.enabled ? 1 : 0

  project = var.project
  name    = var.env_name
  region  = var.region

  # Tags and such can be filled in. Ignore changes after creation.
  lifecycle {
    ignore_changes = [
      config["software_config"],
      config["node_config"]
    ]
  }

  config {
    software_config {
      image_version = "composer-2.5.1-airflow-2.6.3"
      env_variables = {
        AIRFLOW_VAR_PROJECT_ID        = var.project
        AIRFLOW_VAR_REGION            = var.region
        AIRFLOW_VAR_ENV_NAME          = var.env_name
        AIRFLOW_VAR_BQ_LOCATION       = var.bq_location
        AIRFLOW_VAR_GCR_HOSTNAME      = var.gcr_hostname
        AIRFLOW_VAR_GCS_INGEST_BUCKET = var.gcs_ingest_bucket
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    node_config {
      network         = module.vpc[0].network_id
      subnetwork      = module.vpc[0].subnets["${var.region}/composer-subnet"].id
      service_account = module.composer_service_account[0].email
      ip_allocation_policy {
        cluster_secondary_range_name = "composer-subnet-cluster"
        services_secondary_range_name = "composer-subnet-services"
      }
    }
  }

  depends_on = [
    module.project_services
  ]
}
