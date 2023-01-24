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

output "airflow_uri" {
  description = "Airflow URI"
  value       = module.composer_reg_reporting.airflow_uri
}

output "airflow_dag_gcs_prefix" {
  description = "Airflow GCS DAG prefix"
  value       = module.composer_reg_reporting.airflow_dag_gcs_prefix
}

output "airflow_gke_cluster" {
  description = "Airflow GKE Cluster"
  value       = module.composer_reg_reporting.airflow_gke_cluster
}

output "gcs_ingest_bucket" {
  value = module.gcs_buckets.names_list[0]
}

output "gcs_cloudbuild_source_staging_bucket" {
  value = module.gcs_buckets.names_list[1]
}