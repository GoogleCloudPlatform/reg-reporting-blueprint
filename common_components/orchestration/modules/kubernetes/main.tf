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


# Create namespace for running
resource "kubernetes_namespace" "runner" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.env_name
  }
}

# Create Google Service Account and K8s service account for workload identity
# See https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/modules/workload-identity
module "my-app-workload-identity" {
  count = var.enabled ? 1 : 0

  source = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/workload-identity?ref=v20.0.0"

  name       = var.env_name
  namespace  = var.env_name
  project_id = var.project_id
  roles      = ["roles/bigquery.dataEditor"]
  depends_on = [
    kubernetes_namespace.runner
  ]
}

