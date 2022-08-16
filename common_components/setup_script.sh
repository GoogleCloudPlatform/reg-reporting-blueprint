#!/bin/bash

# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#### Description: Sets up the Terraform configuration files as per the
#### variables entered by the user, and initialises the environment variables
#### used by Argo and DBT

__text_welcome="
This script performs the setup required to stand up the
Google Regulatory Reporting solution.
"

__text_variables_init="
#########################################################
# Variables initialisation                              #
#########################################################
"

__text_config_tf="
#########################################################
# Configuration of the terraform scripts                #
#########################################################
"

__text_success="
Your configuration has been updated, please inspect the following files.
Please run terraform init, plan and apply to create the infrastructure.
"

echo -e "$__text_welcome"
echo -e "$__text_variables_init"

SCRIPT_DIR=$(dirname "$0")

source "${SCRIPT_DIR}/../environment-variables.sh"

# Do all the setup in the terraform files
echo -e "$__text_config_tf"
pushd "${SCRIPT_DIR}/orchestration/infrastructure" > /dev/null
echo -e "Creating the storage bucket"
BUCKET="gs://${GCS_TF_STATE}"
if $(gsutil ls "${BUCKET}" > /dev/null 2>&1); then
  echo "Bucket already exists. Skipping bucket creation."
else
  gsutil mb "${BUCKET}"
  echo -e "Enabling Object Versioning to keep the history of your deployments"
  gsutil versioning set on "${BUCKET}"
fi

echo -e "Creating the terraform.tfvars file..."
# Update with use-case specific BQ vars
cat terraform.tfvars.template | sed \
  -e s/PROJECT_ID/$PROJECT_ID/g \
  -e s/ENV_ID/$ENV_ID/g \
  -e s/REGION/$REGION/g \
  -e s/GCS_LOCATION/$GCS_LOCATION/g \
  -e s/PROJECT_NUMBER/$PROJECT_NUMBER/g \
  -e s/BQ_LOCATION/$BQ_LOCATION/g \
  -e s/HOMELOAN_BQ_DEV/$HOMELOAN_BQ_DEV/g \
  -e s/HOMELOAN_BQ_DATA/$HOMELOAN_BQ_DATA/g \
  -e s/HOMELOAN_BQ_EXPECTEDRESULTS/$HOMELOAN_BQ_EXPECTEDRESULTS/g \
  -e s/TF_VAR_FLASHING_BQ_MARKET_DATA/$TF_VAR_FLASHING_BQ_MARKET_DATA/g \
  -e s/TF_VAR_FLASHING_BQ_ORDER_DATA/$TF_VAR_FLASHING_BQ_ORDER_DATA/g \
  > terraform.tfvars

echo -e "Creating the backend.tf file..."
cat backend.tf.template | sed \
  -e s/PROJECT_ID/$PROJECT_ID/g \
  -e s/ENV_ID/$ENV_ID/g \
  > backend.tf

popd
