FROM python:3.9

# Install required system packages and cleanup to reduce image size
RUN apt-get update -y && \
  apt-get install --no-install-recommends -y -q \
  git libpq-dev python-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install data build tool
RUN pip install -U pip
RUN pip install \
        dbt-core~=1.2.0 \
        dbt-bigquery==1.2.0

# Create users
ENV DBT_DIR /dbt/
RUN useradd -rm -d $DBT_DIR -s /bin/bash -u 1000 dbt
WORKDIR $DBT_DIR
USER dbt

# Copy files to the image
COPY --chown=dbt . $DBT_DIR

# Run DBT debs to install dependencies
RUN dbt deps

# Run dbt. Profiles defaults locally through DBT_PROFILES_DIR.
ENV DBT_PROFILES_DIR /dbt/profiles
ENTRYPOINT [ "dbt" ]
