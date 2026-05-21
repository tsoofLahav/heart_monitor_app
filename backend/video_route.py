import numpy as np
from flask import Flask, request, jsonify
import os
import logging

from video_edit import process_video_frames, get_video_duration_seconds
from filter_and_peaks import denoise_ppg, find_peaks
import globals

logging.basicConfig(level=logging.DEBUG, format="%(asctime)s %(levelname)s %(message)s", force=True)


def setup_video_route(app):
    @app.route('/process_video', methods=['POST'])
    def process_video():
        try:
            globals.reset_all()

            file = request.files.get('video')
            if not file:
                return jsonify({'error': 'No video file received.'}), 400

            video_path = './temp_video.mp4'
            file.save(video_path)
            if not os.path.exists(video_path) or os.path.getsize(video_path) == 0:
                raise Exception("Invalid video file.")

            duration_sec = get_video_duration_seconds(video_path)
            fps, intensities, processed_duration = process_video_frames(
                video_path, target_duration=duration_sec
            )
            if not intensities:
                raise Exception("No frames were processed.")

            globals.session_duration = float(processed_duration)

            clean_signal, filtered_signal, not_reading = denoise_ppg(intensities, fps)

            if not_reading:
                return jsonify({'not_reading': True}), 200

            peaks_in_window = find_peaks(clean_signal, fps)
            upper = max(globals.session_duration - 0.5, 0.5)
            final_peaks = [x for x in peaks_in_window if 0.5 <= x <= upper]

            globals.add_to_round_signal(clean_signal)
            globals.add_to_round_peaks(final_peaks)
            globals.round_count = 1

            if globals.testing_mode:
                return jsonify({
                    'clean_signal': clean_signal.tolist(),
                    'filtered_signal': filtered_signal.tolist(),
                    'peaks_in_window': peaks_in_window,
                    'duration': globals.session_duration,
                }), 200

            return jsonify({
                'message': 'Processed successfully.',
                'duration': globals.session_duration,
            }), 200

        except Exception as e:
            logging.exception("Unhandled exception:")
            globals.reset_all()
            return jsonify({'server_error': True, 'error': str(e)}), 500
