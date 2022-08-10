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

# Load the input data
declare -a arr=( \
"ref_legal_entity_mapping"
"ref_products" \
"ref_region_codes" \
"src_current_accounts_attributes" \
"src_current_accounts_balances" \
"src_link_securities_accounts" \
"src_loans" \
"src_provisions" \
"src_securities") \

for table in "${arr[@]}"
do
  bq load \
  --replace=true \
  --source_format=CSV \
  --skip_leading_rows=1 \
  $PROJECT_ID:$HOMELOAN_BQ_DATA.$table \
  gs://$GCS_INGEST_BUCKET/homeloan/input/$table.csv \
  schema/input/$table.json
done


# Load the expected results data
declare -a arr=( \
"stg_accounts" \
"stg_products" \
"stg_provisions" \
"stg_securities") \

for table in "${arr[@]}"
do
  bq load \
  --replace=true \
  --source_format=CSV \
  --skip_leading_rows=1 \
  $PROJECT_ID:$HOMELOAN_BQ_EXPECTEDRESULTS.$table \
  gs://$GCS_INGEST_BUCKET/homeloan/expected/$table.csv \
  schema/expected/$table.json
done


