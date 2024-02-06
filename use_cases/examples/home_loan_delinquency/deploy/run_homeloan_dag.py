# Copyright 2023 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Composer DAG to excute the Homeloan Delinquency workflow

import datetime

from airflow.models import Variable

from dag_utils.tools import DBTComposerPodOperator, ComposerPodOperator
from airflow.models import Param
from airflow.decorators import dag


# Project and region for the repository
PROJECT_ID = Variable.get("PROJECT_ID")
REGION = Variable.get("REGION")

# GCS Ingest Bucket
GCS_INGEST_BUCKET = Variable.get("INGEST_BUCKET")

# BigQuery location
BQ_LOCATION = Variable.get("BQ_LOCATION")

# Tag to run (default is latest if not set)
TAG = Variable.get("tag", default_var="latest")

# Repository
REPO = Variable.get("REPO")


# Define the DAG
@dag(
    schedule_interval="@daily",
    catchup=False,
    start_date=datetime.datetime(2022, 1, 1),
    default_args={
        "retries": 2
    },
    params={
        'tag': Param(
            default=TAG,
            type='string',
        ),
        'repo': Param(
            default=REPO,
            type='string',
        ),
    },
)
def home_loan_delinquency():

    load_job = ComposerPodOperator(
        task_id='bq-data-load',
        name='bq-data-load',
        image='{{ params.repo }}/homeloan-bq-data-load:{{ params.tag }}',
        env_vars={
            'GCS_INGEST_BUCKET': GCS_INGEST_BUCKET,
            'PROJECT_ID': PROJECT_ID,
        }
    )

    run_hld_report = DBTComposerPodOperator(
        task_id='hld-run',
        name='hld-run',
        image='{{ params.repo }}/homeloan-dbt:{{ params.tag }}',
        cmds=[
            '/bin/bash',
            '-xc',
            '&&'.join([
                'dbt run',
                'dbt docs generate --static',
            ]),
        ],
        dbt_vars={
            'reporting_day': '{{ ds }}',
        },
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'BQ_LOCATION': BQ_LOCATION,
            'REGION': REGION,
            'GCS_INGEST_BUCKET': GCS_INGEST_BUCKET,
        },
    )

    test_hld_dq = DBTComposerPodOperator(
        task_id='hld-dq-test',
        name='hld-dq-test',
        image='{{ params.repo }}/homeloan-dbt:{{ params.tag }}',
        cmds=[
            '/bin/bash',
            '-xc',
            '&&'.join([
                'dbt --no-use-colors test -s test_type:generic',
                'dbt docs generate --static',
            ]),
        ],
        dbt_vars={
            'reporting_day': '{{ ds }}',
        },
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'BQ_LOCATION': BQ_LOCATION,
            'REGION': REGION,
            'GCS_INGEST_BUCKET': GCS_INGEST_BUCKET,
        }
    )

    test_hld_regression = DBTComposerPodOperator(
        task_id='hld-regression-test',
        name='hld-regression-test',
        image='{{ params.repo }}/homeloan-dbt:{{ params.tag }}',
        cmds=[
            '/bin/bash',
            '-xc',
            '&&'.join([
                'dbt --no-use-colors test -s test_type:singular',
                'dbt docs generate --static',
            ]),
        ],
        dbt_vars={
            'reporting_day': '{{ ds }}',
        },
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'BQ_LOCATION': BQ_LOCATION,
            'REGION': REGION,
            'GCS_INGEST_BUCKET': GCS_INGEST_BUCKET,
        }
    )

    load_job >> run_hld_report
    run_hld_report >> test_hld_regression
    run_hld_report >> test_hld_dq


home_loan_delinquency()
