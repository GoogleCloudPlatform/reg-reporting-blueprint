FROM python:3.8.5

# Install required system packages and cleanup to reduce image size
RUN apt-get update -y && \
  apt-get install --no-install-recommends -y -q \
  git libpq-dev python-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install data build tool
RUN pip install -U pip
RUN pip install \
        dbt-core~=1.1.0 \
        dbt-bigquery==1.1.0

# Create users
ENV HOME /dbt/
RUN useradd -rm -d $HOME -s /bin/bash -u 1000 dbt
USER dbt

# Copy files to the image
COPY --chown=dbt use_cases/examples/home_loan_delinquency/dbt $HOME/use_cases/examples/home_loan_delinquency/dbt/
COPY --chown=dbt common_components/monitoring/dbt_log $HOME/common_components/monitoring/dbt_log/

# Start DBT dir
WORKDIR $HOME/use_cases/examples/home_loan_delinquency/dbt

# Run DBT debs to install dependencies
RUN dbt deps

# Run dbt. Profiles defaults locally through DBT_PROFILES_DIR.
ENV DBT_PROFILES_DIR /dbt/use_cases/examples/home_loan_delinquency/dbt/profiles
ENTRYPOINT [ "dbt" ]
