"""Windowed PPG quality classification for backend inference."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import torch

from ppg_quality.features import (
    TARGET_LEN,
    build_peak_mask,
    compute_rr_features,
    resample_signal,
    standardize_rr_features,
)
from ppg_quality.model import TwoBranchCNN

WINDOW_SEC = 10.0
MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "ppg_quality_both.pt"
THRESHOLD = 0.5

_model_bundle: dict | None = None


def quality_windows(duration_sec: float, window_sec: float = WINDOW_SEC) -> list[tuple[float, float]]:
    """Return (start_sec, end_sec) windows covering the stable signal."""
    duration_sec = float(duration_sec)
    if duration_sec <= window_sec:
        return [(0.0, duration_sec)]

    windows: list[tuple[float, float]] = [(0.0, window_sec)]
    start = window_sec
    while start + window_sec < duration_sec:
        windows.append((start, start + window_sec))
        start += window_sec

    last_start = duration_sec - window_sec
    if last_start > windows[-1][0]:
        windows.append((last_start, duration_sec))

    return windows


def _load_model_bundle() -> dict:
    global _model_bundle
    if _model_bundle is not None:
        return _model_bundle

    if not MODEL_PATH.is_file():
        raise FileNotFoundError(f"PPG quality model not found: {MODEL_PATH}")

    checkpoint = torch.load(MODEL_PATH, map_location="cpu", weights_only=False)
    mode = checkpoint.get("config", {}).get("mode", "both")
    model = TwoBranchCNN(mode=mode)
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()

    _model_bundle = {
        "model": model,
        "rr_mean": np.asarray(checkpoint["rr_mean"], dtype=np.float32),
        "rr_std": np.asarray(checkpoint["rr_std"], dtype=np.float32),
        "mode": mode,
    }
    return _model_bundle


def _slice_window(
    signal: np.ndarray,
    peaks_local: list[float],
    fs: float,
    start_sec: float,
    end_sec: float,
) -> tuple[np.ndarray, list[float]]:
    signal = np.asarray(signal, dtype=float)
    start_idx = int(round(start_sec * fs))
    end_idx = int(round(end_sec * fs))
    start_idx = max(0, min(start_idx, len(signal)))
    end_idx = max(start_idx, min(end_idx, len(signal)))

    window_signal = signal[start_idx:end_idx]
    window_peaks = [
        float(p - start_sec)
        for p in peaks_local
        if start_sec <= float(p) < end_sec
    ]
    return window_signal, window_peaks


def _predict_window(
    window_signal: np.ndarray,
    window_peaks: list[float],
    bundle: dict,
) -> tuple[str, float]:
    waveform = resample_signal(window_signal, TARGET_LEN).astype(np.float32)
    peak_mask = build_peak_mask(window_peaks, TARGET_LEN)
    rr_raw = compute_rr_features(window_peaks)
    rr = standardize_rr_features(rr_raw, bundle["rr_mean"], bundle["rr_std"])

    model = bundle["model"]
    with torch.no_grad():
        logit = model(
            torch.from_numpy(waveform).unsqueeze(0).unsqueeze(0),
            torch.from_numpy(peak_mask).unsqueeze(0).unsqueeze(0),
            torch.from_numpy(rr).unsqueeze(0),
        )
        prob_good = float(torch.sigmoid(logit).item())

    label = "good" if prob_good >= THRESHOLD else "bad"
    return label, prob_good


def classify_signal_windows(
    signal: np.ndarray,
    peaks_local: list[float],
    fs: float,
    duration_sec: float,
) -> dict:
    """
    Classify stable PPG signal in 10-second windows.

    Overall label is bad if ANY window is bad (conservative).
    """
    bundle = _load_model_bundle()
    windows = quality_windows(duration_sec)

    window_results = []
    min_prob_good = 1.0

    for start_sec, end_sec in windows:
        window_signal, window_peaks = _slice_window(
            signal, peaks_local, fs, start_sec, end_sec
        )
        label, prob_good = _predict_window(window_signal, window_peaks, bundle)
        min_prob_good = min(min_prob_good, prob_good)
        window_results.append(
            {
                "start_sec": round(start_sec, 3),
                "end_sec": round(end_sec, 3),
                "label": label,
                "prob_good": round(prob_good, 4),
                "prob_bad": round(1.0 - prob_good, 4),
                "peaks_count": len(window_peaks),
            }
        )

    any_bad = any(w["label"] == "bad" for w in window_results)
    overall_prob_good = min_prob_good if window_results else 0.0

    return {
        "quality_label": "bad" if any_bad else "good",
        "quality_prob_good": round(overall_prob_good, 4),
        "quality_prob_bad": round(1.0 - overall_prob_good, 4),
        "quality_windows": window_results,
    }
