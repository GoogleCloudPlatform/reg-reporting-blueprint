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


variable "enabled" {
  description = "Whether the Cloud Composer environment is enabled"
  default = true
  type = bool
}

variable "env_name"{
  description = "The name of the Google Cloud Composer env"
  default = "reg-runner"
}

variable "project" {
  description = "The project ID to host composer"
}

variable "region" {
  description = "The region to host composer"
}

variable "bq_location" {
  description = "The location of BigQuery datasets"
}

variable "gcr_hostname" {
  description = "The GCR hostname that determines the location where the image is stored"
}

variable "gcs_ingest_bucket" {
  description = "GCS ingest bucket for loading data"
}
