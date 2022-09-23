#!/bin/bash
#
# Copyright 2022 The Reg Reporting Blueprint Authors
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

# Check ingest bucket
if [ -z "${GCS_INGEST_BUCKET}" ]; then
  echo "GCS_INGEST_BUCKET is not defined. Please source environment_variables.sh."
  exit 1
fi


#
# GCS ingest copy
#
function copy_data {
  gsutil -m cp -r sec_data rating_data "gs://${GCS_INGEST_BUCKET}/"
}


#
# Sec data download
#
BASE_SEC_URL="https://www.sec.gov/files/dera/data/financial-statement-data-sets"
function download_sec_data {
  mkdir -p sec_data
  cd sec_data

  first_year=2009
  last_year=$(date +%Y)

  year=${first_year}
  while [ ${year} -le ${last_year} ]; do
    for q in 1 2 3 4; do
      dest="${year}-q${q}"
      file="${year}q${q}.zip"

      # Skip if already downloaded
      if [ -d "${dest}" ]; then
        continue
      fi

      # Download the data
      echo "Downloading sec financial data ${file}"
      wget -q "${BASE_SEC_URL}/${file}"

      # If successful, make directory for uncompressing it and unzip it
      # Re-compress individual files and remove the downloaded file
      if [ -f "${file}" ]; then
        mkdir -p "${dest}"
        cd "${dest}"

        echo "Unzipping ${file}"
        unzip ../${file}
        rm ../${file}

        echo "Compressing ${file}"
        gzip *.txt

        cd ..
      fi
    done
    year=$((${year} + 1))
  done

  cd ..
}


#
# Ratings data download
#
BASE_RATING_URL="http://ratingshistory.info/csv/"
function download_rating_data {
  mkdir -p rating_data
  cd rating_data

  # Metadata for files to download
  date="20220601"
  provider="Standard & Poor's Ratings Services"
  types="Corporate Financial Insurance"

  for type in ${types}; do
    file="${date} ${provider} ${type}.csv"

    # Skip if file already exists
    if [ -f "${file}.gz" ]; then
      continue
    fi

    echo "Downloading rating ${file}"
    wget -q "${BASE_RATING_URL}${file}"

    # Compress file if available
    if [ -f "${file}" ]; then
      echo "Compressing ${file}"
      gzip "${file}"
    fi
  done

  cd ..
}


#
# Perform operations
#

download_sec_data
download_rating_data
copy_data

