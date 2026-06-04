import random

import numpy as np
from scipy.signal import butter, sosfiltfilt, find_peaks as scipy_find_peaks

EDGE_GAP_SEC = 0.5
RAW_WARMUP_SEC = 0.5
POST_FILTER_TRIM_SEC = 1.5
SIGNAL_START_OFFSET_SEC = RAW_WARMUP_SEC + POST_FILTER_TRIM_SEC
MIN_STABLE_SIGNAL_SEC = 5.0
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
    """Normalize the signal to have mean 0 and std 1 (on the stable segment only)."""
    mean = np.mean(signal)
    std = np.std(signal)
    return (signal - mean) / (std + 1e-8)


def _trim_start(signal, trim_sec, fs):
    signal = np.asarray(signal)
    drop = int(trim_sec * fs)
    if drop <= 0:
        return signal
    if drop >= len(signal):
        return np.array([], dtype=signal.dtype)
    return signal[drop:]


def denoise_ppg(raw_signal, fs):
    """
    Trim warm-up, bandpass, trim filter transients, normalize on stable segment.
    Returns (normalized_signal, filtered_signal).
    """
    raw_signal = np.array(raw_signal)
    raw_signal = _trim_start(raw_signal, RAW_WARMUP_SEC, fs)
    if len(raw_signal) < 2:
        return np.array([]), np.array([])

    filtered_signal = butter_bandpass_filter(raw_signal, fs)
    filtered_signal = _trim_start(filtered_signal, POST_FILTER_TRIM_SEC, fs)
    if len(filtered_signal) < 2:
        return np.array([]), np.array([])

    normalized_signal = regularize_signal(filtered_signal)
    return normalized_signal, filtered_signal


def stable_signal_duration_sec(signal, fs):
    if fs <= 0 or len(signal) == 0:
        return 0.0
    return len(signal) / float(fs)


def peaks_local_to_video(peaks_sec, time_offset_sec=SIGNAL_START_OFFSET_SEC):
    return [float(p) + time_offset_sec for p in peaks_sec]


def peaks_video_to_local(peaks_sec, time_offset_sec=SIGNAL_START_OFFSET_SEC):
    return [float(p) - time_offset_sec for p in peaks_sec]


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
    """Find systolic peaks; returns peak times in seconds (relative to stable signal start)."""
    signal = np.array(signal)
    distance = max(1, int(fs * 0.33))
    prominence = 0.4
    peaks, _ = scipy_find_peaks(signal, distance=distance, prominence=prominence)
    peaks = _merge_close_peaks(peaks, signal, fs)
    return (peaks / fs).tolist()


def peak_detection_window(duration_sec):
    """Valid peak time range in seconds relative to video start."""
    start_sec = max(EDGE_GAP_SEC, SIGNAL_START_OFFSET_SEC)
    end_sec = max(start_sec, float(duration_sec) - EDGE_GAP_SEC)
    return start_sec, end_sec


def peak_detection_window_local(video_duration_sec):
    """Peak window mapped onto the returned (trimmed) signal timeline."""
    video_lo, video_hi = peak_detection_window(video_duration_sec)
    stable_duration = max(0.0, float(video_duration_sec) - SIGNAL_START_OFFSET_SEC)
    return (
        max(0.0, video_lo - SIGNAL_START_OFFSET_SEC),
        min(stable_duration, max(0.0, video_hi - SIGNAL_START_OFFSET_SEC)),
    )


def filter_peaks_to_window(peaks_sec, duration_sec):
    start_sec, end_sec = peak_detection_window(duration_sec)
    return [p for p in peaks_sec if start_sec <= p <= end_sec]


def compute_quality_metrics(
    peaks_sec,
    video_duration_sec,
    fps,
    video_width,
    video_height,
    stable_duration_sec=None,
):
    """Quality summary for a peak list (may reflect a failed read)."""
    peaks = sorted(float(p) for p in peaks_sec)
    stable_duration_sec = (
        float(stable_duration_sec)
        if stable_duration_sec is not None
        else max(0.0, float(video_duration_sec) - SIGNAL_START_OFFSET_SEC)
    )
    metrics = {
        'fps': round(float(fps), 2),
        'video_width': int(video_width),
        'video_height': int(video_height),
        'video_duration_sec': round(float(video_duration_sec), 3),
        'duration_sec': round(stable_duration_sec, 3),
        'signal_start_sec': round(SIGNAL_START_OFFSET_SEC, 3),
        'signal_end_sec': round(SIGNAL_START_OFFSET_SEC + stable_duration_sec, 3),
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
