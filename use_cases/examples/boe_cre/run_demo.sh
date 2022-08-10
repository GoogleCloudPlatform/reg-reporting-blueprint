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

# Environment variables
echo -e "\n\nInitialise environment variables"
source ../../../environment-variables.sh

# Retrieve terraform config
echo -e "\n\nGet the terraform configuration"
cd ../../../common_components/orchestration/infrastructure/
AIRFLOW_DAG_GCS=$(terraform output --raw airflow_dag_gcs_prefix)
AIRFLOW_UI=$(terraform output --raw airflow_uri)
echo -e "\tAIRFLOW_DAG_GCS: "${AIRFLOW_DAG_GCS}
echo -e "\tAIRFLOW_UI:      "${AIRFLOW_UI}
cd ../../../use_cases/examples/boe_cre/

# Create containereised app
echo -e "\n\nCreate a containerised data generator application"
cd data_generator
gcloud builds submit --tag $CRE_GCR_DATALOAD
cd ..

# Create containereised app
echo -e "\n\nCreate a containerised data transformation application"
cd dbt
gcloud builds submit --tag $CRE_GCR_DBT
cd ..

# Submit ther DAG to Composer
echo -e "\n\nSubmit the DAG to Composer"
cd deploy
gsutil cp run_cre_dag.py $AIRFLOW_DAG_GCS

echo -e "\tClick on the link to see progress: "${AIRFLOW_UI}
cd ..
