# Copyright 2022 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Data Generator
#
# This script generates sample data in the format required by the CRE reports

from datetime import date
from io import StringIO
import random
import csv
import argparse

import names
from tqdm import tqdm
from google.cloud import bigquery


def upload_rows_to_bigquery(client, table_id, num_rows, row_generator):
    """
    Load data into BigQuery
    :param client:         BigQuery Client
    :param table_id:       Full table_id target for BigQuery
    :param num_rows:       Number of rows to generate
    :param row_generator:  Function to generate rows
    """

    # Construct a load job
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
    )

    # In-memory buffer for data to be uploaded
    memory_buffer = StringIO()

    # Initialize CSV writer
    keys = row_generator().keys()
    dict_writer = csv.DictWriter(memory_buffer, keys)
    dict_writer.writeheader()

    # Generate all of the rows
    for _ in tqdm(range(num_rows), f"{table_id}: Generating {num_rows} rows"):
        dict_writer.writerow(row_generator())

    # Load into BigQuery
    print(f"{table_id}: Loading data into BigQuery")
    job = client.load_table_from_file(memory_buffer, table_id,
                                      job_config=job_config, rewind=True)

    job.result()  # Waits for the job to complete.

    # Gather statistics of target table
    table = client.get_table(table_id)
    print(f"{table_id}: There are {table.num_rows} rows and " +
          f"{len(table.schema)} columns")


if __name__ == "__main__":
    # Arguments
    parser = argparse.ArgumentParser(description='Create random CRE records')
    parser.add_argument('--project_id',
                        required=True,
                        help='The GCP project ID where the data should be loaded')
    parser.add_argument('--bq_dataset',
                        required=True,
                        help='The BigQuery dataset where the data should be loaded')
    parser.add_argument('--num_records_stock',
                        default=10, type=int, nargs='?',
                        help='Number of records to generate for the stock data')
    parser.add_argument('--num_records_flow',
                        default=11, type=int, nargs='?',
                        help='Number of records to generate for the flow data')

    args = parser.parse_args()

    bigquery_client = bigquery.Client(project=args.project_id)

    generator = RandomDataGenerator()

    upload_rows_to_bigquery(
        bigquery_client,
        f"{args.project_id}.{args.bq_dataset}.boe_cre_loan_level_stock_granular",
        args.num_records_stock,
        generator.generate_stock_record)

    upload_rows_to_bigquery(
        bigquery_client,
        f"{args.project_id}.{args.bq_dataset}.boe_cre_loan_level_flow_granular",
        args.num_records_flow,
        generator.generate_flow_record)
