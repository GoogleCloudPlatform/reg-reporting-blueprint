# Data Generator for CRE
This application generates sample data as per the requirements of the Commercial Real Estate report.

# Run the program locally
```
python3 data_generator.py --project_id=$PROJECT_ID --bq_dataset=$CRE_BQ_DATA
```

# Build the image locally
```
docker build . -t cre_data:latest
```

# Execute container locally
```
docker run --user 0 -v $HOME/.config/gcloud/:/user/.config/gcloud cre_data --project_id=$PROJECT_ID --bq_dataset=$CRE_BQ_DATA
```

NOTE: The -v maps the local `gcloud auth application-default login` details into
the container, and --user 0 runs the container as root to prevent permission
issues with the mounted directory. This is an work-around to run locally and
is intended for development and testing purposes only.

# Create containerised data load app
```
gcloud builds submit --tag $CRE_GCR_DATALOAD
```

