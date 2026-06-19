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
MAX_IBI_CV = 0.30
REFRACTORY_MIN_SEC = 0.20
REFRACTORY_IBI_FRAC = 0.30

OUTLIER_MAD_SCALE = 4.0
MAX_OUTLIER_FRAC = 0.02
BEAT_CORRELATION_THRESHOLD = 0.32
MIN_PEAK_PROMINENCE = 0.58
PEAK_MIN_DISTANCE_SEC = 0.45
PEAK_HEIGHT_MEDIAN_FRAC = 0.50
MAX_PEAK_AMPLITUDE_CV = 0.42
MAX_BEAT_COUNT_FACTOR = 1.10


def butter_bandpass_filter(signal, fs, lowcut=0.8, highcut=3.0, order=6):
    """Applies a band-pass filter using second-order sections (SOS) for stability."""
    nyq = 0.5 * fs
    low, high = lowcut / nyq, highcut / nyq
    sos = butter(order, [low, high], btype='band', output='sos')
    return sosfiltfilt(sos, signal)


def _robust_scale(signal):
    signal = np.asarray(signal)
    mad = np.median(np.abs(signal - np.median(signal)))
    return float(mad * 1.4826 + 1e-8)


def _clip_outliers(signal, mad_scale=OUTLIER_MAD_SCALE):
    signal = np.asarray(signal)
    med = np.median(signal)
    scale = _robust_scale(signal)
    return np.clip(signal, med - mad_scale * scale, med + mad_scale * scale)


def regularize_signal(signal):
    """Robust normalize: clip outliers, then median/MAD scaling."""
    signal = _clip_outliers(np.asarray(signal))
    med = np.median(signal)
    scale = _robust_scale(signal)
    return (signal - med) / scale


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


def _estimate_mean_ibi_sec(peak_indices, signal, fs):
    peak_indices = np.asarray(peak_indices, dtype=int)
    if len(peak_indices) < 2:
        return None

    heights = signal[peak_indices]
    tall_peaks = peak_indices[heights >= np.median(heights)]
    if len(tall_peaks) >= 2:
        return float(np.median(np.diff(tall_peaks)) / fs)
    return float(np.median(np.diff(peak_indices)) / fs)


def _merge_close_peaks(peak_indices, signal, fs):
    """
    Drop shorter peaks when two detections fall within one beat (e.g. dicrotic notch).
    Keeps the sample with the larger signal value.
    """
    if len(peak_indices) <= 1:
        return peak_indices

    peak_indices = np.sort(np.asarray(peak_indices, dtype=int))
    signal = np.asarray(signal)

    mean_ibi_sec = _estimate_mean_ibi_sec(peak_indices, signal, fs)
    if mean_ibi_sec is None:
        return peak_indices

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


def _filter_peaks_by_amplitude(peak_indices, signal, min_frac=PEAK_HEIGHT_MEDIAN_FRAC):
    if len(peak_indices) == 0:
        return peak_indices

    peak_indices = np.asarray(peak_indices, dtype=int)
    heights = signal[peak_indices]
    threshold = min_frac * float(np.median(heights))
    return peak_indices[heights >= threshold]


def _keep_tallest_in_beat_windows(peak_indices, signal, fs, mean_ibi_sec):
    """Keep only the tallest peak within each expected beat window."""
    if len(peak_indices) <= 1:
        return peak_indices

    peak_indices = np.sort(np.asarray(peak_indices, dtype=int))
    window_samples = max(1, int(0.85 * mean_ibi_sec * fs))

    kept = []
    window_start = int(peak_indices[0])
    best = int(peak_indices[0])
    for idx in peak_indices[1:]:
        idx = int(idx)
        if idx - window_start < window_samples:
            if signal[idx] > signal[best]:
                best = idx
        else:
            kept.append(best)
            window_start = idx
            best = idx
    kept.append(best)
    return np.array(kept, dtype=int)


