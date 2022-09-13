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


resource "google_bigquery_dataset" "dev_dataset" {
  project                     = var.project
  dataset_id                  = var.bq_dataset_dev
  friendly_name               = "Reg Reporting solution - DEV"
  description                 = "Dev dataset to demonstrate the Reg Reporting solution"
  location                    = var.bq_location
  labels = {
    env = "default"
  }
}

resource "google_bigquery_dataset" "sampledata_dataset" {
  project = var.project
  dataset_id = var.bq_dataset_sampledata
  friendly_name = "Reg Reporting solution - Sample data"
  description = "Sample data to demonstrate the Reg Reporting solution"
  location = var.bq_location
  labels = {
    env = "default"
  }
}

resource "google_bigquery_dataset" "expectedresults_dataset" {
  project                     = var.project
  dataset_id                  = var.bq_dataset_expectedresults
  friendly_name               = "Reg Reporting solution - Expected results data"
  description                 = "Sample data to demonstrate the regression test features of the Reg Reporting solution"
  location                    = var.bq_location
  labels = {
    env = "default"
  }
}