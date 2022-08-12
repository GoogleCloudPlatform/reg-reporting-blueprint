## Copyright 2022 Google LLC

## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at

##     https://www.apache.org/licenses/LICENSE-2.0

## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.


## Data Generator
##
## This script generates sample data in the format required by the CRE reports

from datetime import date
from io import StringIO
import random
import csv
import argparse

import names
from tqdm import tqdm
from google.cloud import bigquery


STR_PCT_FORMAT = "{:.2}"
def _format_pct(pct: float):
    """
    Auxiliary method to format a float into a percentage
    """
    if pct:
        return STR_PCT_FORMAT.format(pct)

    return ''


STR_FLOAT_FORMAT = "{:.3f}"
def _format_float(number: float):
    """
    Auxiliary method to format a float into a format suitable for output
    """
    if number:
        return STR_FLOAT_FORMAT.format(number)

    return ''


STR_DATE_FORMAT = "%Y-%m-%d"
def _format_date(input_date: date):
    """
    Auxiliary method to format a date into a format suitable for output
    """
    if input_date:
        return input_date.strftime(STR_DATE_FORMAT)

    return ''


class RandomDataGenerator:
    """
    This class generates sample data in the format required by the CRE reports
    """

    def __init__(self):
        """
        Constructor
        This initializes internal configuration for the data generator.
        """

        # Configuration of the file generator
        self.config = {
            'lst_booking_entity': [
                "Entity A",
                "Entity B",
                "Entity C"
            ],
            'lst_legal_entity': [
                "Entity A",
                "Entity B",
                "Entity C"
            ],
            'lst_division_of_bank': [
                "Commercial Bank",
                "Commercial Bank",
                "Investment Bank"
            ],
            'lst_dropdown_within_policy_or_exception':
                ['Policy'] * 9 + ['Exception'] * 1,
            'lst_dropdown_transaction_type_table_1': \
                ['CRE Investment'] + ['CRE Development'] * 2,
            'lst_dropdown_type_of_development': [
                'Speculative commercial',
                'Fully pre-let commercial',
                'Part speculative commercial; part fully pre-let commercial',
                'Residential development for sale',
                'Other (please state in "any other brief comments" variable)'
            ],
            'lst_dropdown_deal_type':
                ['New client',
                 'Existing client, new transaction',
                 'Existing client, refinance of existing transaction',
                 ''],  # added an empty choice
            'max_limit': 10000,
            'max_amount_kept_on_balance_sheet': 1000,
            'lst_dropdown_main_receiver_of_distributed_loan': [
                'UK bank',
                'Non-UK bank',
                'UK insurer',
                'Non-UK insurer',
                'UK pension fund',
                'Non-UK pension fund',
                'Credit fund'],
            'min_drawdown_date': date(1980, 1, 1),
            'max_drawdown_date': date(2020, 12, 31),
            'min_maturity_date': date(1985, 1, 1),
            'max_maturity_date': date(2040, 12, 31),
            'lst_dropdown_sub_property_sector': [
                'Office',
                'High Street Retail',
                'Shopping Centres',
                'Warehouse/Distribution',
                'Residential',
                'Hotels',
                'Nursing Care',
                'Leisure',
                'Student Accommodation',
                'Serviced offices/co-working',
                'Healthcare',
                'Mixed'],
            'lst_dropdown_region': [
                'North East ',
                'North West',
                'Yorkshire and the Humber',
                'East Midlands',
                'West Midlands',
                'East of England',
                'London',
                'South East',
                'South West',
                'Northern Ireland',
                'Scotland',
                'Wales ',
                'Nationwide'],
            'lst_dropdown_property_quality': [
                'Prime',
                'Good Secondary',
                'Secondary',
                'Tertiary'],
            'max_icr': 5,
            'max_net_rental_income_ratio': 0.2,
            'max_margin': 0.2,
            'max_fees': 0.05,
            'lst_dropdown_interest_basis': [
                'Entirely floating rate with no interest rate protection',
                'Entirely fixed rate',
                'Partially fixed rate or with interest rate protection'],
            'min_maturity_date_of_hedge': date(1985, 1, 1),
            'max_maturity_date_of_hedge': date(2040, 12, 31),
            'lst_dropdown_security': [
                'First charge',
                'Second charge',
                'Unsecured'],
            'max_lease_length_months': 60,
            'lst_dropdown_average_tenant_credit_quality': [
                'Sovereign',
                'Investment grade',
                'Sub-investment grade',
                'Individuals/Sole traders'],
            'max_projected_value_of_loan_at_maturity_pct': 0.1,
            'num_lenders': 1000,
            'lst_dropdown_ongoing_covenants': [
                'Running LTV and ICR/DSR covenants',
                'Running LTV covenant',
                'Running ICR/DSR covenant',
                'Running LTC/LTeV covenant',
                'No running covenants',
                'Other (please state in "any other brief comments" variable)'],
            'lst_dropdown_sponsor_quality': [
                ('Strong. Project is highly strategic for the sponsor ' +
                 '(core business - long-term strategy)'),
                'Good. Project is strategic for the sponsor (core business - long-term strategy)',
                'Acceptable. Project is considered important for the sponsor (core business)',
                'Limited. Project is not key to sponsors long-term strategy or core business'],
            'lst_dropdown_policy_exception': [
                'Higher LTV (inv and land bank only)',
                'Equity in pari-passu or last (dev only)',
                'Higher LTC and/or LTeV (dev only)',
                'Higher Residual Value percentage (inv only)',
                'Lower ICR (inv only)',
                'Lower risk reward return (all)',
                'Weaker repayment structure (all)',
                'Weaker planning requirement (land bank only)',
                'Weaker interest payment basis (land bank only)',
                'Weaker lending basis, i.e. LTV instead of LTC (land bank only)',
                'Weaker pre-let requirement (dev only)',
                'No hedging when hedging is mandatory (all)'],
            'lst_dropdown_basel_approach': [
                'F-IRB',
                'A-IRB',
                'IRB Slotting',
                'Standardised'],
            'lst_dropdown_credit_rating_scale_name': [
                'CQS',
                'Firm slotting scale',
                'Standardised no internal rating'],
            'lst_dropdown_internal_credit_rating': [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                'Default',
                'Good',
                'Satisfactory',
                'Strong',
                'Unrated',
                'Weak'],
            # how many times the credit rating at origination is the same
            'frequency_of_change': 0.1,
        }

    def generate_stock_record(self) -> dict:
        """
        Generate a random stock record
        """
        return self.generate_record(rec_type='stock')

    def generate_flow_record(self) -> dict:
        """
        Generate a random flow record
        """
        return self.generate_record(rec_type='flow')

    def generate_record(self, rec_type: str = 'stock') -> dict:
        """
        Generate a random record in the CRE structure
        :param rec_type: whether this is a 'stock' or a flow 'record'
        :return: a dictionary of a random record as per the CRE structure
        """

        if rec_type not in ['stock', 'flow']:
            raise ValueError('Only stock or flow are allowed values for type')

        # Initialize common random variables for the record
        limit = random.random() * self.config['max_limit']

        amount_kept_on_balance_sheet = (
            random.random() * self.config['max_amount_kept_on_balance_sheet'])

        transaction_type = random.choice(
            self.config['lst_dropdown_transaction_type_table_1'])

        within_policy_or_exception = random.choice(
            self.config['lst_dropdown_within_policy_or_exception'])

        ltv_at_origination = None
        if transaction_type == 'CRE Investment':
            ltv_at_origination = random.random()

        # Initialize random fields common across both records
        rec = dict(
            booking_entity =   random.choice(self.config['lst_booking_entity']),

            legal_entity =     random.choice(self.config['lst_legal_entity']),

            division_of_bank = random.choice(self.config['lst_division_of_bank']),

            within_policy_or_exception = within_policy_or_exception,

            transaction_type = transaction_type,

            deal_type = random.choice(self.config['lst_dropdown_deal_type']),

            main_receiver_of_distributed_loan = random.choice(
                self.config['lst_dropdown_main_receiver_of_distributed_loan']),

            drawdown_date = _format_date(
                self.config['min_drawdown_date'] +
                (self.config['max_drawdown_date'] - self.config['min_drawdown_date']) *
                random.random()),

            maturity_date = _format_date(
                self.config['min_maturity_date'] +
                (self.config['max_maturity_date'] - self.config['min_maturity_date']) *
                random.random()),

            sub_property_sector = random.choice(
                self.config['lst_dropdown_sub_property_sector']),

            region = random.choice(self.config['lst_dropdown_region']),

            property_quality = random.choice(
                self.config['lst_dropdown_property_quality']),

            limit_value = _format_float(limit),

            amount_kept_on_balance_sheet = _format_float(amount_kept_on_balance_sheet),

            if_cre_Development_type_of_development = (
                random.choice(self.config['lst_dropdown_type_of_development'])
                if transaction_type == 'CRE Development'
                else ""),

            ltev = (
                _format_pct(random.random())
                if transaction_type == 'CRE Development'
                else ""),

            ltc = (
                _format_pct(random.random())
                if transaction_type == 'CRE Development'
                else ""),

            # It looks like the ICR is always required. Unclear from the spec.
            icr = (
                _format_pct(random.random() * self.config['max_icr'])),

            net_rental_income = (
                _format_float(
                    random.random() * amount_kept_on_balance_sheet *
                    self.config['max_net_rental_income_ratio'])
                if transaction_type == 'CRE Investment'
                else ""),

            margin =_format_pct(
                random.random() * self.config['max_margin']),

            fees = _format_pct(
                random.random() * self.config['max_fees']),

            interest_basis = random.choice(
                self.config['lst_dropdown_interest_basis']),

            pct_of_limit_hedge = _format_pct(random.random()),

            maturity_date_of_hedge = _format_date(
                self.config['min_maturity_date_of_hedge'] +
                ((self.config['max_maturity_date_of_hedge'] -
                  self.config['min_maturity_date_of_hedge']) *
                  random.random())
            ),

            security = random.choice(self.config['lst_dropdown_security']),

            total_limit_on_transaction_including_other_lenders_debt_if_known = (
                _format_float(random.random() * limit)),

            weighted_average_remaining_lease_length = int(
                random.random() * self.config['max_lease_length_months']),

            average_tenant_credit_quality = random.choice(
                self.config['lst_dropdown_average_tenant_credit_quality']),

            projected_value_of_loan_at_maturity = _format_float(
                limit * self.config['max_projected_value_of_loan_at_maturity_pct']),

            identity_of_lead_lender = "Lender " + str(
                int(random.random() * self.config['num_lenders'])),

            participating_lenders = "Lender " + str(
                int(random.random() * self.config['num_lenders'])),

            ongoing_covenants = random.choice(
                self.config['lst_dropdown_ongoing_covenants']),

            name_of_borrower = names.get_full_name(),
            name_of_sponsor = names.get_full_name(),

            sponsor_quality = random.choice(
                self.config['lst_dropdown_sponsor_quality']),

            policy_exceptions = (
                random.choice(self.config['lst_dropdown_policy_exception'])
                if within_policy_or_exception == 'Exception'
                else ""),

            brief_reason_for_policy_exception = (
                "A description of the policy exception"
                if within_policy_or_exception == 'Exception'
                else ""),

            any_other_brief_comments = "",
        )

        # Initialize stock-specific fields
        if rec_type == 'stock':
            internal_credit_rating = random.choice(
                self.config['lst_dropdown_internal_credit_rating'])

            rec.update(
                ltv_at_origination = _format_pct(ltv_at_origination),

                indexed_ltv = (
                    _format_pct(random.random())
                    if transaction_type == 'CRE Investment'
                    else None),

                basel_approach = random.choice(
                    self.config['lst_dropdown_basel_approach']),

                credit_rating_scale_name = random.choice(
                    self.config['lst_dropdown_credit_rating_scale_name']),

                internal_credit_rating = internal_credit_rating,

                internal_credit_rating_at_origination = (
                    random.choice(self.config['lst_dropdown_internal_credit_rating'])
                    if random.random() < self.config['frequency_of_change']
                    else internal_credit_rating),

                rwa = (_format_float(random.random() * amount_kept_on_balance_sheet)),

                pd_regulatory = _format_pct(random.random()),

                lgd_regulatory = _format_pct(random.random()),

                expected_loss_regulatory = _format_pct(
                    random.random() * amount_kept_on_balance_sheet),

                provisions = _format_float(random.random() * amount_kept_on_balance_sheet),
            )

        # Initialize flow-specific fields
        if rec_type == 'flow':
            rec.update(
                ltv_pct = _format_pct(ltv_at_origination)
            )

        return rec


