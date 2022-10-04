# Logistic regression model in tensorflow
# Productionising Trainer Code

## Environment

This walk-through assumes some constants. Configure them appropriately.
```
export PROJECT_ID=$(gcloud config get project)
export DATASET_ID=mtronci_pd_lge
export TRAINING_DATA_TABLE=training_data
export REGION=europe-west4
export BUCKET=gs://${PROJECT_ID}-temp
export SERVICE_ACCOUNT=1086447207088-compute@developer.gserviceaccount.com
export TENSORBOARD_INSTANCE=projects/1086447207088/locations/europe-west4/tensorboards/8858052701456433152
```



## Run locally
Install requirements
```
pip3 install -r requirements.txt
```
You may have to install a certificate locally
```
curl -Lo ~/roots.pem https://pki.google.com/roots.pem
export GRPC_DEFAULT_SSL_ROOTS_FILE_PATH="~/roots.pem"
```

To run locally, just execute the trainer script locally, like this.
```
python3 -m trainer.task \
  --project-id=${PROJECT_ID} \
  --table-id=${PROJECT_ID}.${CREDIT_POC_BQ_DATA}.${TRAINING_DATA_TABLE} \
  --model-dir=./model \
  --tensorboard-log-dir=./logs\
  --epochs=30 \
  --experiment-id=local \
  --tensorboard=${TENSORBOARD_INSTANCE}
```
Note that the table-id must point to a table containing only:
* the features to the model, in individual columns (i.e. no struct) \n
* is_test_data: a boolean column indicating whether the data is test (otherwise is training) \n
* will_default_1y: used as the actual label"

## Building the container
Note that you must create a repository for container images in your location.
The repository name used in this example is rep-repo.

See [this](https://cloud.google.com/artifact-registry/docs/docker/store-docker-container-images). Create a repository
and configure authentication with docker (very important, otherwise docker will say permission denied).
Building can be done locally:
```
docker build .

# Tag it locally
docker tag <hash-of-build> ${REGION}-docker.pkg.dev/${PROJECT_ID}/reg-repo/custom

# Push it to the repository
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/reg-repo/custom
```

Or using Cloud Build:
```
gcloud builds submit . --region=${REGION}
```

## Running the container locally
Running locally requires specifying the CLOUD_ML_PROJECT_ID environment
variable and mapping in the proper credentials.

NOTE: It is assumed that gcloud auth application-default login has been run
locally prior to this. You also require a GCS bucket for writing the model
results to.

Local docker:
```
docker run \
  -e CLOUD_ML_PROJECT_ID=${PROJECT_ID} \
  -v $HOME/.config/gcloud:/root/.config/gcloud \
  ${REGION}-docker.pkg.dev/${PROJECT_ID}/reg-repo/custom \
  --project-id=${PROJECT_ID} \
  --table-id=${PROJECT_ID}.${DATASET_ID}.${TRAINING_DATA_TABLE} \
  --model-dir=./model \
  --tensorboard-log-dir=./logs \
  --epochs=30 \
  --experiment-id=container-test \
  --tensorboard=${TENSORBOARD_INSTANCE}
```

NOTE: The service-account must have access to read from BigQuery and write to
GCS. You can use any service account you have access to. Vertex AI will use
service agents by default (see
[this](https://cloud.google.com/vertex-ai/docs/general/access-control#service-agents))
if not specified.

## Running the container on vertex AI
Running this on Vertex AI:
```
gcloud ai custom-jobs create \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --worker-pool-spec=machine-type="n1-standard-4",container-image-uri="${REGION}-docker.pkg.dev/${PROJECT_ID}/reg-repo/custom" \
  --display-name='tf-logistic-regression' \
  --service-account="${SERVICE_ACCOUNT}" \
  --args="--project-id=${PROJECT_ID},--table-id=${PROJECT_ID}.${DATASET_ID}.${TRAINING_DATA_TABLE},--model-dir=./model,--tensorboard-log-dir=./logs,--epochs=30,--tensorboard=${TENSORBOARD_INSTANCE},--experiment-id=vertex-test"
```

## Running from Airflow
Airflow can launch Vertex AI (as a macro orchestrator) using the following API [here](https://airflow.apache.org/docs/apache-airflow-providers-google/stable/_api/airflow/providers/google/cloud/operators/vertex_ai/custom_job/index.html#airflow.providers.google.cloud.operators.vertex_ai.custom_job.CreateCustomTrainingJobOperator).


## Next Steps
More may need to be done in practice:
 * Any suitable tests on the models. Generally, unit tests should be applied to
   the libraries. Tests should be applied to the model performance.
 * Creation of or deployment to model endpoints for online service.
 * Performance optimization for parallel workers or GPU-enabled workers. For
   distributed workers, Keras provides
   [capability](https://www.tensorflow.org/tutorials/distribute/keras). Vertex
   AI can manage this through the machine spec and replica count.

