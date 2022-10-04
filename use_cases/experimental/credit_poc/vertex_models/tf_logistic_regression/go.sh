#!/bin/bash

export PROJECT_ID=$(gcloud config get project)
export REGION=europe-west1
export BUCKET=gs://${PROJECT_ID}-temp

# --worker-pool-spec=machine-type="n1-standard-4",local-package-path=.,python-module=trainer.task,executor-image-uri=europe-docker.pkg.dev/vertex-ai/training/tf-cpu.2-8:latest,requirements=requirements.txt \
gcloud ai custom-jobs create \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --worker-pool-spec=machine-type="n1-standard-4",custom-image-uri=europe-docker.pkg.dev/linear-catalyst-179213/reg-repo/custom:latest \
  --display-name='test-training' \
  --service-account="625326067249-compute@developer.gserviceaccount.com" \
  --args=--project-id=linear-catalyst-179213,--table-id=linear-catalyst-179213.temp_syd.xyz
