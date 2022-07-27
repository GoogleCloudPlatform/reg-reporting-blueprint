
import datetime
import json
import os

from airflow import models
from airflow.models import Variable
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator

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
# REPO = f'{REGION}-docker.pkg.dev/{PROJECT_ID}/reg-repo' # if using artefacts registry
REPO = f'gcr.io/{PROJECT_ID}'  # if using container registry


#
# Simplified version based on the following -
# https://github.com/GoogleCloudPlatform/professional-services/blob/main/examples/dbt-on-cloud-composer/basic/dag/dbt_with_kubernetes.py
#
def dbt_job(name, image_name, arguments=[], env_vars={}, repo=REPO):
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
    dag_id='home-loan-delinquency',
    schedule_interval= "0 * * * *",
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

    load_job = dbt_job(
        name='bq-data-load',
        image_name='bq-data-load',
        env_vars={
            'HOMELOAN_BQ_DATA': 'homeloan_data',
            'HOMELOAN_BQ_EXPECTEDRESULTS': 'homeloan_expectedreresults',
            'PROJECT_ID': PROJECT_ID,
            'GCS_INGEST_BUCKET': GCS_INGEST_BUCKET,
        }
    )

    run_hld_report = dbt_job(
        name='hld-run',
        image_name='home-loan-delinquency',
        arguments=[
            "run",
            "--vars",
            json.dumps({
                # { ds } is a template that it interpolated in the
                # KubernetesPodOperator from Airflow as the execution
                # date
                "reporting_day": "{{ ds }}",
            })
        ],
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'PROJECT_ID_PRD': PROJECT_ID,
            'HOMELOAN_BQ_DEV': 'homeloan_dev',
            'HOMELOAN_BQ_DATA': 'homeloan_data',
            'HOMELOAN_BQ_EXPECTEDRESULTS': 'homeloan_expectedreresults',
            'BQ_LOCATION': BQ_LOCATION,
        }
    )

    test_hld_dq = dbt_job(
        name='hld-dq-test',
        image_name='home-loan-delinquency',
        arguments=[
            "test",
            "-s",
            "test_type:singular",
            "--vars",
            json.dumps({
                # { ds } is a template that it interpolated in the
                # KubernetesPodOperator from Airflow as the execution
                # date
                "reporting_day": "{{ ds }}",
            })
        ],
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'PROJECT_ID_PRD': PROJECT_ID,
            'HOMELOAN_BQ_DEV': 'homeloan_dev',
            'HOMELOAN_BQ_DATA': 'homeloan_data',
            'HOMELOAN_BQ_EXPECTEDRESULTS': 'homeloan_expectedreresults',
            'BQ_LOCATION': BQ_LOCATION,
        }
    )

    test_hld_regression = dbt_job(
        name='hld-regression-test',
        image_name='home-loan-delinquency',
        arguments=[
            "test",
            "-s",
            "test_type:generic",
            "--vars",
            json.dumps({
                # { ds } is a template that it interpolated in the
                # KubernetesPodOperator from Airflow as the execution
                # date
                "reporting_day": "{{ ds }}",
            })
        ],
        env_vars={
            'PROJECT_ID': PROJECT_ID,
            'PROJECT_ID_PRD': PROJECT_ID,
            'HOMELOAN_BQ_DEV': 'homeloan_dev',
            'HOMELOAN_BQ_DATA': 'homeloan_data',
            'HOMELOAN_BQ_EXPECTEDRESULTS': 'homeloan_expectedreresults',
            'BQ_LOCATION': BQ_LOCATION,
        }
    )

    load_job >> run_hld_report
    run_hld_report >> test_hld_regression
    run_hld_report >> test_hld_dq

