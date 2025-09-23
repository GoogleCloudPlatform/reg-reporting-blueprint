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


variable "project" {}

variable "region" {
  description = "The region for Cloud Composer"
}

variable "gcs_location" {
  description = "The GCS location where the buckets will be created"
}

variable "bq_location" {
  description = "The BQ location where the datasets will be created"
}

variable "bq_datasets" {
  description = "The BQ datasets to create"
}

variable "composer_version" {
  description = "The version of Cloud Composer to use"
  default     = "composer-2.14.2-airflow-2.10.5"
}

variable "src_url" {
  description = "Source URL for dbt_dashboard (embedded into dashboards)"
  default     = "https://github.com/GoogleCloudPlatform/reg-reporting-blueprint/tree"
}

