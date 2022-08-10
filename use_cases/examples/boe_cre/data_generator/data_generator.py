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

import random
from datetime import date
import names
import csv
from tqdm import tqdm
import argparse
from google.cloud import bigquery

STR_PCT_FORMAT = "{:.2}"
STR_FLOAT_FORMAT = "{:.3f}"
STR_DATE_FORMAT = "%Y-%m-%d"

# Arguments
parser = argparse.ArgumentParser(description='Create random records')
parser.add_argument('--project_id',
                    help='The GCP project ID where the data should be loaded')
parser.add_argument('--bq_dataset',
                    help='The BigQuery dataset where the data should be loaded')
parser.add_argument('--num_records_stock', default=10, type=int, nargs='?',
                    help='Number of records to generate for the stock data')
parser.add_argument('--num_records_flow', default=11, type=int, nargs='?',
                    help='Number of records to generate for the flow data')
parser.add_argument('--filename_stock', default='data/loan_level_stock_granular.csv', nargs='?',
                    help='The filename where to save the stock data')
parser.add_argument('--filename_flow', default='data/loan_level_flow_granular.csv', nargs='?',
                    help='The filename where to save the flow data')

args = parser.parse_args()


def _format_pct(pct: float):
    """
    Auxiliary method to format a float into a percentage
    """
    if pct:
        return STR_PCT_FORMAT.format(pct)
    else:
        return ''


def _format_float(number: float):
    """
    Auxiliary method to format a float into a format suitable for output
    """
    if number:
        return STR_FLOAT_FORMAT.format(number)
    else:
        return ''


def _format_date(input_date: date):
    """
    Auxiliary method to format a date into a format suitable for output
    """
    if input_date:
        return input_date.strftime(STR_DATE_FORMAT)
    else:
        return ''


