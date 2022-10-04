# Using Python 3.7 slim. Note that if CUDA/CUDNN is required, the
# Vertex AI provided may be used or one provided by NVidia
# (nvidia/cuda) with Python installed.
FROM python:3.7-slim

# Keep files in /root
WORKDIR /root

# Upgrade pip3
RUN pip3 install --no-cache-dir --upgrade pip

# Installs additional packages
# Ideally, this would be managed through requirements.txt or other standard
# mechanisms.
RUN pip3 install --no-cache-dir \
  tensorflow-datasets \
  tensorflow-io \
  tensorflow \
  tensorboardX \
  google-cloud-bigquery \
  google-cloud-aiplatform[tensorboard]

# Copies the trainer code to the docker image.
COPY . /root

# Sets up the entry point to invoke the trainer.
ENTRYPOINT ["python3", "-m", "trainer.task"]
