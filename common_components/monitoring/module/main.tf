# Copyright 2023 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Create dataset for monitoring
module "bigquery_monitoring" {
  source = "github.com/terraform-google-modules/terraform-google-bigquery?ref=v6.1.1"

  project_id   = var.project_id
  dataset_id   = each.value
  dataset_name = each.value
  description  = "Dataset ${each.value} created by terraform"
  location     = var.bq_location

  # List of datasets to create
  for_each = toset([var.monitoring_dataset])
}


# Create dbt_log table outline.
resource "google_bigquery_table" "dbt_log_table" {

  # Only create table after the dataset is created
  depends_on = [
    module.bigquery_monitoring
  ]

  dataset_id    = var.monitoring_dataset
  table_id      = "dbt_log"
  friendly_name = "dbt_log"
  project       = var.project_id

  labels              = {}
  schema              = file("${path.module}/dbt_log_schema.json")
  deletion_protection = false

  time_partitioning {
    type                     = "DAY"
    expiration_ms            = null
    field                    = "update_time"
    require_partition_filter = false
  }

  lifecycle {
    ignore_changes = [
      # managed by google_bigquery_dataset.main.default_encryption_configuration
      encryption_configuration
    ]
  }
}

data "template_file" "dbt_start" {
  template = file("${path.module}/dbt_start.sql")
  vars = {
    monitoring_dataset = var.monitoring_dataset
  }
}

# Create dbt_end materialized view
resource "google_bigquery_table" "dbt_start" {
  project             = var.project_id
  dataset_id          = var.monitoring_dataset
  friendly_name       = "dbt_start"
  table_id            = "dbt_start"
  description         = "DBT start stage extraction"
  deletion_protection = false

  materialized_view {
    query = data.template_file.dbt_start.rendered
  }

  depends_on = [
    google_bigquery_table.dbt_log_table
  ]

  lifecycle {
    ignore_changes = [
      encryption_configuration
    ]
  }
}

data "template_file" "dbt_end" {
  template = file("${path.module}/dbt_end.sql")
  vars = {
    monitoring_dataset = var.monitoring_dataset
  }
}

# Create dbt_end materialized view
resource "google_bigquery_table" "dbt_end" {
  project             = var.project_id
  dataset_id          = var.monitoring_dataset
  friendly_name       = "dbt_end"
  table_id            = "dbt_end"
  description         = "DBT end stage extraction"
  deletion_protection = false

  materialized_view {
    query = data.template_file.dbt_end.rendered
  }

  depends_on = [
    google_bigquery_table.dbt_log_table
  ]

  lifecycle {
    ignore_changes = [
      encryption_configuration
    ]
  }
}


data "template_file" "dbt_dashboard" {
  template = file("${path.module}/dbt_dashboard.sql")
  vars = {
    project_id         = var.project_id
    monitoring_dataset = var.monitoring_dataset
    airflow_url        = var.airflow_url
    docs_bucket        = var.docs_bucket
    src_url            = var.src_url
  }
}

# Create dbt_dashboard view (for dashboards!)
resource "google_bigquery_table" "dbt_dashboard" {
  project             = var.project_id
  dataset_id          = var.monitoring_dataset
  friendly_name       = "dbt_dashboard"
  table_id            = "dbt_dashboard"
  description         = "DBT dashboard"
  deletion_protection = false

  view {
    query          = data.template_file.dbt_dashboard.rendered
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.dbt_start,
    google_bigquery_table.dbt_end
  ]

  lifecycle {
    ignore_changes = [
      encryption_configuration
    ]
  }
}

