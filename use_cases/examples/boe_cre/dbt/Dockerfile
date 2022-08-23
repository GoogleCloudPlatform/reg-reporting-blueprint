FROM python:3.9

# Default build ARGs
ARG BUILD_TAG=dev
ENV BUILD_TAG=${BUILD_TAG}
ARG BULID_COMMIT=dev
ENV BUILD_COMMIT=${BUILD_COMMIT}

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
        dbt-bigquery~=1.2.0

# Create users
ENV HOME /dbt/
RUN useradd -rm -d $HOME -s /bin/bash -u 1000 dbt
WORKDIR $HOME
USER dbt

# Copy files to the image
COPY --chown=dbt . $HOME

# Run DBT debs to install dependencies
RUN dbt deps

# Run dbt. Profiles defaults locally through DBT_PROFILES_DIR.
ENV DBT_PROFILES_DIR $HOME/profiles
ENTRYPOINT [ "dbt" ]
