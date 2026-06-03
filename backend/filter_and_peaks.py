import random

import numpy as np
from scipy.signal import butter, sosfiltfilt, find_peaks as scipy_find_peaks

EDGE_GAP_SEC = 0.5
MIN_HR_BPM = 45.0
MAX_HR_BPM = 150.0
MAX_IBI_CV = 0.25
REFRACTORY_MIN_SEC = 0.20
REFRACTORY_IBI_FRAC = 0.30


def butter_bandpass_filter(signal, fs, lowcut=0.8, highcut=3.0, order=6):
    """Applies a band-pass filter using second-order sections (SOS) for stability."""
    nyq = 0.5 * fs
    low, high = lowcut / nyq, highcut / nyq
    sos = butter(order, [low, high], btype='band', output='sos')
    return sosfiltfilt(sos, signal)


def regularize_signal(signal):
    """Normalize the signal to have mean 0 and std 1."""
    mean = np.mean(signal)
    std = np.std(signal)
    return (signal - mean) / (std + 1e-8)


def denoise_ppg(raw_signal, fs):
    """Bandpass + normalize. Returns (normalized_signal, filtered_signal)."""
    raw_signal = np.array(raw_signal)
    filtered_signal = butter_bandpass_filter(raw_signal, fs)
    normalized_signal = regularize_signal(filtered_signal)
    return normalized_signal, filtered_signal


def _merge_close_peaks(peak_indices, signal, fs):
    """
    Drop shorter peaks when two detections fall within one beat (e.g. dicrotic notch).
    Keeps the sample with the larger signal value.
    """
    if len(peak_indices) <= 1:
        return peak_indices

    peak_indices = np.sort(np.asarray(peak_indices, dtype=int))
    signal = np.asarray(signal)

    mean_ibi_sec = float(np.mean(np.diff(peak_indices)) / fs)
    min_gap_sec = max(REFRACTORY_MIN_SEC, REFRACTORY_IBI_FRAC * mean_ibi_sec)
    min_gap_samples = max(1, int(min_gap_sec * fs))

    kept = [int(peak_indices[0])]
    for idx in peak_indices[1:]:
        idx = int(idx)
        if idx - kept[-1] < min_gap_samples:
            if signal[idx] > signal[kept[-1]]:
                kept[-1] = idx
        else:
            kept.append(idx)
    return np.array(kept, dtype=int)


def find_peaks(signal, fs):
    """Find systolic peaks; returns peak times in seconds (relative to video start)."""
    signal = np.array(signal)
    distance = max(1, int(fs * 0.33))
    prominence = 0.4
    peaks, _ = scipy_find_peaks(signal, distance=distance, prominence=prominence)
    peaks = _merge_close_peaks(peaks, signal, fs)
    return (peaks / fs).tolist()


def peak_detection_window(duration_sec):
    """Valid peak time range in seconds relative to video start."""
    start_sec = EDGE_GAP_SEC
    end_sec = max(float(duration_sec) - EDGE_GAP_SEC, EDGE_GAP_SEC)
    return start_sec, end_sec


def filter_peaks_to_window(peaks_sec, duration_sec):
    start_sec, end_sec = peak_detection_window(duration_sec)
    return [p for p in peaks_sec if start_sec <= p <= end_sec]


def compute_quality_metrics(peaks_sec, duration_sec, fps, video_width, video_height):
    """Quality summary for a peak list (may reflect a failed read)."""
    peaks = sorted(float(p) for p in peaks_sec)
    metrics = {
        'fps': round(float(fps), 2),
        'video_width': int(video_width),
        'video_height': int(video_height),
        'duration_sec': round(float(duration_sec), 3),
        'peaks_count': len(peaks),
        'mean_hr_bpm': None,
        'ibi_cv': None,
    }
    if len(peaks) >= 2:
        ibis = np.diff(peaks)
        mean_ibi = float(np.mean(ibis))
        if mean_ibi > 0:
            metrics['mean_hr_bpm'] = round(60.0 / mean_ibi, 2)
            metrics['ibi_cv'] = round(float(np.std(ibis) / mean_ibi), 4)
    return metrics


def validate_peaks_quality(peaks_sec, duration_sec):
    """Reject artifact-heavy segments: beat count, HR, and IBI regularity."""
    peaks = sorted(float(p) for p in peaks_sec)
    if len(peaks) < 2:
        return False

    ibis = np.diff(peaks)
    mean_ibi = float(np.mean(ibis))
    if mean_ibi <= 0:
        return False

    hr_bpm = 60.0 / mean_ibi
    if hr_bpm < MIN_HR_BPM or hr_bpm > MAX_HR_BPM:
        return False

    cv = float(np.std(ibis) / mean_ibi)
    if cv > MAX_IBI_CV:
        return False

    min_beats = max(3, int(duration_sec * 40 / 60 * 0.75))
    max_beats = int(duration_sec * 160 / 60 * 1.25) + 2
    if len(peaks) < min_beats or len(peaks) > max_beats:
        return False

    return True


def build_fake_peaks(real_peaks, window_lo, window_hi):
    fake = []
    for p in real_peaks:
        jittered = round(p + random.uniform(-0.1, 0.1), 2)
        jittered = max(window_lo, min(jittered, window_hi))
        fake.append(jittered)
    return fake
