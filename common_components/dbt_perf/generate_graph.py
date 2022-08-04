#!/usr/bin/python3

# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import json
import argparse
import os

from google.cloud import bigquery

parser = argparse.ArgumentParser(description='Extract DBT results')
parser.add_argument('--project_id', type=str, default=os.getenv('PROJECT_ID'),
                    help='Project for DBT log')
parser.add_argument('--dataset_id', type=str, required=True,
                    help='Dataset for DBT log')
parser.add_argument('--table_id', type=str, default='dbt_log',
                    help='Table ID for DBT Log')
parser.add_argument('--num', type=int, default=10,
                    help='Number of recent invocations to list (if none fetched)')
parser.add_argument('dbt_invocation_id', type=str, nargs='?',
                    help='DBT invocation id to extract')



def dbt_recent_invocations_query(full_table_id, num):
    return f"""
      SELECT
        dbt_invocation_id,
        MIN(IF(stage='START', update_time, NULL)) AS start_time,
        MAX(IF(stage='END', update_time, NULL)) AS end_time
      FROM
        `{full_table_id}`
      GROUP BY
        1
      ORDER BY
        start_time DESC
      LIMIT
        {num};
    """


TIME_FORMAT = '%Y-%m-%d %H:%M:%S'
def dbt_recent_invocations(client, full_table_id, num):
    results = client.query(dbt_recent_invocations_query(full_table_id, num))
    print('dbt_invocation_id                    start_date          end_date')
    for row in results:
        print(row['dbt_invocation_id'],
              row['start_time'].strftime(TIME_FORMAT),
              row['end_time'].strftime(TIME_FORMAT))


def dbt_invocation_query(full_table_id, dbt_invocation_id):
    return f"""
      WITH
        StartStage AS (
          SELECT
            dbt_invocation_id,
            JSON_EXTRACT_SCALAR(n, "$.id") AS name,
            JSON_EXTRACT_STRING_ARRAY(n, "$.depends_on") AS depends_on
          FROM
            `{full_table_id}` AS l
            CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(l.info, "$.tree")) AS n
          WHERE
            stage='START' AND
            dbt_invocation_id='{dbt_invocation_id}'
        ),
        EndStage AS (
          SELECT
            dbt_invocation_id,
            JSON_EXTRACT_SCALAR(n, "$.id") AS name,
            JSON_EXTRACT_SCALAR(t, "$.started_at") AS start_time,
            JSON_EXTRACT_SCALAR(t, "$.completed_at") AS end_time,
          FROM
            `{full_table_id}` AS l
            CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(l.info, "$")) AS n
            CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(n, "$.timing")) AS t
          WHERE
            stage='END' AND
            JSON_EXTRACT_SCALAR(n, "$.status")='success' AND
            dbt_invocation_id='{dbt_invocation_id}'
        ),
        Combined AS (
          SELECT
            dbt_invocation_id,
            TO_JSON(ARRAY_AGG(
              STRUCT(name, depends_on, start_time, end_time)
            )) AS perf
          FROM
            StartStage s
            LEFT JOIN EndStage e USING (dbt_invocation_id, name)
          GROUP BY
            1
        )
      SELECT perf FROM Combined;
    """

def dbt_dump_invocation(client, full_table_id, dbt_invocation_id):
    results = client.query(dbt_invocation_query(full_table_id, dbt_invocation_id))
    for row in results:
        parsed = json.loads(row[0])
        print(json.dumps(parsed, indent=4, sort_keys=True))


def main():
    args = parser.parse_args()

    client = bigquery.Client()

    full_table_id = f"{args.project_id}.{args.dataset_id}.{args.table_id}"

    if not args.dbt_invocation_id:
        dbt_recent_invocations(client, full_table_id, args.num)

    dbt_dump_invocation(client, full_table_id, args.dbt_invocation_id)


if __name__ == "__main__":
    main()