class random_data_generator:
    """
    This class generates sample data in the format required by the CRE reports
    """

    def __init__(self,
                 num_records_stock,
                 num_records_flow,
                 filename_stock,
                 filename_flow,
                 project_id,
                 bq_dataset,
                 ):
        """
        Constructor
        :param num_records_stock: number of records to generate for the stock data
        :param num_records_flow: number of records to generate for the flow data
        :param filename_stock: filename where to save the stock data
        :param filename_flow: filename where to save the flow data
        :param project_id: the GCP project where the data can be loaded
        :param bq_dataset: the BQ dataset where the data can be loaded
        """
        # Initalise the internal structures for the data
        self.loan_stock = []    # stores the generated stock loans data
        self.loan_flow = []     # stores the generated flow loans data

        # Initialise the GCP config
        self.project_id = project_id
        self.bq_dataset = bq_dataset
        self.load_config = {
            "flow": {
                "filename": filename_flow,
                "table_id": "{}.{}.loan_level_flow_granular".format(self.project_id, self.bq_dataset),
                "data_structure": self.loan_flow,
            },
            "stock": {
                "filename": filename_stock,
                "table_id": "{}.{}.loan_level_stock_granular".format(self.project_id, self.bq_dataset),
                "data_structure": self.loan_stock,
            },
        }

        # Initialise the number of records attributes
        self.num_records_stock = num_records_stock
        self.num_records_flow = num_records_flow

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
                'Strong. Project is highly strategic for the sponsor (core business - long-term strategy)',
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
            'frequency_of_change': 0.1,  # how many times the credit rating at origination is the same
        }

    def generate_sample_data(self):
        """
        Method to generate sample records. Fills the internal structures as per the num_stock_loans and num_flow_loans
        passed to the constructor.
        :return: None
        """
        for _ in tqdm(range(self.num_records_stock), "Generating {} stock loans records...".format(self.num_records_stock)):
            self.loan_stock.append(self.generate_record(type='stock'))

        for _ in tqdm(range(self.num_records_flow), "Generating {} flow loans records...".format(self.num_records_flow)):
            self.loan_flow.append(self.generate_record(type='flow'))

    def save_sample_data(self):
        """
        Saves the random data into a file in the filenames specified in the constructor
        :return: None
        """
        for entity in self.load_config.keys():
            filename = self.load_config[entity]['filename']
            data_structure = self.load_config[entity]['data_structure']
            print("Saving the {} loans data in {}".format(entity, filename))
            keys = data_structure[0].keys()
            output_file = open(filename, 'w')
            dict_writer = csv.DictWriter(output_file, keys)
            dict_writer.writeheader()
            dict_writer.writerows(data_structure)
            output_file.close()

    def generate_record(self, type: str = 'stock') -> dict:
        """
        Static method to generate a random record in the CRE structure
        :param type: whether this is a 'stock' or a flow 'record'
        :return: a dictionary of a random record as per the CRE structure
        """

        if type not in ['stock', 'flow']:
            raise ValueError('Only stock or flow are allowed values for type')

        # Create a variable for each field, drawing randomly from a list
        # The lists have multiple copies of the same element to make it more probable
        "booking_entity"
        booking_entity = random.choice(self.config['lst_booking_entity'])

        "legal_entity"
        legal_entity = random.choice(self.config['lst_legal_entity'])

        "division_of_bank"
        division_of_bank = random.choice(self.config['lst_division_of_bank'])

        "within_policy_or_exception"
        within_policy_or_exception = random.choice(self.config['lst_dropdown_within_policy_or_exception'])

        "transaction_type"
        transaction_type = random.choice(self.config['lst_dropdown_transaction_type_table_1'])

        "if_cre_development_type_of_development"
        if_cre_development_type_of_development = ""
        if transaction_type == 'CRE Development':
            if_cre_development_type_of_development = random.choice(self.config['lst_dropdown_type_of_development'])

        "deal_type"
        deal_type = random.choice(self.config['lst_dropdown_deal_type'])

        "limit(£m)"
        limit = random.random() * self.config['max_limit']

        "amount_kept_on_balance_sheet(ie_not_distributed)(£m)"
        amount_kept_on_balance_sheet = random.random() * self.config['max_amount_kept_on_balance_sheet']

        "main_receiver_of_distributed_loan"
        main_receiver_of_distributed_loan = random.choice(self.config['lst_dropdown_main_receiver_of_distributed_loan'])

        "drawdown_date"
        drawdown_date = (self.config['min_drawdown_date'] +
                         (self.config['max_drawdown_date'] - self.config['min_drawdown_date']) *
                         random.random())

        "maturity_date"
        maturity_date = (self.config['min_maturity_date'] +
                         (self.config['max_maturity_date'] - self.config['min_maturity_date']) *
                         random.random())

        "sub-property_sector"
        sub_property_sector = random.choice(self.config['lst_dropdown_sub_property_sector'])

        "region"
        region = random.choice(self.config['lst_dropdown_region'])

        "property_quality"
        property_quality = random.choice(self.config['lst_dropdown_property_quality'])

        "ltv_at_origination(%)"
        ltv_at_origination = None
        if transaction_type == 'CRE Investment':
            ltv_at_origination = random.random()

        "indexed_ltv(%)"
        indexed_ltv = None
        if transaction_type == 'CRE Investment':
            indexed_ltv = random.random()

        "ltev(%)"
        ltev = None
        if transaction_type == 'CRE Development':
            ltev = random.random()

        "ltc(%)"
        ltc = None
        if transaction_type == 'CRE Development':
            ltc = random.random()

        "icr(x)"
        icr = None
        # if transaction_type == 'CRE Investment': ## looks like the ICR is always required? Unclear from the spec
        icr = random.random() * self.config['max_icr']

        "net_rental_income(£m)"
        net_rental_income = None
        if transaction_type == 'CRE Investment':
            net_rental_income = random.random() * amount_kept_on_balance_sheet * \
                                self.config['max_net_rental_income_ratio']

        "margin(%)"
        margin = random.random() * self.config['max_margin']

        "fees(%)"
        fees = random.random() * self.config['max_fees']

        "interest_basis"
        interest_basis = random.choice(self.config['lst_dropdown_interest_basis'])

        "pct_of_limit_hedge"
        pct_of_limit_hedge = random.random()

        "maturity_date_of_hedge"
        maturity_date_of_hedge = (self.config['min_maturity_date_of_hedge'] +
                                  (self.config['max_maturity_date_of_hedge'] - self.config['min_maturity_date_of_hedge']) *
                                  random.random())

        "security"
        security = random.choice(self.config['lst_dropdown_security'])

        "total_limit_on_transaction_including_other_lenders_debt_if_known(£m)"
        total_limit_on_transaction_including_other_lenders_debt_if_known = random.random() * limit

        "weighted_average_remaining_lease_length(months)"
        weighted_average_remaining_lease_length = int(random.random() * self.config['max_lease_length_months'])

        "average_tenant_credit_quality"
        average_tenant_credit_quality = random.choice(self.config['lst_dropdown_average_tenant_credit_quality'])

        "projected_value_of_loan_at_maturity(£m)"
        projected_value_of_loan_at_maturity = limit * self.config['max_projected_value_of_loan_at_maturity_pct']

        "identity_of_lead_lender(for_club_deals_and_syndications)"
        identity_of_lead_lender = "Lender " + str(int(random.random() * self.config['num_lenders']))

        "participating_lenders(for_club_deals_and_syndications)"
        participating_lenders = "Lender " + str(int(random.random() * self.config['num_lenders']))

        "ongoing_covenants"
        ongoing_covenants = random.choice(self.config['lst_dropdown_ongoing_covenants'])

        "name_of_borrower"
        name_of_borrower = names.get_full_name()

        "name_of_sponsor(based_on_slotting_assessment)"
        name_of_sponsor = names.get_full_name()

        "sponsor_quality"
        sponsor_quality = random.choice(self.config['lst_dropdown_sponsor_quality'])

        "policy_exceptions"
        policy_exceptions = ""
        if within_policy_or_exception == 'Exception':
            policy_exceptions = random.choice(self.config['lst_dropdown_policy_exception'])

        "brief_reason_for_policy_exception(s)"
        brief_reason_for_policy_exception = ""
        if within_policy_or_exception == 'Exception':
            brief_reason_for_policy_exception = "A description of the policy exception"

        "basel_approach"
        basel_approach = random.choice(self.config['lst_dropdown_basel_approach'])

        "credit_rating_scale_name"
        credit_rating_scale_name = random.choice(self.config['lst_dropdown_credit_rating_scale_name'])

        "internal_credit_rating"
        internal_credit_rating = random.choice(self.config['lst_dropdown_internal_credit_rating'])

        "internal_credit_rating_at_origination"
        internal_credit_rating_at_origination = internal_credit_rating
        if random.random() < self.config['frequency_of_change']:
            internal_credit_rating_at_origination = random.choice(self.config['lst_dropdown_internal_credit_rating'])

        "rwa(£m)"
        rwa = random.random() * amount_kept_on_balance_sheet

        "pd_regulatory(%)"
        pd_regulatory = random.random()

        "lgd_regulatory(%)"
        lgd_regulatory = random.random()

        "expected_loss_regulatory(£m)"
        expected_loss_regulatory = random.random() * amount_kept_on_balance_sheet

        "provisions(£m)"
        provisions = random.random() * amount_kept_on_balance_sheet

        "any_other_brief_comments"
        any_other_brief_comments = ""

        # Populate a dictionary
        record = {
            "booking_entity":
                booking_entity,
            "legal_entity":
                legal_entity,
            "division_of_bank":
                division_of_bank,
            "within_policy_or_exception":
                within_policy_or_exception,
            "transaction_type":
                transaction_type,
            "if_cre_development_type_of_development":
                if_cre_development_type_of_development,
            "deal_type":
                deal_type,
            "limit_value":  # have to append value as limit is a reserved word in BQ
                _format_float(limit),
            "amount_kept_on_balance_sheet":
                _format_float(amount_kept_on_balance_sheet),
            "main_receiver_of_distributed_loan":
                main_receiver_of_distributed_loan,
            "drawdown_date":
                _format_date(drawdown_date),
            "maturity_date":
                _format_date(maturity_date),
            "sub_property_sector":
                sub_property_sector,
            "region":
                region,
            "property_quality":
                property_quality,
            "ltev":
                _format_pct(ltev),
            "ltc":
                _format_pct(ltc),
            "icr":
                _format_pct(icr),
            "net_rental_income":
                _format_float(net_rental_income),
            "margin":
                _format_pct(margin),
            "fees":
                _format_pct(fees),
            "interest_basis":
                interest_basis,
            "pct_of_limit_hedge":
                _format_pct(pct_of_limit_hedge),
            "maturity_date_of_hedge":
                _format_date(maturity_date_of_hedge),
            "security":
                security,
            "total_limit_on_transaction_including_other_lenders_debt_if_known":
                _format_float(total_limit_on_transaction_including_other_lenders_debt_if_known),
            "weighted_average_remaining_lease_length":
                weighted_average_remaining_lease_length,
            "average_tenant_credit_quality":
                average_tenant_credit_quality,
            "projected_value_of_loan_at_maturity":
                _format_float(projected_value_of_loan_at_maturity),
            "identity_of_lead_lender":
                identity_of_lead_lender,
            "participating_lenders":
                participating_lenders,
            "ongoing_covenants":
                ongoing_covenants,
            "name_of_borrower":
                name_of_borrower,
            "name_of_sponsor":
                name_of_sponsor,
            "sponsor_quality":
                sponsor_quality,
            "policy_exceptions":
                policy_exceptions,
            "brief_reason_for_policy_exception":
                brief_reason_for_policy_exception,
            "any_other_brief_comments":
                any_other_brief_comments
        }
        if type == 'stock': # Stock has a few additional attributes
            record["ltv_at_origination"] = _format_pct(ltv_at_origination)
            record["indexed_ltv"] = _format_pct(indexed_ltv)
            record["basel_approach"] = basel_approach
            record["credit_rating_scale_name"] = credit_rating_scale_name
            record["internal_credit_rating"] = internal_credit_rating
            record["internal_credit_rating_at_origination"] = internal_credit_rating_at_origination
            record["rwa"] = _format_float( rwa)
            record["pd_regulatory"] = _format_pct( pd_regulatory)
            record["lgd_regulatory"] = _format_pct( lgd_regulatory)
            record["expected_loss_regulatory"] = _format_pct( expected_loss_regulatory)
            record["provisions"] = _format_float( provisions)

        if type == 'flow':
            record["ltv_pct"] = _format_pct(ltv_at_origination)

        # Return
        return record


    def load_data_to_bq(self):
        """
        Loads the generated data into BigQuery.
        :param project_id:
        :param bq_dataset:
        """
        # Construct a BigQuery client object.
        client = bigquery.Client(project=self.project_id)
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV, skip_leading_rows=1, autodetect=True,
        )


        for table in self.load_config.keys():
            filename = self.load_config[table]["filename"]
            table_id = self.load_config[table]["table_id"]
            "Loading data in table {}".format(table_id)
            with open(filename, "rb") as source_file:
                job = client.load_table_from_file(source_file, table_id, job_config=job_config)

            job.result()  # Waits for the job to complete.

            table = client.get_table(table_id)  # Make an API request.
            print(
                "\tThere are {} rows and {} columns in {}".format(
                    table.num_rows, len(table.schema), table_id
                )
            )


if __name__ == "__main__":
    generator = random_data_generator(
        project_id=args.project_id,
        bq_dataset=args.bq_dataset,
        num_records_stock=args.num_records_stock,
        num_records_flow=args.num_records_flow,
        filename_stock=args.filename_stock,
        filename_flow=args.filename_flow,
    )
    generator.generate_sample_data()
    generator.save_sample_data()
    generator.load_data_to_bq()
    exit()
