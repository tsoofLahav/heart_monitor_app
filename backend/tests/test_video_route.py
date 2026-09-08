"""Video API contract tests, without a camera, SQL connection or ML runtime."""
import importlib.util
import io
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import Mock, patch

from flask import Flask


class VideoRouteTests(unittest.TestCase):
    def setUp(self):
        self.saved_paths = []
        self.video = types.ModuleType('video_edit')
        self.video.get_video_duration_seconds = Mock(return_value=13.0)

        def frames(path, target_duration):
            self.saved_paths.append(path)
            self.assertTrue(Path(path).exists())
            return 30.0, [1.0] * 390, 13.0, 640, 480

        self.video.process_video_frames = Mock(side_effect=frames)
        self.signal = types.ModuleType('filter_and_peaks')
        methods = {
            'denoise_ppg': ([0.1] * 300, [0.1] * 300),
            'stable_signal_duration_sec': 10.0,
            'find_peaks': [1.0, 2.0],
            'peaks_local_to_video': [4.0, 5.0],
            'filter_peaks_to_window': [4.0, 5.0],
            'peaks_video_to_local': [1.0, 2.0],
            'compute_quality_metrics': {'peaks_count': 2, 'mean_hr_bpm': 60.0},
            'peak_detection_window_local': (0.5, 9.5),
            'build_fake_peaks': [1.1, 2.1],
        }
        for name, result in methods.items():
            setattr(self.signal, name, Mock(return_value=result))
        self.signal.SIGNAL_START_OFFSET_SEC = 3.0
        self.timing = types.ModuleType('session_timing')
        self.timing.parse_recording_started_at = Mock(return_value=None)
        self.timing.build_peak_window_metadata = Mock(return_value={
            'peak_window_start_sec': 3.5, 'peak_window_end_sec': 12.5,
        })
        self.ml = types.ModuleType('ppg_quality.classifier')
        self.ml.classify_signal_windows = Mock(return_value={
            'quality_label': 'bad', 'quality_prob_good': 0.1,
            'quality_prob_bad': 0.9, 'quality_windows': [{'label': 'bad'}],
        })
        spec = importlib.util.spec_from_file_location(
            'video_route_under_test', Path(__file__).resolve().parents[1] / 'video_route.py')
        module = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {
            'video_edit': self.video, 'filter_and_peaks': self.signal,
            'session_timing': self.timing, 'ppg_quality.classifier': self.ml,
        }):
            spec.loader.exec_module(module)
        app = Flask(__name__)
        module.setup_video_route(app)
        self.client = app.test_client()

    def upload(self):
        return self.client.post('/process_video', data={
            'video': (io.BytesIO(b'video fixture'), 'clip.mp4'),
            'recording_started_at': '2026-09-08T10:00:00Z',
        })

    def test_ml_bad_label_preserves_signal_response_and_cleans_upload(self):
        response = self.upload()
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data['quality_label'], 'bad')
        self.assertEqual(data['real_peaks'], [1.0, 2.0])
        self.assertEqual(data['fake_peaks'], [1.1, 2.1])
        self.assertEqual(len(data['signal']), 300)
        self.assertEqual(data['signal_start_sec'], 3.0)
        self.assertEqual(data['signal_end_sec'], 13.0)
        self.assertNotIn('not_reading', data)
        self.ml.classify_signal_windows.assert_called_once()
        self.assertTrue(all(not Path(p).exists() for p in self.saved_paths))

    def test_good_label_is_returned(self):
        self.ml.classify_signal_windows.return_value.update(
            quality_label='good', quality_prob_good=0.9, quality_prob_bad=0.1)
        self.assertEqual(self.upload().get_json()['quality_label'], 'good')

    def test_missing_upload_is_client_error(self):
        self.assertEqual(self.client.post('/process_video').status_code, 400)
        self.ml.classify_signal_windows.assert_not_called()

    def test_processing_failure_is_server_error_and_cleans_upload(self):
        self.ml.classify_signal_windows.side_effect = RuntimeError('model unavailable')
        response = self.upload()
        self.assertEqual(response.status_code, 500)
        self.assertTrue(response.get_json()['server_error'])
        self.assertTrue(all(not Path(p).exists() for p in self.saved_paths))


if __name__ == '__main__':
    unittest.main()
