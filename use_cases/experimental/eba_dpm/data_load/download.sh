#!/bin/bash

function process_dpm_db() {
  URL=$1
  FILE=$2
  DB_FILE=$3
  NAME=$4

  if [ ! -f "${FILE}" ]; then
    echo "Downloading URL ${FILE}"
    wget --quiet "${URL}/${FILE}"

    echo "Uncompressing file ${FILE}"
    unzip -o "${FILE}"
  fi

  if [ ! -f "${DB_FILE}" ]; then
    echo "Missing output! Expected ${DB_FILE} in ${FILE}"
    exit 1
  fi

  mdb-tables -1 "${DB_FILE}" | while read table; do
    if [ ! -f "${NAME}.${table}.csv.gz" ]; then
      echo "Extracting from table ${NAME}.${table}"
      mdb-export -H -B "${DB_FILE}" "${table}" | gzip > "${NAME}.${table}.csv.gz"
    fi
  done
}

echo "Refer to https://www.eba.europa.eu/risk-analysis-and-data/dpm-data-dictionary for latest updates."

BASE_URL="https://www.eba.europa.eu/sites/default/documents/files/document_library/Risk Analysis and Data/Reporting Frameworks/Reporting framework 3.2/Phase 3/1039945/"
PHASE1="DPM Query Tool_v3_2_Ph2.zip"
PHASE1_DB="DPM Query Tool_v3_2_Ph3.accde"
PHASE2="DPM Database 3.2.phase1_.accdb.zip"
PHASE2_DB="DPM Database 3.2.phase1.accdb"

mkdir -p dpm_model
cd dpm_model
process_dpm_db "${BASE_URL}${PATH_URL}" "${PHASE1}" "${PHASE1_DB}" "dpm_query_tool"
process_dpm_db "${BASE_URL}${PATH_URL}" "${PHASE2}" "${PHASE2_DB}" "dpm_database"
cd ..

echo "Copying to GCS"
gsutil -m cp -r dpm_model/*.csv.gz "gs://${GCS_INGEST_BUCKET}/"
