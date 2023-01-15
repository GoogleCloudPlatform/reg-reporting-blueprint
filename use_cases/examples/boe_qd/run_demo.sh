#!/bin/bash

# Copyright 2022 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a convenience script that runs the BoE QD demo end to end

# Root directory of the project
BOE_QD_DIR=$(dirname $0)
ROOT_DIR=${BOE_QD_DIR}/../../..

# Environment variables
echo -e "\n\nInitialise environment variables"
source ${ROOT_DIR}/environment-variables.sh

# Retrieve terraform config
echo -e "\n\nGet the terraform configuration"
pushd ${ROOT_DIR}/common_components/orchestration/infrastructure/
AIRFLOW_DAG_GCS=$(terraform output --raw airflow_dag_gcs_prefix)
AIRFLOW_UI=$(terraform output --raw airflow_uri)
echo -e "\tAIRFLOW_DAG_GCS: "${AIRFLOW_DAG_GCS}
echo -e "\tAIRFLOW_UI:      "${AIRFLOW_UI}
popd

# Create containerised apps
echo -e "\n\nCreate a containerised apps"
pushd ${ROOT_DIR}
gcloud builds submit --substitutions _GCR_LOCATION=${GCR_LOCATION} --config use_cases/examples/boe_qd/cloudbuild.yaml
popd

# Submit ther DAG to Composer
echo -e "\n\nSubmit the DAG to Composer"
pushd ${BOE_QD_DIR}/deploy
gsutil cp run_boe_qd_dag.py $AIRFLOW_DAG_GCS

echo -e "\tClick on the link to see progress: "${AIRFLOW_UI}
popd
