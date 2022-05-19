FROM fishtownanalytics/dbt:0.20.0

# use dbt user
RUN chmod u+s /usr/bin/whoami
RUN groupadd -r dbt && useradd -r -g dbt dbt

# Install prerequisites
RUN apt-get update && apt-get install -y curl
RUN curl -sSL https://sdk.cloud.google.com | bash

# Set environment variables
ENV DBT_DIR /dbt_demo

#Copy DBT project
COPY . $DBT_DIR

WORKDIR $DBT_DIR
RUN chown -R dbt:dbt $DBT_DIR/

USER dbt

ENTRYPOINT dbt run --profiles-dir profiles

