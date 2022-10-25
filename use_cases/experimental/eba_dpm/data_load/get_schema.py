#!/usr/bin/env python3

import argparse
import subprocess
import re

# Yaml for Schema.yml
from yaml import dump

try:
    from yaml import CDumper as Dumper
except ImportError:
    from yaml import Dumper

parser = argparse.ArgumentParser(description='Extract DBT Schema from Access Database')
parser.add_argument('namespace', type=str,
                    help='Namespace for DPM database')
parser.add_argument('database', type=str,
                    help='Access databases for extracting schema')

args = parser.parse_args()

CREATE_TABLE_RE = re.compile(r"""
                    CREATE\s+TABLE\s+   # Create table
                    \[([^\]]*)\]        # Table name
                    [^(]*\(             # Start of list of fields
                             (.*?)               # Fields (non-greedy)
                    ^\);                # End of list of fields
                    """, re.DOTALL | re.MULTILINE | re.VERBOSE)
FIELD_RE = re.compile(r"""
                      \[([^\]]*)\]   # Field name
                      \s+
                      ([^,]*),?      # Datatype
                    """, re.VERBOSE)
RESERVED_COLUMNS = ['ORDER', 'ROW', 'ROWS']


def get_schema(file, namespace):
    def get_datatype(dt):
        if dt == 'Long Integer':
            return 'INT64'
        elif dt == 'Integer':
            return 'INT64'
        elif dt.startswith('Text ('):
            return 'STRING'
        elif dt.startswith('Memo/Hyperlink ('):
            return 'STRING'
        elif dt == 'DateTime':
            return 'DATETIME'
        elif dt == 'Boolean':
            return 'BOOLEAN'
        raise Exception(f'Invalid type: {dt}')

    def get_column(c):
        c = ''.join(e for e in c if e.isalnum() or e == '_')
        if c.upper() in RESERVED_COLUMNS:
            c += 'Key'
        return c

    create_sql = subprocess.check_output([
        "mdb-schema",
        "--no-drop-table",
        "--no-not-null",
        "--no-default-values",
        "--no-not_empty",
        "--no-comments",
        "--no-indexes",
        "--no-relations",
        file
    ]).decode("utf-8")

    tables = []
    for m in CREATE_TABLE_RE.findall(create_sql):
        columns = []
        for f in FIELD_RE.findall(m[1]):
            columns.append(dict(
                name=get_column(f[0]),
                data_type=get_datatype(f[1].strip()),
            ))
        tables.append(dict(
            name=f"{namespace}_{m[0]}",
            external=dict(
                location="gs://{{ env_var('GCS_INGEST_BUCKET') }}/eba_dpm/" + f"{m[0]}.csv.gz",
                options=dict(
                    allow_quoted_newlines=True,
                    format="CSV"
                ),
            ),
            columns=columns,
        ))

    return tables


if __name__ == "__main__":
    # Generate the schema
    schema = dict(
        version=2,
        sources=[dict(
            name="dpm_model",
            database="{{ env_var('PROJECT_ID') }}",
            schema="{{ env_var('EBADPM_BQ_DATA') }}",
            tables=get_schema(args.database, args.namespace)
        )],
    )

    # Dump it to stdout!
    print(dump(schema, sort_keys=False))
