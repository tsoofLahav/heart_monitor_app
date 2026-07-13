#!/usr/bin/env python3
"""Smoke tests for PPG quality windowing and classifier."""

import numpy as np

from ppg_quality.classifier import classify_signal_windows, quality_windows


def test_window_boundaries():
    assert quality_windows(10.0) == [(0.0, 10.0)]
    assert quality_windows(8.0) == [(0.0, 8.0)]
    assert quality_windows(18.0) == [(0.0, 10.0), (8.0, 18.0)]
    assert quality_windows(28.0) == [(0.0, 10.0), (10.0, 20.0), (18.0, 28.0)]
    print("window boundaries OK")


def test_classifier_runs():
    fs = 30.0
    duration = 10.0
    n = int(duration * fs)
    t = np.linspace(0, duration, n, endpoint=False)
    signal = np.sin(2 * np.pi * 1.2 * t)
    peaks = [float(i) for i in range(1, int(duration * 1.2))]

    result = classify_signal_windows(signal, peaks, fs, duration)
    assert result["quality_label"] in ("good", "bad")
    assert "quality_windows" in result
    assert len(result["quality_windows"]) == 1
    print("classifier OK:", result["quality_label"], result["quality_prob_good"])


if __name__ == "__main__":
    test_window_boundaries()
    test_classifier_runs()
    print("All smoke tests passed.")
