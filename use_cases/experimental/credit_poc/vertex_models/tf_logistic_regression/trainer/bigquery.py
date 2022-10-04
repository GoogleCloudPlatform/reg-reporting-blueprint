from google.cloud import bigquery

from tensorflow.python.framework import dtypes
from tensorflow_io.bigquery import BigQueryClient


class BigQuery():
    """BigQuery utilities for Tensorflow Training"""

    def convert_tf_datatype(bigquery_datatype):
        """Convert BigQuery datatypes into a Tensorflow datatype"""

        if bigquery_datatype == 'FLOAT64':
            return dtypes.float64
        elif bigquery_datatype == 'STRING':
            return dtypes.string
        elif bigquery_datatype == 'BOOL':
            return dtypes.bool
        elif bigquery_datatype == 'INT64':
            return dtypes.int64
        else:
            raise Exception(f'Invalid datatype: {bigquery_datatype}')

    def convert_tf_schema(rows):
        """Convert BigQuery schema (from INFORMATION SHEMA) to Tensorflow"""

        schema = {}
        for r in rows:
            schema[r.column_name] = {
                "output_type": BigQuery.convert_tf_datatype(r.data_type),
                "mode": (BigQueryClient.FieldMode.NULLABLE if r.is_nullable
                         else BigQueryClient.FieldMode.REQUIRED)
            }

        return schema

    def __init__(self, project_id):
        """Initialize utilities with a project_id"""

        # Save the project_id
        self.project_id = project_id

        # Normal Gogole Cloud Client
        self.cloud_client = bigquery.Client(project=project_id)

        # BigQuery client for Tensorflow
        self.tf_client = BigQueryClient()

    def run_sql(self, sql):
        """Run BigQuery SQL and return the rows"""

        return self.cloud_client.query(sql).result()

    def read_tf_dataset(self,
                        bigquery_table_source,
                        schema,
                        row_restriction=None,
                        batch_size=20,
                        shuffle=200,
                        prefetch=1):
        """
        If running locally, make sure to install a certificate from Google, and set up the required environment
        variable.
            curl -Lo roots.pem https://pki.google.com/roots.pem
            export GRPC_DEFAULT_SSL_ROOTS_FILE_PATH=[path_to_certificate]
        :param client:
        :param row_restriction:
        :param batch_size:
        :return:
        """
        dataset_gcp_project_id, dataset_id, table_id, = bigquery_table_source.split('.')
        bqsession = self.tf_client.read_session(
            "projects/" + self.project_id,
            dataset_gcp_project_id,
            table_id,
            dataset_id,
            selected_fields=schema,
            requested_streams=2,
            row_restriction=row_restriction)

        dataset = bqsession.parallel_read_rows()

        return dataset.prefetch(prefetch).shuffle(shuffle).batch(batch_size)

    def get_tf_schema(self, bigquery_table_source, restrictions='TRUE'):
        """Fetch the Tensorflow Schema for a table with potential restrictions on column names"""

        dataset_gcp_project_id, dataset_id, table_id, = bigquery_table_source.split('.')

        sql = f"""
          SELECT
            column_name,
            data_type,
            is_nullable
          FROM
            `{dataset_gcp_project_id}.{dataset_id}.INFORMATION_SCHEMA.COLUMNS`
          WHERE
            table_name='{table_id}' AND
            {restrictions}
        """

        return BigQuery.convert_tf_schema(self.run_sql(sql))
