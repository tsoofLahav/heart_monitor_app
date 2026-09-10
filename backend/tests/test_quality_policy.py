import unittest
from unittest.mock import patch

import numpy as np
from ppg_quality.classifier import classify_signal_windows, quality_windows


class QualityPolicyTests(unittest.TestCase):
    def test_acceptance_boundaries(self):
        for parts in range(1, 9):
            allowance = 0 if parts <= 3 else (1 if parts <= 5 else 2)
            for bad in range(parts + 1):
                with self.subTest(parts=parts, bad=bad):
                    predictions = [('bad', 0.1)] * bad + [('good', 0.9)] * (parts - bad)
                    with patch('ppg_quality.classifier._load_model_bundle', return_value={}), \
                         patch('ppg_quality.classifier._predict_window', side_effect=predictions):
                        result = classify_signal_windows(np.zeros(parts * 300), [], 30, parts * 10)
                    self.assertEqual(result['quality_label'], 'good' if bad <= allowance else 'bad')
                    self.assertEqual(result['quality_bad_windows'], bad)
                    self.assertEqual(result['quality_allowed_bad_windows'], allowance)
                    self.assertEqual(len(result['quality_windows']), parts)

    def test_overlapping_last_window_counts_as_a_part(self):
        self.assertEqual(quality_windows(35), [(0, 10), (10, 20), (20, 30), (25, 35)])

    def test_tolerated_window_is_still_reported_as_bad(self):
        with patch('ppg_quality.classifier._load_model_bundle', return_value={}), \
             patch('ppg_quality.classifier._predict_window', side_effect=[('bad', .1)] + [('good', .9)] * 3):
            result = classify_signal_windows(np.zeros(1200), [], 30, 40)
        self.assertEqual(result['quality_label'], 'good')
        self.assertEqual(result['quality_prob_good'], .1)
        self.assertEqual(result['quality_windows'][0]['label'], 'bad')
