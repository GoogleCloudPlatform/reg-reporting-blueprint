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
