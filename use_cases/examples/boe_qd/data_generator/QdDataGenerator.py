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

# QD Data Generator
# Generate pseudo-random credit default swap (CDS) trade data & write to files.

# This utility provide a class with  methods to generate sample CDS trade details,
# and persist them to n number of FpML files, and, to 1 csv file (with n rows).

import copy
import csv
import datetime
import random
import uuid
import xml.etree.ElementTree as et

from faker import Faker
from faker.providers import address
import numpy
import tqdm
import argparse
from google.cloud import bigquery
from io import StringIO

class QdDataGenerator:
  """This class generates sample FpML (and corresponding JSON) of CDS deals.
  """

  def __init__(self):
    # Paths to extract
    self.els_maps = {
        "trade_date": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}tradeDate",
            "xpath_index": 0
            },
        "sched_term_date": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}unadjustedDate",
            "xpath_index": 0
            },
        "buyer_party_reference": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}buyerPartyReference",
            "xpath_index": 0
            },
        "seller_party_reference": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}sellerPartyReference",
            "xpath_index": 0
            },
        "party_1_trade_id": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}tradeId",
            "xpath_index": 0
            },
        "party_2_trade_id": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}tradeId",
            "xpath_index": 1
            },
        "index_name": {
            "xpath":
                ".//{http://www.fpml.org/FpML-5/confirmation}indexName",
            "xpath_index": 0
            },
        "index_series": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}indexSeries",
            "xpath_index": 0
        },
        "index_annex_version": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}indexAnnexVersion",
            "xpath_index": 0
            },
        "payer_party_reference": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}payerPartyReference",
            "xpath_index": 0
            },
        "receiver_party_reference": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}receiverPartyReference",
            "xpath_index": 0
            },
        "fee_currency": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}currency",
            "xpath_index": 0
            },
        "fee_amount": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}amount",
            "xpath_index": 0
            },
        "notional_currency": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}currency",
            "xpath_index": 0
            },
        "notional_amount": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}amount",
            "xpath_index": 1
            },
        "master_confirmation_type": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}masterConfirmationType",
            "xpath_index": 0
            },
        "master_confirmation_date": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}masterConfirmationDate",
            "xpath_index": 0
            },
        "party_1_id": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}partyId",
            "xpath_index": 0
            },
        "party_1_name": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}partyName",
            "xpath_index": 0
            },
        "party_2_id": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}partyId",
            "xpath_index": 1
            },
        "party_2_name": {
            "xpath":
            ".//{http://www.fpml.org/FpML-5/confirmation}partyName",
            "xpath_index": 1
            }
        }

  def make_random_leis(self, num_ia_recs):
    """Generates X num of LEI records w/ fake value for each appropriate element.

    Args:
      num_ia_recs: Length of list of investment advisor records
    Returns:
      list
    """
    # Return list length will be 14 market makers + num_ia_recs
    num_recs = num_ia_recs + 14

    # Define all headers for an LEI record
    # per https://www.gleif.org/en/lei-data/gleif-golden-copy
    lei_headers = [
        "LEI",
        "Entity_LegalName",
        "Entity_LegalName_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_1",
        "Entity_OtherEntityNames_OtherEntityName_1_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_1_type",
        "Entity_OtherEntityNames_OtherEntityName_2",
        "Entity_OtherEntityNames_OtherEntityName_2_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_2_type",
        "Entity_OtherEntityNames_OtherEntityName_3",
        "Entity_OtherEntityNames_OtherEntityName_3_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_3_type",
        "Entity_OtherEntityNames_OtherEntityName_4",
        "Entity_OtherEntityNames_OtherEntityName_4_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_4_type",
        "Entity_OtherEntityNames_OtherEntityName_5",
        "Entity_OtherEntityNames_OtherEntityName_5_xmllang",
        "Entity_OtherEntityNames_OtherEntityName_5_type",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_1",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_1_xmllang",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_1_type",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_2",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_2_xmllang",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_2_type",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_3",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_3_xmllang",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_3_type",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_4",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_4_xmllang",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_4_type",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_5",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_5_xmllang",
        "Entity_TransliteratedOtherEntityNames_" +
        "TransliteratedOtherEntityName_5_type",
        "Entity_LegalAddress_xmllang",
        "Entity_LegalAddress_FirstAddressLine",
        "Entity_LegalAddress_AddressNumber",
        "Entity_LegalAddress_AddressNumberWithinBuilding",
        "Entity_LegalAddress_MailRouting",
        "Entity_LegalAddress_AdditionalAddressLine_1",
        "Entity_LegalAddress_AdditionalAddressLine_2",
        "Entity_LegalAddress_AdditionalAddressLine_3",
        "Entity_LegalAddress_City",
        "Entity_LegalAddress_Region",
        "Entity_LegalAddress_Country",
        "Entity_LegalAddress_PostalCode",
        "Entity_HeadquartersAddress_xmllang",
        "Entity_HeadquartersAddress_FirstAddressLine",
        "Entity_HeadquartersAddress_AddressNumber",
        "Entity_HeadquartersAddress_AddressNumberWithinBuilding",
        "Entity_HeadquartersAddress_MailRouting",
        "Entity_HeadquartersAddress_AdditionalAddressLine_1",
        "Entity_HeadquartersAddress_AdditionalAddressLine_2",
        "Entity_HeadquartersAddress_AdditionalAddressLine_3",
        "Entity_HeadquartersAddress_City",
        "Entity_HeadquartersAddress_Region",
        "Entity_HeadquartersAddress_Country",
        "Entity_HeadquartersAddress_PostalCode",
        "Entity_OtherAddresses_OtherAddress_1_xmllang",
        "Entity_OtherAddresses_OtherAddress_1_type",
        "Entity_OtherAddresses_OtherAddress_1_FirstAddressLine",
        "Entity_OtherAddresses_OtherAddress_1_AddressNumber",
        "Entity_OtherAddresses_OtherAddress_1_AddressNumberWithinBuilding",
        "Entity_OtherAddresses_OtherAddress_1_MailRouting",
        "Entity_OtherAddresses_OtherAddress_1_AdditionalAddressLine_1",
        "Entity_OtherAddresses_OtherAddress_1_AdditionalAddressLine_2",
        "Entity_OtherAddresses_OtherAddress_1_AdditionalAddressLine_3",
        "Entity_OtherAddresses_OtherAddress_1_City",
        "Entity_OtherAddresses_OtherAddress_1_Region",
        "Entity_OtherAddresses_OtherAddress_1_Country",
        "Entity_OtherAddresses_OtherAddress_1_PostalCode",
        "Entity_OtherAddresses_OtherAddress_2_xmllang",
        "Entity_OtherAddresses_OtherAddress_2_type",
        "Entity_OtherAddresses_OtherAddress_2_FirstAddressLine",
        "Entity_OtherAddresses_OtherAddress_2_AddressNumber",
        "Entity_OtherAddresses_OtherAddress_2_AddressNumberWithinBuilding",
        "Entity_OtherAddresses_OtherAddress_2_MailRouting",
        "Entity_OtherAddresses_OtherAddress_2_AdditionalAddressLine_1",
        "Entity_OtherAddresses_OtherAddress_2_AdditionalAddressLine_2",
        "Entity_OtherAddresses_OtherAddress_2_AdditionalAddressLine_3",
        "Entity_OtherAddresses_OtherAddress_2_City",
        "Entity_OtherAddresses_OtherAddress_2_Region",
        "Entity_OtherAddresses_OtherAddress_2_Country",
        "Entity_OtherAddresses_OtherAddress_2_PostalCode",
        "Entity_OtherAddresses_OtherAddress_3_xmllang",
        "Entity_OtherAddresses_OtherAddress_3_type",
        "Entity_OtherAddresses_OtherAddress_3_FirstAddressLine",
        "Entity_OtherAddresses_OtherAddress_3_AddressNumber",
        "Entity_OtherAddresses_OtherAddress_3_AddressNumberWithinBuilding",
        "Entity_OtherAddresses_OtherAddress_3_MailRouting",
        "Entity_OtherAddresses_OtherAddress_3_AdditionalAddressLine_1",
        "Entity_OtherAddresses_OtherAddress_3_AdditionalAddressLine_2",
        "Entity_OtherAddresses_OtherAddress_3_AdditionalAddressLine_3",
        "Entity_OtherAddresses_OtherAddress_3_City",
        "Entity_OtherAddresses_OtherAddress_3_Region",
        "Entity_OtherAddresses_OtherAddress_3_Country",
        "Entity_OtherAddresses_OtherAddress_3_PostalCode",
        "Entity_OtherAddresses_OtherAddress_4_xmllang",
        "Entity_OtherAddresses_OtherAddress_4_type",
        "Entity_OtherAddresses_OtherAddress_4_FirstAddressLine",
        "Entity_OtherAddresses_OtherAddress_4_AddressNumber",
        "Entity_OtherAddresses_OtherAddress_4_AddressNumberWithinBuilding",
        "Entity_OtherAddresses_OtherAddress_4_MailRouting",
        "Entity_OtherAddresses_OtherAddress_4_AdditionalAddressLine_1",
        "Entity_OtherAddresses_OtherAddress_4_AdditionalAddressLine_2",
        "Entity_OtherAddresses_OtherAddress_4_AdditionalAddressLine_3",
        "Entity_OtherAddresses_OtherAddress_4_City",
        "Entity_OtherAddresses_OtherAddress_4_Region",
        "Entity_OtherAddresses_OtherAddress_4_Country",
        "Entity_OtherAddresses_OtherAddress_4_PostalCode",
        "Entity_OtherAddresses_OtherAddress_5_xmllang",
        "Entity_OtherAddresses_OtherAddress_5_type",
        "Entity_OtherAddresses_OtherAddress_5_FirstAddressLine",
        "Entity_OtherAddresses_OtherAddress_5_AddressNumber",
        "Entity_OtherAddresses_OtherAddress_5_AddressNumberWithinBuilding",
        "Entity_OtherAddresses_OtherAddress_5_MailRouting",
        "Entity_OtherAddresses_OtherAddress_5_AdditionalAddressLine_1",
        "Entity_OtherAddresses_OtherAddress_5_AdditionalAddressLine_2",
        "Entity_OtherAddresses_OtherAddress_5_AdditionalAddressLine_3",
        "Entity_OtherAddresses_OtherAddress_5_City",
        "Entity_OtherAddresses_OtherAddress_5_Region",
        "Entity_OtherAddresses_OtherAddress_5_Country",
        "Entity_OtherAddresses_OtherAddress_5_PostalCode",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_xmllang",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_type",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_FirstAddressLine",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_AddressNumber",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_AddressNumberWithinBuilding",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_MailRouting",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_AdditionalAddressLine_1",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_AdditionalAddressLine_2",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_AdditionalAddressLine_3",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_City",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_Region",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_Country",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_1_PostalCode",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_xmllang",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_type",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_FirstAddressLine",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_AddressNumber",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_AddressNumberWithinBuilding",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_MailRouting",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_AdditionalAddressLine_1",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_AdditionalAddressLine_2",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_AdditionalAddressLine_3",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_City",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_Region",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_Country",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_2_PostalCode",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_xmllang",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_type",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_FirstAddressLine",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_AddressNumber",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_AddressNumberWithinBuilding",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_MailRouting",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_AdditionalAddressLine_1",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_AdditionalAddressLine_2",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_AdditionalAddressLine_3",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_City",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_Region",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_Country",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_3_PostalCode",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_xmllang",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_type",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_FirstAddressLine",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_AddressNumber",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_AddressNumberWithinBuilding",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_MailRouting",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_AdditionalAddressLine_1",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_AdditionalAddressLine_2",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_AdditionalAddressLine_3",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_City",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_Region",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_Country",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_4_PostalCode",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_xmllang",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_type",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_FirstAddressLine",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_AddressNumber",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_AddressNumberWithinBuilding",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_MailRouting",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_AdditionalAddressLine_1",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_AdditionalAddressLine_2",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_AdditionalAddressLine_3",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_City",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_Region",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_Country",
        "Entity_TransliteratedOtherAddresses_" +
        "TransliteratedOtherAddress_5_PostalCode",
        "Entity_RegistrationAuthority_RegistrationAuthorityID",
        "Entity_RegistrationAuthority_OtherRegistrationAuthorityID",
        "Entity_RegistrationAuthority_RegistrationAuthorityEntityID",
        "Entity_LegalJurisdiction",
        "Entity_EntityCategory",
        "Entity_LegalForm_EntityLegalFormCode",
        "Entity_LegalForm_OtherLegalForm",
        "Entity_AssociatedEntity_type",
        "Entity_AssociatedEntity_AssociatedLEI",
        "Entity_AssociatedEntity_AssociatedEntityName",
        "Entity_AssociatedEntity_AssociatedEntityName_xmllang",
        "Entity_EntityStatus",
        "Entity_EntityExpirationDate",
        "Entity_EntityExpirationReason",
        "Entity_SuccessorEntity_SuccessorLEI",
        "Entity_SuccessorEntity_SuccessorEntityName",
        "Entity_SuccessorEntity_SuccessorEntityName_xmllang",
        "Registration_InitialRegistrationDate",
        "Registration_LastUpdateDate",
        "Registration_RegistrationStatus",
        "Registration_NextRenewalDate",
        "Registration_ManagingLOU",
        "Registration_ValidationSources",
        "Registration_ValidationAuthority_ValidationAuthorityID",
        "Registration_ValidationAuthority_OtherValidationAuthorityID",
        "Registration_ValidationAuthority_ValidationAuthorityEntityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_1_ValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_1_OtherValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_1_ValidationAuthorityEntityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_2_ValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_2_OtherValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_2_ValidationAuthorityEntityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_3_ValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_3_OtherValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_3_ValidationAuthorityEntityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_4_ValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_4_OtherValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_4_ValidationAuthorityEntityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_5_ValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_5_OtherValidationAuthorityID",
        "Registration_OtherValidationAuthorities_" +
        "OtherValidationAuthority_5_ValidationAuthorityEntityID"]
    lei_rec = dict.fromkeys(lei_headers)

    # Populate "template" record with the vals
    # that are common to all records
    fake = Faker()

    lei_rec["Entity_LegalName_xmllang"] = "en"
    lei_rec["Entity_RegistrationAuthority_"
            "RegistrationAuthorityID"] = fake.bothify(text="RA######")
    lei_rec["Entity_RegistrationAuthority_"
            "RegistrationAuthorityEntityID"] = fake.bothify(
                text="##########")
    lei_rec["Entity_Category"] = "FUND"
    lei_rec["Entity_LegalForm_"
            "OtherLegalForm"] = "LIMITED"
    lei_rec["Entity_"
            "EntityStatus"] = "ACTIVE"
    lei_rec["Registration_"
            "RegistrationStatus"] = "ISSUED"
    lei_rec["Registration_ManagingLOU"] = self.make_random_lei()
    lei_rec["Registration_ValidationSources"] = "FULLY_CORROBORATED"
    lei_rec["Registration_ValidationAuthority_"
            "ValidationAuthorityID"] = fake.bothify(text="RA######")
    # Below should have underscore at pos 10
    lei_rec["Registration_ValidationAuthority_"
            "ValidationAuthorityEntityID"] = fake.bothify(
                text="0################")

    # Create the given num of records
    # from the one "template" record
    lei_recs = [lei_rec for i in range(num_recs)]

    # List of locale codes w/ corresponding dist probability
    gb_fake = Faker("en-GB")
    us_fake = Faker("en-US")
    de_fake = Faker("de-DE")
    es_fake = Faker("es-MX")
    ch_fake = Faker("de-CH")
    ca_fake = Faker("en-CA")
    fr_fake = Faker("fr-FR")
    nl_fake = Faker("nl-NL")

    ctry_d = [{"faker": gb_fake, "func": gb_fake.county},
              {"faker": us_fake, "func": us_fake.state},
              {"faker": de_fake, "func": de_fake.state},
              {"faker": es_fake, "func": es_fake.administrative_unit},
              {"faker": ch_fake, "func": lambda: ch_fake.canton()[1]},
              {"faker": ca_fake, "func": ca_fake.province},
              {"faker": fr_fake, "func": lambda: fr_fake.department()[1]},
              {"faker": nl_fake, "func": nl_fake.administrative_unit}]
    ctry_prob = [.35, .35, .05,
                 .05, .05, .05, .05, .05]
    # Create vals distinct to particular records
    # and store in a separate dict
    dstn_data = [{} for _ in range(num_recs)]

    i = 0
    while i < len(dstn_data):
      dstn_rec_a = dstn_data[i]
      dstn_rec_b = dstn_data[i+1]

      lcle = numpy.random.choice(ctry_d, p=ctry_prob)
      fake = lcle["faker"]
      fake.add_provider(address)

      firm_type = "Asset Advisors"
      if i < 30:
        firm_type = "Bank"

      # Generate distinct data points where en-US is appropriate
      dstn_rec_a["LEI"] = self.make_random_lei()
      dstn_rec_a["Entity_LegalName"] = f"{fake.company()} {firm_type} Fund A"
      lei_rec["Entity_LegalAddress_xmllang"] = fake.language_name()
      dstn_rec_a["Entity_"
                 "LegalAddress_"
                 "FirstAddressLine"] = fake.street_address().replace("\n", "")
      dstn_rec_a["Entity_LegalAddress_City"] = fake.city()
      dstn_rec_a["Entity_LegalAddress_Region"] = lcle["func"]()
      dstn_rec_a["Entity_LegalAddress_Country"] = fake.current_country()
      dstn_rec_a["Entity_LegalAddress_PostalCode"] = fake.postcode()
      dstn_rec_a[
          "Entity_"
          "HeadquartersAddress_xmllang"] = lei_rec[
              "Entity_LegalAddress_xmllang"]
      dstn_rec_a["Entity_HeadquartersAddress"
                 "_FirstAddressLine"] = dstn_rec_a[
                     "Entity_LegalAddress_FirstAddressLine"]
      dstn_rec_a["Entity_HeadquartersAddress_City"] = dstn_rec_a[
          "Entity_LegalAddress_City"]
      dstn_rec_a["Entity_HeadquartersAddress_Region"] = dstn_rec_a[
          "Entity_LegalAddress_Region"]
      dstn_rec_a["Entity_HeadquartersAddress_"
                 "Country"] = dstn_rec_a["Entity_LegalAddress_Country"]
      dstn_rec_a["Entity_"
                 "LegalJurisdiction"] = dstn_rec_a[
                     "Entity_LegalAddress_Country"]
      dstn_rec_a["Entity_LegalForm_"
                 "EntityLegalFormCode"] = fake.bothify("#??#")
      initial_renewal_date = fake.date_between(
          start_date="-2d", end_date="today")
      dstn_rec_a["Registration_"
                 "InitialRegistrationDate"] = str(initial_renewal_date)
      next_renewal_date = fake.date_between(start_date="+7d", end_date="+2y")
      dstn_rec_a["Registration_"
                 "NextRenewalDate"] = str(next_renewal_date)
      dstn_rec_a["Registration_LastUpdateDate"] = str(fake.date_between(
          start_date=initial_renewal_date,
          end_date=next_renewal_date))

      dstn_rec_b = dstn_data[i+1]
      dstn_rec_b = dstn_rec_a.copy()
      dstn_rec_b["LEI"] = self.make_random_lei()
      dstn_rec_b["Entity_"
                 "LegalName"] = dstn_rec_a[
                     "Entity_LegalName"].replace("Fund A", "Fund B")

      dstn_data[i] = dstn_rec_a
      dstn_data[i+1] = dstn_rec_b
      i = i+2

    # Update each "template" lei record
    # with distinct data for a subset of
    # fields
    for i in range(len(dstn_data)):
      dstn_d = dstn_data[i]
      lei_d = lei_recs[i]
      lei_recs[i] = dict(lei_d, **dstn_d)

    random.shuffle(lei_recs)

    return lei_recs

  def make_random_lei(self):
    """Generates random LEI value.

    Args:
      None
    Returns:
      string
    """
    fake = Faker()
    lei = list(fake.bothify(text="?????#####").upper())
    random.shuffle(lei)
    return "".join(lei)

  def make_random_fpml(self, list_len, lei_recs):
    """Generates random value for each appropriate element.

    Args:
      list_len: Length of list of randomized xml docs
      lei_recs: List of fake LEI records
    Returns:
      None
    """

      # Define index name to ISDA txn type dict,
      # select random product & assign its vals to FpML elements
    products = {
        "CDX-EMS36V1": {
            "txn_type": "CDX.EmergingMarkets",
            "price": 95.5977,
            "abovewater": False,
            "currency": "USD"
        },
        "CDX-NAHYS37V1": {
            "txn_type": "CDX.NorthAmericanHighYield",
            "price": 108.3472,
            "abovewater": True,
            "currency": "USD"
        },
        "CDX-NAIGS37V1": {
            "txn_type": "CDX.NorthAmericanEmergingMarkets",
            "price": 102.2502,
            "abovewater": True,
            "currency": "USD"
        },
        "ITRAXX-ASIAXJIGRESS34V1": {
            "txn_type": "iTraxxAsiaExJapan",
            "price": 101.5758,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-ASIAXJIGS36V1": {
            "txn_type": "iTraxxAsiaExJapan",
            "price": 100.9115,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-AUSTRALIAS36V1": {
            "txn_type": "iTraxxAustralia",
            "price": 101.5694,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-EUROPES36V1": {
            "txn_type": "iTraxxEurope",
            "price": 102.381,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-FINSENS36V1": {
            "txn_type": "iTraxxFinancials",
            "price": 101.9814,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-FINSUBS36V1": {
            "txn_type": "iTraxxFinancials",
            "price": 99.2764,
            "abovewater": True,
            "currency": "EUR"
        },
        "ITRAXX-XOVERS36V1": {
            "txn_type": "iTraxxCrossover",
            "price": 110.9993,
            "abovewater": True,
            "currency": "EUR"
        }
    }

    xml_docs = []
    rand_vals = {}

    for _ in tqdm.tqdm(range(list_len), "Generating Random Elements"):
      rand_vals["party_1_trade_id"] = str(uuid.uuid1())
      rand_vals["party_2_trade_id"] = str(uuid.uuid1())

      trade_date = (datetime.date.
                    today() - datetime.timedelta(days=random.
                                                 randrange(365)))
      rand_vals["trade_date"] = str(trade_date)

      sched_term_date = str(
          datetime.date(trade_date.year + random.choice([5, 10]),
                        random.choice([3, 6, 9, 12]), 20))
      rand_vals["sched_term_date"] = sched_term_date

      index_name = random.choice(list(products.keys()))
      rand_vals["index_name"] = index_name

      master_confirmation_type = products[index_name]["txn_type"]
      rand_vals["master_confirmation_type"] = master_confirmation_type

      notional_currency = products[index_name]["currency"]
      rand_vals["notional_currency"] = notional_currency

      # Separate lists of sellside and buyside firms
      sellside = [rec for rec
                  in lei_recs if "Bank" in rec["Entity_LegalName"]]
      buyside = [rec for rec
                 in lei_recs if "Bank" not in rec["Entity_LegalName"]]

      party_1_recs = sellside
      party_2_recs = buyside
      # For realism, sellside-to-sellside trades
      # occur about half the time
      if random.randrange(10) > 5:
        party_2_recs = sellside

      party_1 = random.choice(list(party_1_recs))
      party_1_id = party_1["LEI"]
      rand_vals["party_1_id"] = party_1_id
      party_1_name = f"""{party_1["Entity_LegalName"]}"""
      rand_vals["party_1_name"] = party_1_name

      party_2 = random.choice(list(party_2_recs))
      party_2_id = party_2["LEI"]
      rand_vals["party_2_id"] = party_2_id
      party_2_name = f"""{party_2["Entity_LegalName"]}"""
      rand_vals["party_2_name"] = party_2_name

      # For realism, for sellside-to-buyside trades, ensure
      # buyside may be seller and sellside may be buyer
      if random.randrange(10) > 5:
        buyer_party_reference = "party_1_id"
        seller_party_reference = "party_2_id"
      else:
        buyer_party_reference = "party_2_id"
        seller_party_reference = "party_1_id"
      rand_vals["buyer_party_reference"] = buyer_party_reference
      rand_vals["seller_party_reference"] = seller_party_reference

      # Pick random notional,
      # base initial payment amount on recent price of
      # product. Negative initial payment for risky products
      notional_amount = random.randrange(100) * 1000000
      rand_vals["notional_amount"] = str(notional_amount)

      price = products[index_name]["price"]
      fee_amount = int(notional_amount * (price / 10000))
      payer_party_reference = buyer_party_reference
      receiver_party_reference = seller_party_reference

      if not products[index_name]["abovewater"]:
        fee_amount = fee_amount * -1
        payer_party_reference = seller_party_reference
        receiver_party_reference = buyer_party_reference
      rand_vals["fee_amount"] = str(fee_amount)
      rand_vals["payer_party_reference"] = payer_party_reference
      rand_vals["receiver_party_reference"] = receiver_party_reference

      xml_etree = et.parse("./qd-input-data-template.xml")

      # For each random val find etree's
      # element & update & add to list
      for k, v in rand_vals.items():
        xpath = self.els_maps.get(k)["xpath"]
        xpath_index = self.els_maps.get(k)["xpath_index"]
        xml_etree.findall(xpath)[xpath_index].text = v

      xml_docs.append(copy.deepcopy(xml_etree))

    random.shuffle(xml_docs)
    return xml_docs

  def write_fpml_to_bq(self, xml_trees, client, table_id) -> StringIO:
    """
    Saves fields from random FpML tree into BigQuery.
    Note, each string copied twice, once for each counterparty, because
    ideally for each deal a regulator would have two copies
    (one reported by each
    of two counterlei_recs).

    Args:
      :param xml_trees: list of dicts of XML data
      :param client:         BigQuery Client
      :param table_id:       Full table_id target for BigQuery
    Returns:
      None
    """

    # Create data
    data_rows = []
    for xml_tree in tqdm.tqdm(xml_trees, "Flattening data"):
      d = {}
      for field_name, xpath_dict in self.els_maps.items():
        xpath = xpath_dict.get("xpath")
        xpath_index = xpath_dict.get("xpath_index")
        val = xml_tree.findall(xpath)[xpath_index].text
        d[field_name] = val.strip(" \t\n")
      data_rows.append(d.copy())
    # TODO(matait@): Add dupe/reporting counterparty

    # Load into BigQuery
    print(f"{table_id}: Loading data into BigQuery")
    job = client.load_table_from_json(data_rows, table_id)

    job.result()  # Waits for the job to complete.

    # Gather statistics of target table
    table = client.get_table(table_id)
    print(f"{table_id}: There are {table.num_rows} rows and " + f"{len(table.schema)} columns")

  def write_lei_recs_to_bq(self, lei_recs, client, table_id):
    """
    Saves fields from list of fake LEI records into a CSV file.

    Args:
      :param lei_recs:       list of dicts of XML data
      :param client:         BigQuery Client
      :param table_id:       Full table_id target for BigQuery
    Returns:
      None
    """

    # Load into BigQuery
    print(f"{table_id}: Loading data into BigQuery")
    job = client.load_table_from_json(lei_recs, table_id)

    job.result()  # Waits for the job to complete.

    # Gather statistics of target table
    table = client.get_table(table_id)
    print(f"{table_id}: There are {table.num_rows} rows and " + f"{len(table.schema)} columns")

  def write_fpml(self, xml_docs, output_file_path="qd_fpml_output/"):
    """Saves each randomized FpML tree into a separate XML file.

    Args:
      xml_docs: list of dicts of XML data
      output_file_path: the name of the output file
    Returns:
      None
    """
    for tree in tqdm.tqdm(xml_docs, "Writing FpML"):
      # Method call is to et module, not tree class
      et.register_namespace("",
                            "http://www.fpml.org/FpML-5/confirmation")
      tree.write(f"{output_file_path}{uuid.uuid1()}.xml")

