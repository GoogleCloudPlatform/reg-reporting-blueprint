# Copyright 2022 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
ENTRYPOINT ["python3", "datagen.py"]
