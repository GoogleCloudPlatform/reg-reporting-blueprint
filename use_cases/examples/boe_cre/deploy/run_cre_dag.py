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

# Composer DAG to excute the CRE workflow

import datetime
import json
import os

from airflow import models
from airflow.models import Variable

# Project and region for the repository
PROJECT_ID = Variable.get("PROJECT_ID")
REGION = Variable.get("REGION")

# GCS Ingest Bucket
GCS_INGEST_BUCKET = Variable.get("GCS_INGEST_BUCKET")

# Environment name is used for the namespace and service account
ENV_NAME = Variable.get("ENV_NAME")

# BigQuery location
BQ_LOCATION = Variable.get("BQ_LOCATION")

# Inferred repository
REPO = f'gcr.io/{PROJECT_ID}'  # if using container registry


#
# Simplified version based on the following -
# https://github.com/GoogleCloudPlatform/professional-services/blob/main/examples/dbt-on-cloud-composer/basic/dag/dbt_with_kubernetes.py
#
def containerised_job(name, image_name, arguments=[], env_vars={}, repo=REPO):
    """
    Returns a KubernetesPodOperator, which can execute a containerised step
    :param name: the name of the containerised step
    :param image_name: the name of the image to use
    :param arguments: arguments required by the job
    :param env_vars: environment variables for the job
    :param repo: fully qualified path to the repo (optional, and defaulted to f'gcr.io/{PROJECT_ID}'
    :return: the KubernetesPodOperator which executes the containerised step
    """
    from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
    return KubernetesPodOperator(

        # task_id is the unique identifier in Airflow,
        # name is the unique identifier in Kubernetes.
        # Keeping them the same simplifies things.
        task_id=name,
        name=name,

        # Always pull -- if image is updated, we need to use the latest
        image_pull_policy='Always',

        # namespace and k8s service account (Kubernetes)
        # have the correct permissions setup with Workload Identity
        namespace=ENV_NAME,
        service_account_name=ENV_NAME,

        # Capture all of the logs
        get_logs=True,               # Capture logs from the pod
        log_events_on_failure=True,  # Capture and log events in case of pod failure
        is_delete_operator_pod=True, # To clean up the pod after runs

        # Image for this particular job
        image=f'{repo}/{image_name}:latest',
        arguments=arguments,
        env_vars=env_vars
    )


# Define the DAG
with models.DAG(
    dag_id='boe_commercial_real_estate',
    schedule_interval= "00 13 * * *",
    catchup=False,
    default_args={
        'depends_on_past': False,
        'start_date': datetime.datetime(2022, 1, 1),
        'end_date': datetime.datetime(2100, 1, 2),
        'catchup': False,
        'catchup_by_default': False,
        'retries': 0
    }
) as dag:

    generate_data_job = containerised_job(
        name='generate-data',
        image_name='cre-data_generator',
        env_vars={
            'PROJECT_ID': PROJECT_ID,
        },
        arguments=[
            # The project where the data will be ingested
            '--project_id', PROJECT_ID,
            # The BQ dataset where the data will be ingested
            '--bq_dataset', 'boe_cre_data',
        ]
    )

    run_cre_report = containerised_job(
        name='transform-data',
        image_name='cre-dbt',
        arguments=[
            "run",
        ],
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'BQ_LOCATION': BQ_LOCATION,
            'CRE_BQ_DEV': 'boe_cre_dev',
            'CRE_BQ_DATA': 'boe_cre_data',
        }
    )

    test_cre_report = containerised_job(
        name='data-quality-test',
        image_name='cre-dbt',
        arguments=[
            "test",
        ],
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'BQ_LOCATION': BQ_LOCATION,
            'CRE_BQ_DEV': 'boe_cre_dev',
            'CRE_BQ_DATA': 'boe_cre_data',
        }
    )

    generate_data_job >> run_cre_report >> test_cre_report

