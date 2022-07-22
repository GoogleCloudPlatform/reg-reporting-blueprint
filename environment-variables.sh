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

#Set a default region if not set in env
export REGION=$(gcloud config get-value compute/region 2> /dev/null)
export REGION=${REGION:="us-central1"}
if [[ "$REGION" == europe-* ]]; then
  export BQ_LOCATION="EU"
  export GCS_LOCATION="eu"
else
  export BQ_LOCATION="US"
  export GCS_LOCATION="us"
fi


export EMAIL=$(gcloud config get-value account)
export ENV_ID=${EMAIL%@*}-dev
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects list --filter="project_id=$PROJECT_ID" --format="value(PROJECT_NUMBER)")
export GCR_DBT_SAMPLE_REPORTING_IMAGE=gcr.io/${PROJECT_ID}/home-loan-delinquency
export GCR_DATALOAD_IMAGE=gcr.io/${PROJECT_ID}/bq-data-load
export GCS_TF_STATE=${PROJECT_ID}-tfstate
export GCS_INGEST_BUCKET=$PROJECT_ID-$GCS_LOCATION-ingest-bucket


# Define use-case-specific datasets &
# edit:
# ./common_components/orchestration/infrastructure/terraform.tfvars.template
# and
# ./common_components/orchestration/setup_script.sh
# to reflect these vars
export HOMELOAN_BQ_DEV=homeloan_dev
export HOMELOAN_BQ_DATA=homeloan_data
export HOMELOAN_BQ_EXPECTEDRESULTS=homeloan_expectedreresults

echo -e "\nYour environment variables have been initialised as follows:"
echo -e "\tENV_ID                           :" $ENV_ID
echo -e "\tPROJECT_ID                       :" $PROJECT_ID
echo -e "\tPROJECT_NUMBER                   :" $PROJECT_NUMBER
echo -e "\tREGION                           :" $REGION
echo -e "\tGCR_DBT_SAMPLE_REPORTING_IMAGE   :" $GCR_DBT_SAMPLE_REPORTING_IMAGE
echo -e "\tGCR_DATALOAD_IMAGE               :" $GCR_DATALOAD_IMAGE
echo -e "\tGCS_TF_STATE                     :" $GCS_TF_STATE
echo -e "\tGCS_INGEST_BUCKET:               :" $GCS_INGEST_BUCKET
echo -e "\tGCS_LOCATION                     :" $GCS_LOCATION
echo -e "\tBQ_LOCATION                      :" $BQ_LOCATION
# Edit to reflect use-case specific vars
echo -e "\tHOMELOAN_BQ_DEV                  :" $HOMELOAN_BQ_DEV 
echo -e "\tHOMELOAN_BQ_DATA                 :" $HOMELOAN_BQ_DATA
echo -e "\tHOMELOAN_BQ_EXPECTEDRESULTS      :" $HOMELOAN_BQ_EXPECTEDRESULTS 
