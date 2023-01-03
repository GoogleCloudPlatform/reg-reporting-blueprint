#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import argparse


def main(dbt_project_dir, build_ref, gcs_bucket):

  # Find path of target (using script as root of DBT project)
  dbt_target = os.path.join(dbt_project_dir, 'target')

  # Read current index.html
  index = open(os.path.join(dbt_target, 'index.html')).read()

  # Data structure we want to substitute for the actual contents
  # of manifest and catalog
  index.replace(
    '[i("manifest","manifest.json"+t),i("catalog","catalog.json"+t)]',
    json.dumps([
      {
        'label': 'manifest',
        'data': json.load(open(os.path.join(dbt_target, 'manifest.json')))
      },
      {
        'label': 'catalog',
        'data': json.load(open(os.path.join(dbt_target, 'catalog.json')))
      }
    ])
  )

  # Write new static index.html with our substitutions
  target_path = os.path.join(dbt_target, 'static-index.html')
  open(os.path.join(dbt_target, 'static-index.html'), 'w').write(index)
  print(f'Saved new docs as {target_path}')

  if gcs_bucket:
    from google.cloud.storage import client

    print(f'Uploading {target_path} to bucket {gcs_bucket}')
    target_blob = client.Client().bucket(gcs_bucket).blob(
        'build/' + build_ref + '/index.html')
    target_blob.upload_from_filename(target_path)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
      prog = 'static_index',
      description = 'Generates static index for DBT with substitutions')
  parser.add_argument('--dbt_project_dir', nargs='?',
                      default=os.path.dirname(sys.argv[0]))
  parser.add_argument('--build_ref', nargs='?',
                      default=os.environ.get('BUILD_REF', 'unset'))
  parser.add_argument('--gcs_bucket', nargs='?',
                      default=os.environ.get('GCS_DOCS_BUCKET', None))

  args = parser.parse_args()

  main(
      args.dbt_project_dir,
      args.build_ref,
      args.gcs_bucket)
