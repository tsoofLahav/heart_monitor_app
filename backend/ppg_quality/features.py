"""Feature extraction for PPG quality inference."""

from __future__ import annotations

import numpy as np

TARGET_LEN = 300
TARGET_FS = 30.0


def resample_signal(signal: np.ndarray, target_len: int = TARGET_LEN) -> np.ndarray:
    signal = np.asarray(signal, dtype=float)
    if len(signal) == target_len:
        return signal
    if len(signal) < 2:
        return np.zeros(target_len, dtype=float)

    src_x = np.linspace(0.0, 1.0, len(signal))
    dst_x = np.linspace(0.0, 1.0, target_len)
    return np.interp(dst_x, src_x, signal).astype(float)


def peak_times_to_indices(peak_times_sec: list[float], target_len: int = TARGET_LEN) -> np.ndarray:
    indices = []
    for peak_sec in peak_times_sec:
        idx = int(round(float(peak_sec) * TARGET_FS))
        idx = int(np.clip(idx, 0, target_len - 1))
        indices.append(idx)
    return np.unique(np.asarray(indices, dtype=int))


def build_peak_mask(peak_times_sec: list[float], target_len: int = TARGET_LEN) -> np.ndarray:
    mask = np.zeros(target_len, dtype=np.float32)
    for idx in peak_times_to_indices(peak_times_sec, target_len):
        mask[idx] = 1.0
    return mask


def compute_rr_features(peak_times_sec: list[float]) -> np.ndarray:
    peaks = np.asarray(peak_times_sec, dtype=float)
    n_peaks = float(len(peaks))
    if len(peaks) < 2:
        return np.zeros(5, dtype=np.float32)

    rr = np.diff(peaks)
    mean_rr = float(np.mean(rr))
    mean_hr = float(60.0 / mean_rr) if mean_rr > 0 else 0.0
    rr_std = float(np.std(rr, ddof=0))
    rmssd = float(np.sqrt(np.mean(np.diff(rr) ** 2))) if len(rr) >= 2 else 0.0
    return np.array([n_peaks, mean_rr, mean_hr, rr_std, rmssd], dtype=np.float32)


def standardize_rr_features(
    rr_features: np.ndarray,
    mean: np.ndarray,
    std: np.ndarray,
) -> np.ndarray:
    return ((rr_features - mean) / std).astype(np.float32)
