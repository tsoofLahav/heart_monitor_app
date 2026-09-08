import logging
import os
import tempfile

from flask import Flask, request, jsonify

from video_edit import process_video_frames, get_video_duration_seconds
from filter_and_peaks import (
    denoise_ppg,
    find_peaks,
    filter_peaks_to_window,
    compute_quality_metrics,
    build_fake_peaks,
    peaks_local_to_video,
    peaks_video_to_local,
    peak_detection_window_local,
    stable_signal_duration_sec,
    SIGNAL_START_OFFSET_SEC,
)
from session_timing import parse_recording_started_at, build_peak_window_metadata
from ppg_quality.classifier import classify_signal_windows

logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s %(message)s", force=True)


def setup_video_route(app):
    @app.route('/process_video', methods=['POST'])
    def process_video():
        video_path = None
        try:
            file = request.files.get('video')
            if not file:
                return jsonify({'error': 'No video file received.'}), 400

            recording_started_at = parse_recording_started_at(
                request.form.get('recording_started_at')
            )

            with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as tmp:
                video_path = tmp.name
            file.save(video_path)
            if not os.path.exists(video_path) or os.path.getsize(video_path) == 0:
                raise Exception('Invalid video file.')

            duration_sec = get_video_duration_seconds(video_path)
            fps, intensities, processed_duration, width, height = process_video_frames(
                video_path, target_duration=duration_sec
            )
            if not intensities:
                raise Exception('No frames were processed.')

            duration = float(processed_duration)
            peak_window = build_peak_window_metadata(duration, recording_started_at)

            clean_signal, _filtered_signal = denoise_ppg(intensities, fps)
            stable_duration = stable_signal_duration_sec(clean_signal, fps)
            peaks_local = find_peaks(clean_signal, fps)
            peaks_video = peaks_local_to_video(peaks_local)
            real_peaks_video = filter_peaks_to_window(peaks_video, duration)
            real_peaks = peaks_video_to_local(real_peaks_video)

            quality = compute_quality_metrics(
                real_peaks_video,
                duration,
                fps,
                width,
                height,
                stable_duration_sec=stable_duration,
            )

            window_lo_local, window_hi_local = peak_detection_window_local(duration)
            fake_peaks = build_fake_peaks(real_peaks, window_lo_local, window_hi_local)
            signal = [float(x) for x in clean_signal]

            ml_quality = classify_signal_windows(
                signal=clean_signal,
                peaks_local=real_peaks,
                fs=fps,
                duration_sec=stable_duration,
            )

            return jsonify({
                'signal': signal,
                'signal_start_sec': SIGNAL_START_OFFSET_SEC,
                'signal_end_sec': round(SIGNAL_START_OFFSET_SEC + stable_duration, 3),
                'real_peaks': real_peaks,
                'fake_peaks': fake_peaks,
                'peak_window_start_sec': peak_window['peak_window_start_sec'],
                'peak_window_end_sec': peak_window['peak_window_end_sec'],
                **(
                    {
                        'peak_window_start_utc': peak_window['peak_window_start_utc'],
                        'peak_window_end_utc': peak_window['peak_window_end_utc'],
                    }
                    if 'peak_window_start_utc' in peak_window
                    else {}
                ),
                'quality': quality,
                'quality_label': ml_quality['quality_label'],
                'quality_prob_good': ml_quality['quality_prob_good'],
                'quality_prob_bad': ml_quality['quality_prob_bad'],
                'quality_windows': ml_quality['quality_windows'],
            }), 200

        except Exception as e:
            logging.exception('Unhandled exception:')
            return jsonify({'server_error': True, 'error': str(e)}), 500
        finally:
            if video_path and os.path.exists(video_path):
                try:
                    os.remove(video_path)
                except OSError:
                    pass
