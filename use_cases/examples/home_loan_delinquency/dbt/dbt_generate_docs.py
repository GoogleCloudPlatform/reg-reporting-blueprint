#!/usr/bin/env python3

import os
import sys
import json
import subprocess
import argparse

from google.cloud.storage import client, bucket, blob


#
# Generate static documentation
#
def generate_static_docs(dbt_project_dir=None, subs=None):

  if not subs:
    subs=dict()

  # Find path of target (using script as root of DBT project)
  dbt_target = os.path.join(dbt_project_dir, 'target')

  # Data structure we want to substitute for the actual contents
  # of manifest and catalog
  search_str = '[i("manifest","manifest.json"+t),i("catalog","catalog.json"+t)]'
  subs[search_str] = json.dumps([
    {
      'label': 'manifest',
      'data': json.load(open(os.path.join(dbt_target, 'manifest.json')))
    },
    {
      'label': 'catalog',
      'data': json.load(open(os.path.join(dbt_target, 'catalog.json')))
    }
  ])

  # Read current index.html
  index = open(os.path.join(dbt_target, 'index.html')).read()

  # Replace substitutions
  for (key, value) in subs.items():
    index = index.replace(key, value)

  # Write new static index.html with our substitutions
  target_path = os.path.join(dbt_target, 'static-index.html')
  open(os.path.join(dbt_target, 'static-index.html'), 'w').write(index)
  print(f'Saved new docs as {target_path}')


#
# Generate normal DBT documentations
#
def generate_dbt_docs(dbt_project_dir=None):
  subprocess.run(["dbt", "docs", "generate"], cwd=dbt_project_dir)


parser = argparse.ArgumentParser(
    prog = 'static_index',
    description = 'Generates static index for DBT with substitutions')
parser.add_argument('--dbt_project_dir', nargs='?',
                    default=os.path.dirname(sys.argv[0]))
parser.add_argument('--build_ref', nargs='?',
                    default=os.environ.get('BUILD_REF', 'unset'))
parser.add_argument('--save_gcs', nargs='?',
                    default=os.environ.get('GCS_DOCS_BUCKET', None))

args = parser.parse_args()

#
# Save static documentation to GCS
#
def save_static_docs(gcs_bucket, gcs_object, dbt_project_dir):

  from google.cloud.storage import client

  source_file = os.path.join(dbt_project_dir, 'target', 'static-index.html')
  print(f'Uploading {source_file} to object gs://{gcs_bucket}/{gcs_object} ')
  target_blob = client.Client().bucket(gcs_bucket).blob(gcs_object)
  target_blob.upload_from_filename(source_file)



# generate_dbt_docs(args.dbt_project_dir)

generate_static_docs(args.dbt_project_dir, subs={
    '%{BULID_REF}':  args.build_ref,
    '%{COMMIT_SHA}': args.commit_sha,
})

if args.save_gcs:
  save_static_docs(args.save_gcs, 'build/' + args.build_ref + '/index.html', args.dbt_project_dir)

