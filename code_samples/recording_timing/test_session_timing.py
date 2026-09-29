from datetime import datetime, timezone
import unittest

from session_timing import build_peak_window_metadata


class SessionTimingTests(unittest.TestCase):
    def test_legacy_client_keeps_existing_window(self):
        result = build_peak_window_metadata(23)
        self.assertEqual(result['peak_window_start_sec'], 3)
        self.assertEqual(result['peak_window_end_sec'], 22.5)

    def test_cues_define_window_and_utc_bounds(self):
        result = build_peak_window_metadata(24.3,
            datetime(2026, 9, 8, tzinfo=timezone.utc), '3.1', '23.1')
        self.assertEqual(result['peak_window_start_sec'], 3.1)
        self.assertEqual(result['peak_window_end_sec'], 23.1)
        self.assertEqual(result['peak_window_start_utc'], '2026-09-08T00:00:03.100Z')
        self.assertEqual(result['peak_window_end_utc'], '2026-09-08T00:00:23.100Z')

    def test_invalid_intervals_are_not_silently_clamped(self):
        for start, end in [(None, '20'), ('3', None), ('nan', '20'),
                           ('3', 'inf'), ('2', '20'), ('20', '3'),
                           ('3', '25'), ('3', '3'), ('x', '20')]:
            with self.subTest(start=start, end=end), self.assertRaises(ValueError):
                build_peak_window_metadata(24, counting_start_sec=start, counting_end_sec=end)
