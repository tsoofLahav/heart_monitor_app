import logging
import os
import tempfile

from flask import Flask, request, jsonify

from video_edit import process_video_frames, get_video_duration_seconds
from filter_and_peaks import (
    denoise_ppg,
    find_peaks,
    compute_quality_metrics,
    build_fake_peaks,
    peaks_local_to_video,
    peaks_video_to_local,
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
            try:
                peak_window = build_peak_window_metadata(
                    duration, recording_started_at,
                    request.form.get('counting_start_sec'),
                    request.form.get('counting_end_sec'),
                )
            except ValueError as exc:
                return jsonify({'error': str(exc)}), 400
            window_lo = peak_window['peak_window_start_sec']
            window_hi = peak_window['peak_window_end_sec']

            clean_signal, _filtered_signal = denoise_ppg(intensities, fps)
            stable_duration = stable_signal_duration_sec(clean_signal, fps)
            peaks_local = find_peaks(clean_signal, fps)
            peaks_video = peaks_local_to_video(peaks_local)
            real_peaks_video = [p for p in peaks_video if window_lo <= p <= window_hi]
            real_peaks = peaks_video_to_local(real_peaks_video)

            quality = compute_quality_metrics(
                real_peaks_video,
                duration,
                fps,
                width,
                height,
                stable_duration_sec=stable_duration,
            )

            window_lo_local = window_lo - SIGNAL_START_OFFSET_SEC
            window_hi_local = window_hi - SIGNAL_START_OFFSET_SEC
            fake_peaks = build_fake_peaks(real_peaks, window_lo_local, window_hi_local)
            signal = [float(x) for x in clean_signal]

            # New clients classify the interval the participant actually counted.
            # Keep the returned signal on its existing trimmed-video timeline.
            has_cues = request.form.get('counting_start_sec') is not None
            if has_cues:
                quality['duration_sec'] = round(window_hi - window_lo, 3)
                first = max(0, int(round(window_lo_local * fps)))
                last = min(len(clean_signal), int(round(window_hi_local * fps)))
                ml_signal = clean_signal[first:last]
                ml_peaks = [p - window_lo_local for p in real_peaks]
                ml_duration = window_hi - window_lo
            else:
                ml_signal, ml_peaks, ml_duration = clean_signal, real_peaks, stable_duration
            ml_quality = classify_signal_windows(
                signal=ml_signal,
                peaks_local=ml_peaks,
                fs=fps,
                duration_sec=ml_duration,
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
                'quality_window_origin_sec': window_lo if has_cues else SIGNAL_START_OFFSET_SEC,
                'quality_bad_windows': ml_quality['quality_bad_windows'],
                'quality_allowed_bad_windows': ml_quality['quality_allowed_bad_windows'],
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
