#!/usr/bin/env python3

from typing import Optional

import os
import tensorflow as tf
import tensorflow_probability as tfp


class RWA(tf.Module):

  def __init__(self, name: Optional[str] = None):
    self.norm = tfp.distributions.Normal(loc=0, scale=1.0)
    pass

  @tf.function(input_signature=[
      tf.TensorSpec(
          [None], dtype=tf.float32, name='probability_of_default'),
      tf.TensorSpec(
          [None], dtype=tf.float32, name='loss_given_default'),
      tf.TensorSpec(
          [None], dtype=tf.float32, name='exposure_at_default'),
  ])
  def residential_rwa(self, pd, lgd, ead):
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
      factor = self.norm.cdf(
                tf.math.pow(1-corr, -0.5) * self.norm.quantile(pd) +
                tf.math.pow(corr/(1-corr), 0.5) * self.norm.quantile(0.999))
      capital_requirement = (lgd * factor) - (pd * lgd)
      rwa = capital_requirement * 12.5 * ead

      return {
          "rwa": rwa,
          "capital_requirement": capital_requirement,
      }


#
# Save the model
#
def save_model():
  if not os.environ['GCS_INGEST_BUCKET']:
    print(f'GCS_INGEST_BUCKET must be defined')
    return

  save_path = f'gs://{os.environ["GCS_INGEST_BUCKET"]}/models/homeloan/rwa'

  model = RWA()
  tf.saved_model.save(model,
                      save_path,
                      signatures={'serving_default': model.residential_rwa})

  print(f'\nSaved model to {save_path}')


if __name__ == '__main__':
  save_model()