if __name__ == "__main__":
  """ Generates test data for QD and loads into Big Query
  """
  # Arguments
  parser = argparse.ArgumentParser(description='Create random QD records')
  parser.add_argument('--project_id',
                      required=True,
                      help='The GCP project ID where the data should be loaded')
  parser.add_argument('--bq_dataset',
                      required=True,
                      help='The BigQuery dataset where the data should be loaded')
  parser.add_argument('--num_counterparties',
                      required=True,
                      help='The number of counterparties to be created')
  parser.add_argument('--num_records',
                      required=True,
                      help='The number of records to be created')

  args = parser.parse_args()
  bigquery_client = bigquery.Client(project=args.project_id)

  # Instantiate the data generator class
  generator = QdDataGenerator()

  # Generate random data
  lei_list = generator.make_random_leis(int(args.num_counterparties))
  fpml_dict = generator.make_random_fpml(int(args.num_records), lei_list)
  generator.write_fpml(fpml_dict)

  # Write the data to BQ
  generator.write_fpml_to_bq(xml_trees=fpml_dict,
                             client=bigquery_client,
                             table_id=f"{args.project_id}.{args.bq_dataset}.boe_qd_cds_deal_level_granular")

  generator.write_lei_recs_to_bq(lei_list,
                             client=bigquery_client,
                             table_id=f"{args.project_id}.{args.bq_dataset}.boe_qd_lei_records")

  print("FpML and JSON generation complete and data loaded to BQ")
