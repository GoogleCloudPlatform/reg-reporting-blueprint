# Copyright 2022 The Reg Reporting Blueprint Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Spark Python job that will calculate RWA using NumPy
#

#
# Setup:
# - Inspect the profile.yml in the profiles directory.
# - Specify the dataproc cluster name (if not using serverless),
#   validate the region. (Should use environment variable)
# - Grant access to the default compute service account to the homeloan_dev
#   dataset. (Very important -- not done by terraform.)
# - Ensure the subnet used by Dataproc (likely the default network -- not best
#   practice) has Google Private Access enabled.
#   https://console.cloud.google.com/networking/networks/list?project=<project>&pageTab=CURRENT_PROJECT_SUBNETS
#   ... and edit the subnet and enable Google Private Access.
#
# Running:
# dbt run -s tag:rwa -m models/stats/calc_rwa.py
#

#
# Define the residential RWA calculation
#


from scipy.stats import norm

def residential_rwa(pd, lgd, ead):
    """Calculates the RWA based on section 328 for residential mortgage exposures.

       See https://www.bis.org/publ/bcbs128b.pdf for source

       Correlation (R) = 0.15
       Capital requirement (K) = LGD × N[(1 – R)^-0.5 × G(PD) +
                                        (R / (1 – R))^0.5 × G(0.999)] – PD x LGD
       Risk-weighted assets = K x 12.5 x EAD

       NOTE - this is an example of a complex calculation and in no way means
       it is fit for purpose.
    """
    corr = 0.15
    factor = norm.cdf((1-corr)**(-0.5) * norm.ppf(pd) +
                      (corr/(1-corr))**(0.5) * norm.ppf(0.999))
    capital_requirement = (factor - pd) * lgd
    return capital_requirement * 12.5 * ead


#
# Define the mapping from a Spark UDF to the pandas function
#
# This is a wrapper for the numpy algorithm.
#

import pandas as pd

from pyspark.sql.functions import pandas_udf, lit
from pyspark.sql.types import DoubleType


@pandas_udf(DoubleType())
def residential_rwa_wrapper(pd: pd.Series, lgd: pd.Series, ead: pd.Series) -> pd.Series:
    return residential_rwa(pd, lgd, ead)


#
# Pyspark DBT Model
#


def model(dbt, session):

  # Dataframe (Spark) is the history table
  df = dbt.ref("wh_denormalised_history")

  # Return the result of applying the rwa wrapper
  #
  # Literals (constants) are used for PD and LGD, but
  # can be substituted with real columns.
  #
  return df.withColumn(
      "rwa",
      residential_rwa_wrapper(
          lit(0.01),                  # PD
          lit(0.1),                   # LGD
          df.account.account_balance  # EAD
      )
  )
