#!/bin/bash

# Copyright 2023 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Profiles to update
PROFILES_FILE="${HOME}/.dbt/profiles.yml"

# Create the profile directory
mkdir -p "$(dirname ${PROFILES_FILE})"

# Stop early if the DBT profile already exists -- do not overwrite
if [ -f "${PROFILES_FILE}" ]; then
  echo "DBT profile ${PROFILES_FILE} already exists. Exiting..."
  exit 0
fi

# Set the project if necessary
if [ "${PROJECT_ID}" == "" ]; then
  PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/project/project-id)
fi
if [[ "${PROJECT_ID}" == "" ]]; then
  PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
fi
if [[ "${PROJECT_ID}" == "" ]]; then
  read -p "Enter PROJECT_ID: " PROJECT_ID
fi

# Set REGION, and BQ_LOCATION if not already set
if [ "${REGION}" == "" ]; then
  read -p "Enter REGION: " REGION
fi
if [ "${BQ_LOCATION}" == "" ]; then
  read -p "Enter BQ_LOCATION: " BQ_LOCATION
fi

# Identify the USER_DATA prefix (leave empty if cannot)
USER_DATASET=""
if [[ "${USER}" != "" ]]; then
  USER_DATASET="${USER//[^a-zA-Z0-9]/_}_"
fi

# Create the profiles file
cat > "${PROFILES_FILE}" <<EOF
# Copyright 2023 The Reg Reporting Blueprint Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

config:
  partial_parse: false
  use_colors: true
  printer_width: 100
  send_anonymous_usage_stats: false

#
# For development, it is suggested to copy this profile to $HOME/.dbt
#
# See https://docs.getdbt.com/docs/get-started/connection-profiles for details
#
regrep_profile:
  target: prod

  outputs:
    prod:
      type: bigquery
      method: oauth
      project: "{{ env_var('PROJECT_ID', '$PROJECT_ID') }}"
      location: "{{ env_var('BQ_LOCATION', '$BQ_LOCATION') }}"
      dataset: ${USER_DATASET}regrep
      threads: 10
      timeout_seconds: 300
      priority: interactive
      retries: 1

      # Specify region to run the dataproc job
      dataproc_region: "{{ env_var('REGION', '$REGION') }}"

      # Staging bucket for dataproc jobs
      gcs_bucket: "{{ env_var('GCS_INGEST_BUCKET', env_var('PROJECT_ID', '$PROJECT_ID') ~ '-ingest-bucket') }}"

      # Use this if you have a persistent dataproc cluster
      # dataproc_cluster_name: <cluster-id>
EOF
