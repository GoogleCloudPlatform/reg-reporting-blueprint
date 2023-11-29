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


variable "project_id" {
  description = "The project ID to for dbt_log monitoring dataset"
}

variable "bq_location" {
  description = "The location of monitoring dataset"
}

variable "airflow_url" {
  description = "The base URL for airflow (embedded into dashboard tables)"
}

variable "docs_bucket" {
  description = "The bucket name storing the generated documentation (embedded into dashboard tables)"
}

variable "src_url" {
  description = "The source URL for any source code references (embedded into dashboard tables)"
}

variable "monitoring_dataset" {
  description = "The dataset name for monitoring dbt_log"
  default = "monitoring"
}
