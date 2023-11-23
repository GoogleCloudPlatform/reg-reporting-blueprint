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
  export GCR_HOSTNAME="eu.gcr.io"
else
  export BQ_LOCATION="US"
  export GCS_LOCATION="us"
  export GCR_HOSTNAME="gcr.io"
fi

# Generic configuration
export EMAIL=$(gcloud config get-value account)
export ENV_ID=${EMAIL%@*}-dev
export PROJECT_ID=$(gcloud config get-value project)
export TF_VAR_PROJECT_ID=$PROJECT_ID
export PROJECT_NUMBER=$(gcloud projects list --filter="project_id=$PROJECT_ID" --format="value(PROJECT_NUMBER)")
export GCS_TF_STATE=${PROJECT_ID}-tfstate
export GCS_INGEST_BUCKET=$PROJECT_ID-$GCS_LOCATION-ingest-bucket
export GCS_DOCS_BUCKET=$PROJECT_ID-$GCS_LOCATION-docs-bucket
export DBT_PROFILES_DIR=./profiles # DBT specific configuration


# Print variables
echo -e "\nYour environment variables have been initialised as follows:"
echo -e "\tUse case indipendent variables:"
echo -e "\t\tENV_ID                           :" $ENV_ID
echo -e "\t\tPROJECT_ID                       :" $PROJECT_ID
echo -e "\t\tPROJECT_NUMBER                   :" $PROJECT_NUMBER
echo -e "\t\tREGION                           :" $REGION
echo -e "\t\tBQ_LOCATION                      :" $BQ_LOCATION
echo -e "\t\tGCR_HOSTNAME                     :" $GCR_HOSTNAME
echo -e "\t\tGCS_TF_STATE                     :" $GCS_TF_STATE
echo -e "\t\tGCS_LOCATION                     :" $GCS_LOCATION
echo -e "\t\tGCS_INGEST_BUCKET                :" $GCS_INGEST_BUCKET
echo -e "\t\tGCS_DOCS_BUCKET                  :" $GCS_DOCS_BUCKET
echo -e "\t\tDBT_PROFILES_DIR                 :" $DBT_PROFILES_DIR

echo -e "\n"
