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

# This is a convenience script that runs the Flashing demo end to end

# Root directory of the project
FLASHING_DIR=$(dirname $0)
ROOT_DIR=${FLASHING_DIR}/../../..

# Environment variables
echo -e "\n\nInitialise environment variables"
source ${ROOT_DIR}/environment-variables.sh

# Retrieve terraform config
echo -e "\n\nGet the terraform configuration"
pushd ${ROOT_DIR}/common_components/orchestration/infrastructure/
AIRFLOW_DAG_GCS=$(terraform output --raw airflow_dag_gcs_prefix)
AIRFLOW_UI=$(terraform output --raw airflow_uri)
GCS_SOURCE_STAGING_BUCKET=$(terraform output --raw gcs_cloudbuild_source_staging_bucket)
echo -e "\tAIRFLOW_DAG_GCS: "${AIRFLOW_DAG_GCS}
echo -e "\tAIRFLOW_UI:      "${AIRFLOW_UI}
echo -e "\tGCS_SOURCE_STAGING_BUCKET: "${GCS_SOURCE_STAGING_BUCKET}
popd

# # Create some sample data
# pushd ${FLASHING_DIR}/data_generator
# python3 -m pip install --require-hashes -r requirements.txt
# python3 datagen.py --project_id $PROJECT_ID --bq_dataset regrep_source --date 2022-08-15 --symbol ABC
# popd
# 
# ## Run the dbt reports
# pushd ${FLASHING_DIR}/dbt
# dbt deps
# dbt run
# popd

# Create containerised apps
echo -e "\n\nCreate containerised apps"
pushd ${ROOT_DIR}
gcloud builds submit --gcs-source-staging-dir gs://$GCS_SOURCE_STAGING_BUCKET/source --region=${REGION} --substitutions _GCR_HOSTNAME=${GCR_HOSTNAME} --config use_cases/examples/flashing_detection/cloudbuild.yaml
popd

# Submit the DAG to Composer
echo -e "\n\nSubmit the DAG to Composer"
pushd ${FLASHING_DIR}/deploy
gsutil cp run_flashing_dag.py ${AIRFLOW_DAG_GCS}

echo -e "\tClick on the link to see progress: "${AIRFLOW_UI}
popd
