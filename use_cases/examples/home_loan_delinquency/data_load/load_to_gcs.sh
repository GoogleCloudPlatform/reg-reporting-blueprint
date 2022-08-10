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

export error_no_path_to_data="
Error: you must pass the location of the data to be loaded as a parameter.\nFor example: . ./load_to_gcs.sh ../../input/
"

export path_to_data=$1

if [ -z $1 ]
then
  echo -e $error_no_path_to_data
  exit 1
fi

subdir=${path_to_data##*/}

echo -e "Copying the files from $path_to_data"
gsutil cp -r $path_to_data/* gs://$GCS_INGEST_BUCKET/homeloan/$subdir/


