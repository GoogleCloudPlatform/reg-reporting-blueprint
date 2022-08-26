# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM google/cloud-sdk:latest

# Create users
ENV HOME /home/user/
RUN useradd -rm -d $HOME -s /bin/bash -u 1001 user
WORKDIR $HOME
USER user

# Need to pass environment variables used in the script to read to the data from GCS and know where to copy on BQ

# Copy files to the image
COPY --chown=user . $HOME

# Run script
ENTRYPOINT ["./load_to_bq.sh"]
