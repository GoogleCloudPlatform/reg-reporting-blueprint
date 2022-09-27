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

import datetime

from airflow import models
from airflow.models import Variable

from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator


# Project and region for the repository
PROJECT_ID = Variable.get("PROJECT_ID")
REGION = Variable.get("REGION")
REPO = f'{REGION}-docker.pkg.dev/{PROJECT_ID}/reg-repo'

# Environment name is used for the namespace and service account
ENV_NAME = Variable.get("ENV_NAME")

# BigQuery location
BQ_LOCATION = Variable.get("BQ_LOCATION")


#
# Simplified version based on the following -
# https://github.com/GoogleCloudPlatform/professional-services/blob/main/examples/dbt-on-cloud-composer/basic/dag/dbt_with_kubernetes.py
#
def k8s_job(name, image_name, arguments=None, env_vars=None):
    return KubernetesPodOperator(

        # task_id is the unique identifier in Airflow,
        # name is the unique identifier in Kubernetes.
        # Keeping them the same simplifies things.
        task_id=name,
        name=name,

        # Always pull -- if image is updated, we need to use the latest
        #
        # Using specialised tags or repositories is the simplest way to
        # externally control deployed versions of steps.
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
        image=image_name,
        arguments=arguments or [],
        env_vars=env_vars or {}
    )


# Define the DAG
with models.DAG(
    dag_id='mlops-credit-poc',
    schedule_interval= None,    # Manually triggered
    catchup=False,
    default_args={
        'depends_on_past': False,
        'start_date': datetime.datetime(2022, 1, 1),
        'end_date': datetime.datetime(2100, 1, 2),
        'catchup':False,
        'catchup_by_default':False,
        'retries': 0
    }
) as dag:


    #
    # These are examples jobs to be changed!
    #

    # No-op hello world job
    hello_world = k8s_job(
        name='hello-world',
        image_name='hello-world',
        arguments=[],
        env_vars={},
    )

    # Data preparation
    data_preparation = k8s_job(
        name='data_preparation',
        image_name='hello-world',
        arguments=[],
        env_vars={},
    )

    # Univariate analysis
    univariate_analysis = k8s_job(
        name='univariate_analysis',
        image_name='hello-world',
        arguments=[],
        env_vars={},
    )
    data_preparation >> univariate_analysis

    # Variable clustering
    # This runs a Vertex AI Training job running R
    variable_clustering = k8s_job(
        name='variable_clustering',
        image_name=f'{REPO}/trainer:latest',
        arguments=[
          '--name=variable-clustering',
          f'--project_id={PROJECT_ID}',
          f'--location={REGION}',
          '--service_account=625326067249-compute@developer.gserviceaccount.com',
          '--gcs_bucket=gs://linear-catalyst-179213-europe-west1-temp/',
          f'--image_uri={REPO}/r-cluster:latest',
          '--args=linear-catalyst-179213.temp_eu.xyz',
          '--args=linear-catalyst-179213',
          '--args=temp_eu',
          '--args=xyz2',
        ],
        env_vars={},
    )
    univariate_analysis >> variable_clustering

    # Train job
    # This runs a container that launches Vertex AI for training
    # ... and uploads it afterwards.
    train_job = k8s_job(
        name='train_and_deployjob',
        image_name=f'{REPO}/trainer:latest',
        arguments=[
          '--name=special-model',
          f'--project_id={PROJECT_ID}',
          f'--location={REGION}',
          '--service_account=625326067249-compute@developer.gserviceaccount.com',
          f'--args=--project-id={PROJECT_ID}',
          '--args=--table-id=linear-catalyst-179213.temp_syd.xyz',
          '--gcs_bucket=gs://linear-catalyst-179213-europe-west1-temp/',
          f'--image_uri={REPO}/custom:latest',
          '--upload=True',
        ],
        env_vars={},
    )
    variable_clustering >> train_job

    # Train job (second model type)
    # This runs a container that launches Vertex AI for training
    # ... and uploads it afterwards.
    train_job2 = k8s_job(
        name='train_and_deployjob_2',
        image_name=f'{REPO}/trainer:latest',
        arguments=[
          '--name=special-model',
          f'--project_id={PROJECT_ID}',
          f'--location={REGION}',
          '--service_account=625326067249-compute@developer.gserviceaccount.com',
          f'--args=--project-id={PROJECT_ID}',
          '--args=--table-id=linear-catalyst-179213.temp_syd.xyz',
          '--gcs_bucket=gs://linear-catalyst-179213-europe-west1-temp/',
          f'--image_uri={REPO}/custom:latest',
          '--upload=True',
        ],
        env_vars={},
    )
    variable_clustering >> train_job2