def upload_rows_to_bigquery(client, table_id, num_rows, row_generator):
    """
    Load data into BigQuery
    :param client:         BigQuery Client
    :param table_id:       Full table_id target for BigQuery
    :param num_rows:       Number of rows to generate
    :param row_generator:  Function to generate rows
    """

    # Construct a load job
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
    )

    # In-memory buffer for data to be uploaded
    memory_buffer = StringIO()

    # Initialize CSV writer
    keys = row_generator().keys()
    dict_writer = csv.DictWriter(memory_buffer, keys)
    dict_writer.writeheader()

    # Generate all of the rows
    for _ in tqdm(range(num_rows), f"{table_id}: Generating {num_rows} rows"):
        dict_writer.writerow(row_generator())

    # Load into BigQuery
    print(f"{table_id}: Loading data into BigQuery")
    job = client.load_table_from_file(memory_buffer, table_id,
                                      job_config=job_config, rewind=True)

    job.result()  # Waits for the job to complete.

    # Gather statistics of target table
    table = client.get_table(table_id)
    print(f"{table_id}: There are {table.num_rows} rows and " +
          f"{len(table.schema)} columns")


if __name__ == "__main__":

    # Arguments
    parser = argparse.ArgumentParser(description='Create random CRE records')
    parser.add_argument('--project_id',
                        required=True,
                        help='The GCP project ID where the data should be loaded')
    parser.add_argument('--bq_dataset',
                        required=True,
                        help='The BigQuery dataset where the data should be loaded')
    parser.add_argument('--num_records_stock',
                        default=10, type=int, nargs='?',
                        help='Number of records to generate for the stock data')
    parser.add_argument('--num_records_flow',
                        default=11, type=int, nargs='?',
                        help='Number of records to generate for the flow data')

    args = parser.parse_args()

    bigquery_client = bigquery.Client(project=args.project_id)

    generator = RandomDataGenerator()

    upload_rows_to_bigquery(
        bigquery_client,
        f"{args.project_id}.{args.bq_dataset}.loan_level_stock_granular",
        args.num_records_stock,
        generator.generate_stock_record)

    upload_rows_to_bigquery(
        bigquery_client,
        f"{args.project_id}.{args.bq_dataset}.loan_level_flow_granular",
        args.num_records_flow,
        generator.generate_flow_record)
