#!/usr/bin/env python3

import tensorflow as tf
import unittest

from rwa_model import RWA

class RWATestCase(unittest.TestCase):

  def setUp(self):
    self.model = RWA()

  def test_residential_rwa(self):
    result = self.model.residential_rwa(
      tf.constant([0.01], dtype=tf.float32),     # PD
      tf.constant([0.1], dtype=tf.float32),      # LGD
      tf.constant([800000.0], dtype=tf.float32), # EAD
    )
    self.assertEqual(result['rwa'], 100265.086)

if __name__ == "__main__":
  unittest.main()

