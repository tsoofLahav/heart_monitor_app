import os
import logging

from flask import Flask, request, jsonify

from video_edit import process_video_frames, get_video_duration_seconds
from filter_and_peaks import (
    denoise_ppg,
    find_peaks,
    filter_peaks_to_window,
    validate_peaks_quality,
    compute_quality_metrics,
    build_fake_peaks,
)
from session_timing import parse_recording_started_at, build_peak_window_metadata

logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s %(message)s", force=True)


def setup_video_route(app):
    @app.route('/process_video', methods=['POST'])
    def process_video():
        video_path = './temp_video.mp4'
        try:
            file = request.files.get('video')
            if not file:
                return jsonify({'error': 'No video file received.'}), 400

            recording_started_at = parse_recording_started_at(
                request.form.get('recording_started_at')
            )

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
            window_lo = peak_window['peak_window_start_sec']
            window_hi = peak_window['peak_window_end_sec']

            clean_signal, _filtered_signal = denoise_ppg(intensities, fps)
            peaks_all = find_peaks(clean_signal, fps)
            real_peaks = filter_peaks_to_window(peaks_all, duration)

            quality = compute_quality_metrics(real_peaks, duration, fps, width, height)

            if not validate_peaks_quality(real_peaks, duration):
                return jsonify({'not_reading': True}), 200

            fake_peaks = build_fake_peaks(real_peaks, window_lo, window_hi)
            signal = [float(x) for x in clean_signal]

            return jsonify({
                'signal': signal,
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
            }), 200

        except Exception as e:
            logging.exception('Unhandled exception:')
            return jsonify({'server_error': True, 'error': str(e)}), 500
        finally:
            if os.path.exists(video_path):
                try:
                    os.remove(video_path)
                except OSError:
                    pass
