FROM python:3.8.5

# Install required system packages and cleanup to reduce image size
RUN apt-get update -y && \
  apt-get install --no-install-recommends -y -q \
  git libpq-dev python-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create users
ENV HOME /user/
RUN useradd -rm -d $HOME -s /bin/bash -u 1000 user
WORKDIR $HOME
USER user

# Copy files to the image
COPY --chown=user . $HOME

# Install dependencies
RUN pip install -U pip
RUN pip install -r requirements.txt

# Run dbt. Profiles defaults locally through DBT_PROFILES_DIR.
ENTRYPOINT ["python3", "data_generator.py"]
