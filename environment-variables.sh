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

# Generic configuration
export EMAIL=$(gcloud config get-value account)
export ENV_ID=${EMAIL%@*}-dev
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects list --filter="project_id=$PROJECT_ID" --format="value(PROJECT_NUMBER)")
export GCS_TF_STATE=${PROJECT_ID}-tfstate
export GCS_INGEST_BUCKET=$PROJECT_ID-$GCS_LOCATION-ingest-bucket
export DBT_PROFILES_DIR=./profiles # DBT specific configuration


# Use case specific configuration
# Define use-case-specific datasets &
# edit:
# ./common_components/orchestration/infrastructure/terraform.tfvars.template
# and
# ./common_components/orchestration/setup_script.sh
# to reflect these vars

# Print variables
echo -e "\nYour environment variables have been initialised as follows:"
echo -e "\tUse case indipendent variables:"
echo -e "\t\tENV_ID                           :" $ENV_ID
echo -e "\t\tPROJECT_ID                       :" $PROJECT_ID
echo -e "\t\tPROJECT_NUMBER                   :" $PROJECT_NUMBER
echo -e "\t\tREGION                           :" $REGION
echo -e "\t\tBQ_LOCATION                      :" $BQ_LOCATION
echo -e "\t\tGCS_TF_STATE                     :" $GCS_TF_STATE
echo -e "\t\tGCS_LOCATION                     :" $GCS_LOCATION
echo -e "\t\tGCS_INGEST_BUCKET                :" $GCS_INGEST_BUCKET
echo -e "\t\tDBT_PROFILES_DIR                 :" $DBT_PROFILES_DIR

# Edit to reflect use-case specific vars
# HOME LOAN DELINQUENCY
export HOMELOAN_GCR_DATALOAD=gcr.io/${PROJECT_ID}/homeloan-bq-data-load
export HOMELOAN_GCR_DBT=gcr.io/${PROJECT_ID}/homeloan-dbt
export HOMELOAN_BQ_DEV=homeloan_dev
export HOMELOAN_BQ_DATA=homeloan_data
export HOMELOAN_BQ_EXPECTEDRESULTS=homeloan_expectedreresults
echo -e "\n\tUse case: Home Loan Delinquency:"
echo -e "\t\tHOMELOAN_GCR_DATALOAD            :" $HOMELOAN_GCR_DATALOAD
echo -e "\t\tHOMELOAN_GCR_DBT                 :" $HOMELOAN_GCR_DBT
echo -e "\t\tHOMELOAN_BQ_DEV                  :" $HOMELOAN_BQ_DEV
echo -e "\t\tHOMELOAN_BQ_DATA                 :" $HOMELOAN_BQ_DATA
echo -e "\t\tHOMELOAN_BQ_EXPECTEDRESULTS      :" $HOMELOAN_BQ_EXPECTEDRESULTS

# Edit to reflect use-case specific vars
export CRE_GCR_DATALOAD=gcr.io/${PROJECT_ID}/cre-data_generator
export CRE_GCR_DBT=gcr.io/${PROJECT_ID}/cre-dbt
export CRE_BQ_DEV=cre_dev
export CRE_BQ_DATA=cre_data
echo -e "\n\tUse case: BoE Commercial Real Estate:"
echo -e "\t\tCRE_GCR_DATALOAD                 :" $CRE_GCR_DATALOAD
echo -e "\t\tCRE_GCR_DBT                      :" $CRE_GCR_DBT
echo -e "\t\tCRE_BQ_DEV                       :" $CRE_BQ_DEV
echo -e "\t\tCRE_BQ_DATA                      :" $CRE_BQ_DATA
echo -e "\n"