def find_peaks(signal, fs):
    """Find systolic peaks; returns peak times in seconds (relative to stable signal start)."""
    signal = np.asarray(signal)
    distance = max(1, int(fs * PEAK_MIN_DISTANCE_SEC))
    peaks, _ = scipy_find_peaks(
        signal,
        distance=distance,
        prominence=MIN_PEAK_PROMINENCE,
    )
    peaks = _merge_close_peaks(peaks, signal, fs)
    peaks = _filter_peaks_by_amplitude(peaks, signal)
    if len(peaks) >= 2:
        mean_ibi_sec = _estimate_mean_ibi_sec(peaks, signal, fs)
        if mean_ibi_sec is not None:
            peaks = _keep_tallest_in_beat_windows(peaks, signal, fs, mean_ibi_sec)
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


def _outlier_fraction(signal):
    signal = np.asarray(signal)
    med = np.median(signal)
    scale = _robust_scale(signal)
    if scale <= 1e-8:
        return 0.0
    return float(np.mean(np.abs(signal - med) > OUTLIER_MAD_SCALE * scale))


def _beat_template_correlation(signal, fs):
    """Mean pairwise correlation of beat-shaped windows around detected peaks."""
    signal = np.asarray(signal)
    distance = max(1, int(fs * PEAK_MIN_DISTANCE_SEC))
    peaks, _ = scipy_find_peaks(signal, distance=distance, prominence=MIN_PEAK_PROMINENCE * 0.75)
    if len(peaks) < 2:
        return 0.0

    beat_window = max(3, int(0.7 * fs))
    beats = []
    half = beat_window // 2
    for peak in peaks:
        start = int(peak) - half
        end = int(peak) + half
        if start >= 0 and end <= len(signal):
            beats.append(signal[start:end])

    if len(beats) < 2:
        return 0.0

    ref = beats[0]
    correlations = []
    for beat in beats[1:]:
        if len(beat) != len(ref):
            continue
        corr = np.corrcoef(ref, beat)[0, 1]
        if np.isfinite(corr):
            correlations.append(float(corr))

    return float(np.mean(correlations)) if correlations else 0.0


def validate_signal_quality(signal, fs):
    """Morphology-based rejection before peak counting."""
    signal = np.asarray(signal)
    if len(signal) < int(fs * 2):
        return False, 'signal_too_short'

    if _outlier_fraction(signal) > MAX_OUTLIER_FRAC:
        return False, 'outlier_fraction'

    correlation = _beat_template_correlation(signal, fs)
    if correlation < BEAT_CORRELATION_THRESHOLD:
        return False, 'beat_correlation'

    return True, None


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


def validate_peaks_quality(peaks_sec, stable_duration_sec, signal=None, fs=None):
    """Reject artifact-heavy segments: beat count, HR, IBI regularity, peak amplitude."""
    peaks = sorted(float(p) for p in peaks_sec)
    if len(peaks) < 2:
        return False, 'too_few_peaks'

    ibis = np.diff(peaks)
    mean_ibi = float(np.mean(ibis))
    if mean_ibi <= 0:
        return False, 'invalid_ibi'

    hr_bpm = 60.0 / mean_ibi
    if hr_bpm < MIN_HR_BPM or hr_bpm > MAX_HR_BPM:
        return False, 'hr_out_of_range'

    cv = float(np.std(ibis) / mean_ibi)
    if cv > MAX_IBI_CV:
        return False, 'ibi_irregular'

    stable_duration_sec = float(stable_duration_sec)
    min_beats = max(3, int(stable_duration_sec * MIN_HR_BPM / 60 * 0.75))
    max_beats = int(stable_duration_sec * MAX_HR_BPM / 60 * MAX_BEAT_COUNT_FACTOR) + 1
    if len(peaks) < min_beats or len(peaks) > max_beats:
        return False, 'beat_count'

    if signal is not None and fs is not None and len(peaks) >= 3:
        signal = np.asarray(signal)
        indices = np.clip((np.array(peaks) * fs).astype(int), 0, len(signal) - 1)
        heights = signal[indices]
        amp_cv = float(np.std(heights) / (np.mean(heights) + 1e-8))
        if amp_cv > MAX_PEAK_AMPLITUDE_CV:
            return False, 'peak_amplitude_cv'

    return True, None


def build_fake_peaks(real_peaks, window_lo, window_hi):
    fake = []
    for p in real_peaks:
        jittered = round(p + random.uniform(-0.1, 0.1), 2)
        jittered = max(window_lo, min(jittered, window_hi))
        fake.append(jittered)
    return fake
