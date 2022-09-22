#!/usr/bin/python3

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

"""Display recent DBT invocations and extract performance graphs from
   DBT.

   This is intended to be used with json_to_dot.py which can convert
   these performance graphs into a DOT graph for graphviz.
"""


import json
import argparse
import os

try:
  from google.cloud import bigquery
except ModuleNotFoundError:
  print('Please install google-cloud-bigquery by pip3')
  print('For example, running "pip3 install google-cloud-bigquery"')
  raise SystemExit


def dbt_recent_invocations_query(full_table_id, num):
    """Generate query for extracting DBT recent invocations"""

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
def dbt_recent_invocations(client, project_id, dataset_id, table_id, num):
    """Display recent DBT invocations"""

    full_table_id = f'{project_id}.{dataset_id}.{table_id}'
    results = client.query(dbt_recent_invocations_query(full_table_id, num))
    print('dbt_invocation_id                    start_date          end_date')
    for row in results:
        end_time = ''
        if row['end_time']:
            end_time = row['end_time'].strftime(TIME_FORMAT)
        print(row['dbt_invocation_id'],
              row['start_time'].strftime(TIME_FORMAT),
              end_time)


def dbt_invocation_query(full_table_id, dbt_invocation_id):
    """Generate query for extracting DBT performance JSON graph from DBT log"""

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



def dbt_live_invocation_query(full_table_id, project_id, location, dbt_invocation_id):
    """Generate query for extracting DBT performance JSON graph from live data"""

    return rf"""
      WITH
        StartStage AS (
          SELECT
            dbt_invocation_id,
            update_time,
            JSON_EXTRACT_SCALAR(n, "$.id") AS name,
            JSON_EXTRACT_STRING_ARRAY(n, "$.depends_on") AS depends_on
          FROM
            `{full_table_id}` AS l
            CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(l.info, "$.tree")) AS n
          WHERE
            stage='START' AND
            dbt_invocation_id='{dbt_invocation_id}'
        ),
        CreationTime AS (
          SELECT
            MIN(update_time) AS creation_time
          FROM
            StartStage
        ),
        InfoSchema AS (
          SELECT
            (SELECT ANY_VALUE(value) FROM j.labels WHERE key='dbt_invocation_id') AS dbt_invocation_id,
            DATETIME(j.creation_time) AS start_time,
            DATETIME(end_time) AS end_time,
            JSON_VALUE(PARSE_JSON(REGEXP_EXTRACT(query, r'^/\* (.*) \*/')), "$.node_id") AS name,
          FROM
            CreationTime ct
            CROSS JOIN `{project_id}.region-{location}.INFORMATION_SCHEMA.JOBS_BY_PROJECT` j
          WHERE
            j.creation_time >= ct.creation_time AND
            state='DONE' AND
            (SELECT ANY_VALUE(value) FROM j.labels WHERE key='dbt_invocation_id')='{dbt_invocation_id}'
        ),
        Combined AS (
          SELECT
            dbt_invocation_id,
            TO_JSON(ARRAY_AGG(
              STRUCT(name, depends_on, start_time, end_time)
            )) AS perf
          FROM
            StartStage s
            LEFT JOIN InfoSchema e USING (dbt_invocation_id, name)
          GROUP BY
            1
        )
      SELECT perf FROM Combined;
    """


def dbt_dump_invocation(client,
                        project_id,
                        dataset_id,
                        table_id,
                        dbt_invocation_id,
                        is_live=False):
    """
    Dump performance graph JSON for a dbt_invocation_id

    Parameters
    ----------
    client : google.cloud.bigquery.client.Client
        BigQuery client for querying
    project_id : str
        Project for the dbt log
    dataset_id : str
        Dataset for the dbt log (if live, correlates with jobs in same location)
    table_id : str
        Table id for the dbt log
    dbt_invocation_id : str
        Specific dbt_invocation_id to extract
    is_live : bool
        Whether to use running jobs or DBT results for analysis
    """

    # Fully qualified table id
    full_table_id = f"{project_id}.{dataset_id}.{table_id}"

    # Generate query
    if is_live:

        # Fetch location of dataset for jobs
        location = client.get_dataset(f"{project_id}.{dataset_id}").location

        query = dbt_live_invocation_query(full_table_id, project_id,
                                          location, dbt_invocation_id)
    else:
        query = dbt_invocation_query(full_table_id, dbt_invocation_id)

    # Run query and dump results
    results = client.query(query)
    for row in results:
        parsed = json.loads(row[0])
        print(json.dumps(parsed, indent=4, sort_keys=True))


def main():
    """Extract DBT JSON performance graph from historical (dbt_log) or live data"""

    parser = argparse.ArgumentParser(description='Extract DBT performance results')
    parser.add_argument('--project_id', type=str, default=os.getenv('PROJECT_ID'),
                        help='Project for DBT log')
    parser.add_argument('--dataset_id', type=str, required=True,
                        help='Dataset for DBT log')
    parser.add_argument('--table_id', type=str, default='dbt_log',
                        help='Table ID for DBT Log')
    parser.add_argument('--num', type=int, default=10,
                        help='Number of recent invocations to list (if none fetched)')
    parser.add_argument('--live', action='store_true',
                        help='Query INFORMATION_SCHEMA instead of dbt log (region required)')
    parser.add_argument('dbt_invocation_id', type=str, nargs='?',
                        help='DBT invocation id to extract')

    args = parser.parse_args()

    client = bigquery.Client()

    if not args.dbt_invocation_id:
        dbt_recent_invocations(client,
                               args.project_id,
                               args.dataset_id,
                               args.table_id,
                               args.num)

    else:
        dbt_dump_invocation(client,
                            args.project_id,
                            args.dataset_id,
                            args.table_id,
                            args.dbt_invocation_id,
                            args.live)


if __name__ == "__main__":
    main()
