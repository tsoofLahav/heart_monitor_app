#!/usr/bin/env python3
"""
PPG app vs ECG monitor validation script - dynamic matching version.

Expected file pairs:
  <name>-<NN>-app.pdf
  <name>-<NN>-monitor.txt

Outputs:
  results/per_pair_results.csv
  results/overall_summary.csv
  results/visualizations/<pair_id>_full_24s.png
  results/visualizations/<pair_id>_bland_altman_dynamic.png
  results/visualizations/<pair_id>_dynamic_alignment.png

Method:
  1. Use file timestamps for rough window alignment.
  2. Extract app peaks and clean PPG signal from app PDF.
  3. Detect ECG R-peaks from monitor txt.
  4. Compare PP/RR intervals, not absolute peak times, to avoid ECG->PPG physiological lag.
  5. Use dynamic interval matching over the whole 24s window.
     - matched interval = ECG RR/HR interval paired to app PP/HR interval
     - skipped ECG interval = likely missed app beat / unmatched reference interval
     - skipped app interval = likely extra app interval / artifact
  6. Report:
     A. matched-interval accuracy: MAE, RMSE, bias, Bland-Altman LoA, within +/-5 bpm, correlation
     B. artifact/robustness: skipped intervals, artifact rate, sensitivity, PPV, F1
     C. penalized accuracy: skipped intervals are counted as large errors
"""

from __future__ import annotations

import argparse
import ast
import csv
import json
import math
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt, find_peaks

APP_WINDOW_START_SEC = 4.5
APP_WINDOW_END_SEC = 24.5
DEFAULT_MONITOR_UTC_OFFSET_HOURS = 3

ECG_BANDPASS_LOW_HZ = 5
ECG_BANDPASS_HIGH_HZ = 35
ECG_MIN_RR_SEC = 0.45
ECG_MIN_HEIGHT_Z = 0.8
ECG_MIN_PROMINENCE_Z = 1.0

DEFAULT_SKIP_PENALTY_BPM = 8.0
DEFAULT_SKIP_ERROR_BPM = 20.0

# Edge-offset sweep: tries dropping a few interval edges before matching.
# This handles cases where trimming starts/ends mid-cycle and one signal has a partial edge interval.
DEFAULT_MAX_DROP_START_INTERVALS = 2
DEFAULT_MAX_DROP_END_INTERVALS = 1

EDGE_SWEEP_ROWS: List[Dict[str, object]] = []


@dataclass
class AppData:
    start_utc: datetime
    fps: float
    peaks_sec: np.ndarray
    clean_signal: np.ndarray
    duration_sec: float


@dataclass
class MonitorData:
    start_utc: datetime
    fs: float
    signal: np.ndarray
    t_sec: np.ndarray


@dataclass
class Metrics:
    n: int
    bias_bpm: float
    mae_bpm: float
    rmse_bpm: float
    loa_low_bpm: float
    loa_high_bpm: float
    within_5_bpm_pct: float
    pearson_r: float


@dataclass
class DynamicMatchResult:
    ecg_matched_hr: np.ndarray
    app_matched_hr: np.ndarray
    ecg_matched_idx: List[int]
    app_matched_idx: List[int]
    skipped_ecg_idx: List[int]
    skipped_app_idx: List[int]
    total_cost: float


def run_pdftotext(pdf_path: Path) -> str:
    try:
        return subprocess.check_output(["pdftotext", str(pdf_path), "-"], text=True)
    except Exception:
        pass

    try:
        import PyPDF2
        with open(pdf_path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            return "\n".join(page.extract_text() or "" for page in reader.pages)
    except Exception as e:
        raise RuntimeError(
            f"Could not extract text from {pdf_path}. Install poppler/pdftotext or PyPDF2."
        ) from e


def extract_json_array(name: str, text: str) -> np.ndarray:
    m = re.search(rf'"{re.escape(name)}"\s*:\s*\[(.*?)\]', text, re.S)
    if not m:
        raise ValueError(f"Could not find JSON array '{name}' in app PDF text.")
    arr_text = "[" + m.group(1).replace("\f", "\n") + "]"
    return np.array(ast.literal_eval(arr_text), dtype=float)


def parse_app_pdf(path: Path) -> AppData:
    text = run_pdftotext(path)

    start_match = re.search(r"Started \(UTC\):\s*([^\n]+)", text)
    if not start_match:
        raise ValueError(f"Could not find app UTC start time in {path}")
    start_utc = datetime.fromisoformat(start_match.group(1).strip().replace("Z", "+00:00"))

    fps_match = re.search(r"FPS:\s*([0-9.]+)", text)
    fps = float(fps_match.group(1)) if fps_match else 23.96

    duration_match = re.search(r'"duration"\s*:\s*([0-9.]+)', text)
    duration = float(duration_match.group(1)) if duration_match else np.nan

    return AppData(
        start_utc=start_utc,
        fps=fps,
        peaks_sec=extract_json_array("real_peaks", text),
        clean_signal=extract_json_array("clean_signal", text),
        duration_sec=duration,
    )


def parse_monitor_txt(path: Path, monitor_utc_offset_hours: int) -> MonitorData:
    header = []
    rows = []
    in_data = False

    with open(path, "r", errors="ignore") as f:
        for line in f:
            if line.startswith("# EndOfHeader"):
                in_data = True
                continue
            if not in_data:
                header.append(line)
                continue
            if not line.strip() or line.startswith("#"):
                continue
            parts = line.strip().split()
            if len(parts) >= 3:
                try:
                    rows.append((int(parts[0]), float(parts[2])))
                except ValueError:
                    continue

    header_text = "".join(header)
    json_match = re.search(r"#\s*(\{.*\})", header_text, re.S)
    if not json_match:
        raise ValueError(f"Could not parse OpenSignals header in {path}")

    header_json = json.loads(json_match.group(1))
    device = next(iter(header_json.values()))

    fs = float(device.get("sampling rate", 200))
    y, mo, d = [int(x) for x in device["date"].split("-")]
    hh, mm, ss = device["time"].split(":")
    ss_float = float(ss)
    local_start = datetime(
        y, mo, d,
        int(hh), int(mm), int(ss_float),
        int(round((ss_float % 1) * 1_000_000)),
    )
    start_utc = local_start.replace(
        tzinfo=timezone(timedelta(hours=monitor_utc_offset_hours))
    ).astimezone(timezone.utc)

    data = np.array(rows, dtype=float)
    nseq = data[:, 0]
    signal = data[:, 1]
    return MonitorData(start_utc=start_utc, fs=fs, signal=signal, t_sec=nseq / fs)


def robust_norm(x: np.ndarray) -> np.ndarray:
    scale = np.percentile(x, 95) - np.percentile(x, 5)
    return (x - np.median(x)) / scale if scale != 0 else x - np.median(x)


def detect_ecg_r_peaks(t: np.ndarray, ecg: np.ndarray, fs: float) -> np.ndarray:
    ecg_centered = ecg - np.median(ecg)
    high = min(ECG_BANDPASS_HIGH_HZ, fs / 2 - 1)
    b, a = butter(
        2,
        [ECG_BANDPASS_LOW_HZ / (fs / 2), high / (fs / 2)],
        btype="bandpass",
    )
    filtered = filtfilt(b, a, ecg_centered)
    z = (filtered - np.mean(filtered)) / np.std(filtered)

    peak_idx, _ = find_peaks(
        z,
        distance=int(ECG_MIN_RR_SEC * fs),
        height=ECG_MIN_HEIGHT_Z,
        prominence=ECG_MIN_PROMINENCE_Z,
    )
    return t[peak_idx]


def interval_hr(peaks_sec: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    peaks_sec = np.asarray(peaks_sec, dtype=float)
    intervals = np.diff(peaks_sec)
    mids = (peaks_sec[:-1] + peaks_sec[1:]) / 2
    valid = intervals > 0
    return mids[valid], 60.0 / intervals[valid]


def dynamic_interval_match(
    ecg_hr: np.ndarray,
    app_hr: np.ndarray,
    skip_penalty_bpm: float = DEFAULT_SKIP_PENALTY_BPM,
) -> DynamicMatchResult:
    n, m = len(ecg_hr), len(app_hr)
    dp = np.full((n + 1, m + 1), np.inf)
    back = np.empty((n + 1, m + 1), dtype=object)
    dp[0, 0] = 0.0
    back[0, 0] = None

    for i in range(1, n + 1):
        dp[i, 0] = dp[i - 1, 0] + skip_penalty_bpm
        back[i, 0] = "skip_ecg"
    for j in range(1, m + 1):
        dp[0, j] = dp[0, j - 1] + skip_penalty_bpm
        back[0, j] = "skip_app"

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            match_cost = dp[i - 1, j - 1] + abs(float(app_hr[j - 1] - ecg_hr[i - 1]))
            skip_ecg_cost = dp[i - 1, j] + skip_penalty_bpm
            skip_app_cost = dp[i, j - 1] + skip_penalty_bpm
            best = min(match_cost, skip_ecg_cost, skip_app_cost)
            dp[i, j] = best
            if best == match_cost:
                back[i, j] = "match"
            elif best == skip_ecg_cost:
                back[i, j] = "skip_ecg"
            else:
                back[i, j] = "skip_app"

    matched_ecg_idx, matched_app_idx = [], []
    skipped_ecg_idx, skipped_app_idx = [], []
    i, j = n, m
    while i > 0 or j > 0:
        op = back[i, j]
        if op == "match":
            matched_ecg_idx.append(i - 1)
            matched_app_idx.append(j - 1)
            i -= 1
            j -= 1
        elif op == "skip_ecg":
            skipped_ecg_idx.append(i - 1)
            i -= 1
        elif op == "skip_app":
            skipped_app_idx.append(j - 1)
            j -= 1
        else:
            break

    matched_ecg_idx.reverse()
    matched_app_idx.reverse()
    skipped_ecg_idx.reverse()
    skipped_app_idx.reverse()

    return DynamicMatchResult(
        ecg_matched_hr=ecg_hr[matched_ecg_idx],
        app_matched_hr=app_hr[matched_app_idx],
        ecg_matched_idx=matched_ecg_idx,
        app_matched_idx=matched_app_idx,
        skipped_ecg_idx=skipped_ecg_idx,
        skipped_app_idx=skipped_app_idx,
        total_cost=float(dp[n, m]),
    )


def compute_metrics(ecg_hr: np.ndarray, app_hr: np.ndarray) -> Metrics:
    n = min(len(ecg_hr), len(app_hr))
    if n == 0:
        return Metrics(0, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan, np.nan)
    ecg_hr = ecg_hr[:n]
    app_hr = app_hr[:n]
    diff = app_hr - ecg_hr
    bias = float(np.mean(diff))
    mae = float(np.mean(np.abs(diff)))
    rmse = float(np.sqrt(np.mean(diff ** 2)))
    sd = float(np.std(diff, ddof=1)) if n > 1 else float("nan")
    loa_low = bias - 1.96 * sd
    loa_high = bias + 1.96 * sd
    within_5 = float(np.mean(np.abs(diff) <= 5) * 100)
    r = float(np.corrcoef(ecg_hr, app_hr)[0, 1]) if n > 1 and np.std(ecg_hr) > 1e-9 and np.std(app_hr) > 1e-9 else float("nan")
    return Metrics(n, bias, mae, rmse, loa_low, loa_high, within_5, r)


def compute_penalized_metrics(match: DynamicMatchResult, skip_error_bpm: float) -> Dict[str, float]:
    matched_errors = np.abs(match.app_matched_hr - match.ecg_matched_hr)
    n_skips = len(match.skipped_ecg_idx) + len(match.skipped_app_idx)
    errors = np.concatenate([matched_errors, np.full(n_skips, skip_error_bpm)]) if n_skips else matched_errors
    if len(errors) == 0:
        return {"penalized_n": 0, "penalized_mae_bpm": np.nan, "penalized_rmse_bpm": np.nan, "penalized_within_5_bpm_pct": np.nan}
    return {
        "penalized_n": int(len(errors)),
        "penalized_mae_bpm": float(np.mean(errors)),
        "penalized_rmse_bpm": float(np.sqrt(np.mean(errors ** 2))),
        "penalized_within_5_bpm_pct": float(np.mean(errors <= 5) * 100),
    }





def compute_penalized_metrics_with_extra_skips(
    match: DynamicMatchResult,
    skip_error_bpm: float,
    extra_skips: int,
) -> Dict[str, float]:
    matched_errors = np.abs(match.app_matched_hr - match.ecg_matched_hr)
    n_skips = len(match.skipped_ecg_idx) + len(match.skipped_app_idx) + int(extra_skips)
    errors = np.concatenate([matched_errors, np.full(n_skips, skip_error_bpm)]) if n_skips else matched_errors
    if len(errors) == 0:
        return {
            "penalized_n": 0,
            "penalized_mae_bpm": np.nan,
            "penalized_rmse_bpm": np.nan,
            "penalized_within_5_bpm_pct": np.nan,
        }
    return {
        "penalized_n": int(len(errors)),
        "penalized_mae_bpm": float(np.mean(errors)),
        "penalized_rmse_bpm": float(np.sqrt(np.mean(errors ** 2))),
        "penalized_within_5_bpm_pct": float(np.mean(errors <= 5) * 100),
    }


def edge_slice(x: np.ndarray, drop_start: int, drop_end: int) -> np.ndarray:
    """Drop intervals from start/end without failing on short arrays."""
    x = np.asarray(x)
    if drop_start < 0 or drop_end < 0:
        raise ValueError("drop_start/drop_end must be non-negative")
    end = len(x) - drop_end if drop_end else len(x)
    if drop_start >= end:
        return x[:0]
    return x[drop_start:end]


def candidate_quality_score(row: Dict[str, object]) -> float:
    """
    Quality only, not coverage. Higher is better.
    Used to filter candidate edge alignments before maximizing ECG coverage.
    """
    mae = float(row.get("matched_mae_bpm", float("nan")))
    within5 = float(row.get("matched_within_5_bpm_pct", float("nan")))
    r = float(row.get("matched_pearson_r", float("nan")))
    if math.isnan(mae):
        mae = 1e9
    if math.isnan(within5):
        within5 = 0.0
    # Correlation can be unstable when HR range is tiny, so use it lightly.
    r_bonus = 0.0 if math.isnan(r) else max(min(r, 1.0), -1.0) * 5.0
    return within5 - 10.0 * mae + r_bonus


def edge_selection_key(row: Dict[str, object]) -> Tuple[float, float, float, float]:
    """
    Select among above-average-quality candidates.
    Primary: ECG coverage. Tie-breakers: lower MAE, app coverage, lower penalized MAE.
    """
    ecg_cov = float(row.get("ecg_interval_coverage_pct", float("nan")))
    app_cov = float(row.get("app_interval_coverage_pct", float("nan")))
    mae = float(row.get("matched_mae_bpm", float("nan")))
    penalized_mae = float(row.get("penalized_mae_bpm", float("nan")))
    if math.isnan(ecg_cov):
        ecg_cov = -1e9
    if math.isnan(app_cov):
        app_cov = -1e9
    if math.isnan(mae):
        mae = 1e9
    if math.isnan(penalized_mae):
        penalized_mae = 1e9
    return (ecg_cov, -mae, app_cov, -penalized_mae)


def edge_offset_sweep_match(
    pair_id: str,
    ecg_interval_times: np.ndarray,
    ecg_hr: np.ndarray,
    app_interval_times: np.ndarray,
    app_hr: np.ndarray,
    skip_penalty_bpm: float,
    skip_error_bpm: float,
    max_drop_start_intervals: int = DEFAULT_MAX_DROP_START_INTERVALS,
    max_drop_end_intervals: int = DEFAULT_MAX_DROP_END_INTERVALS,
) -> Tuple[DynamicMatchResult, np.ndarray, np.ndarray, np.ndarray, np.ndarray, Dict[str, object], List[Dict[str, object]]]:
    """
    Try small edge drops before dynamic matching.

    This solves global edge-index ambiguity caused by starting/ending the analysis
    window inside a cardiac cycle. Selection is quality-aware:
      1. score each candidate by match quality only
      2. keep candidates >= this pair's average quality
      3. choose highest ECG coverage, then lowest MAE
    Coverage and penalized metrics are computed against the original interval counts,
    so dropped edge intervals are not hidden.
    """
    original_ecg_n = len(ecg_hr)
    original_app_n = len(app_hr)
    candidate_rows: List[Dict[str, object]] = []
    candidate_objects = []

    for drop_ecg_start in range(max_drop_start_intervals + 1):
        for drop_app_start in range(max_drop_start_intervals + 1):
            for drop_ecg_end in range(max_drop_end_intervals + 1):
                for drop_app_end in range(max_drop_end_intervals + 1):
                    ecg_hr_c = edge_slice(ecg_hr, drop_ecg_start, drop_ecg_end)
                    app_hr_c = edge_slice(app_hr, drop_app_start, drop_app_end)
                    ecg_t_c = edge_slice(ecg_interval_times, drop_ecg_start, drop_ecg_end)
                    app_t_c = edge_slice(app_interval_times, drop_app_start, drop_app_end)
                    if len(ecg_hr_c) == 0 or len(app_hr_c) == 0:
                        continue

                    match = dynamic_interval_match(ecg_hr_c, app_hr_c, skip_penalty_bpm)
                    metrics = compute_metrics(match.ecg_matched_hr, match.app_matched_hr)

                    dropped_ecg = drop_ecg_start + drop_ecg_end
                    dropped_app = drop_app_start + drop_app_end
                    extra_skips = dropped_ecg + dropped_app
                    penalized = compute_penalized_metrics_with_extra_skips(match, skip_error_bpm, extra_skips)

                    matched_n = len(match.ecg_matched_idx)
                    skipped_ecg = len(match.skipped_ecg_idx) + dropped_ecg
                    skipped_app = len(match.skipped_app_idx) + dropped_app
                    total_skipped = skipped_ecg + skipped_app
                    total_considered = original_ecg_n + original_app_n

                    row = {
                        "pair_id": pair_id,
                        "edge_drop_ecg_start": drop_ecg_start,
                        "edge_drop_app_start": drop_app_start,
                        "edge_drop_ecg_end": drop_ecg_end,
                        "edge_drop_app_end": drop_app_end,
                        "edge_dropped_ecg_intervals": dropped_ecg,
                        "edge_dropped_app_intervals": dropped_app,
                        "edge_cropped_ecg_intervals": len(ecg_hr_c),
                        "edge_cropped_app_intervals": len(app_hr_c),
                        "dynamic_matched_intervals": matched_n,
                        "dynamic_skipped_ecg_intervals": skipped_ecg,
                        "dynamic_skipped_app_intervals": skipped_app,
                        "dynamic_total_cost": match.total_cost,
                        "artifact_interval_rate_pct": total_skipped / total_considered * 100 if total_considered else np.nan,
                        "ecg_interval_coverage_pct": matched_n / original_ecg_n * 100 if original_ecg_n else np.nan,
                        "app_interval_coverage_pct": matched_n / original_app_n * 100 if original_app_n else np.nan,
                        "matched_bias_bpm": metrics.bias_bpm,
                        "matched_mae_bpm": metrics.mae_bpm,
                        "matched_rmse_bpm": metrics.rmse_bpm,
                        "matched_loa_low_bpm": metrics.loa_low_bpm,
                        "matched_loa_high_bpm": metrics.loa_high_bpm,
                        "matched_within_5_bpm_pct": metrics.within_5_bpm_pct,
                        "matched_pearson_r": metrics.pearson_r,
                        **penalized,
                    }
                    row["edge_quality_score"] = candidate_quality_score(row)
                    candidate_rows.append(row)
                    candidate_objects.append((row, match, ecg_t_c, ecg_hr_c, app_t_c, app_hr_c))

    if not candidate_objects:
        raise ValueError(f"No valid edge-offset candidates for {pair_id}")

    quality_vals = [float(r["edge_quality_score"]) for r in candidate_rows if not math.isnan(float(r["edge_quality_score"]))]
    avg_quality = float(np.mean(quality_vals)) if quality_vals else -1e9

    eligible = [obj for obj in candidate_objects if float(obj[0]["edge_quality_score"]) >= avg_quality]
    if not eligible:
        eligible = candidate_objects

    best_row, best_match, best_ecg_t, best_ecg_hr, best_app_t, best_app_hr = max(
        eligible,
        key=lambda obj: edge_selection_key(obj[0]),
    )

    for row in candidate_rows:
        row["edge_avg_quality_score_for_pair"] = avg_quality
        row["edge_above_avg_quality"] = float(row["edge_quality_score"]) >= avg_quality
        row["is_selected_edge_alignment"] = (
            row["edge_drop_ecg_start"] == best_row["edge_drop_ecg_start"] and
            row["edge_drop_app_start"] == best_row["edge_drop_app_start"] and
            row["edge_drop_ecg_end"] == best_row["edge_drop_ecg_end"] and
            row["edge_drop_app_end"] == best_row["edge_drop_app_end"]
        )

    selected_info = dict(best_row)
    selected_info["edge_selection_rule"] = "above_avg_quality_then_max_ecg_coverage_then_min_mae"

    return best_match, best_ecg_t, best_ecg_hr, best_app_t, best_app_hr, selected_info, candidate_rows


def extract_ecg_segment_with_padding(
    mon: MonitorData,
    ecg_abs_start: float,
    ecg_abs_end: float,
    pair_id: str,
    max_pad_sec: float = 0.75,
) -> Tuple[np.ndarray, np.ndarray, Dict[str, object]]:
    """
    Extract ECG segment for the requested absolute monitor-time window.

    If the requested window is only slightly outside the monitor recording,
    pad the missing edge with the closest available ECG value.

    If too much is missing, raise a detailed error.
    """
    target_duration = ecg_abs_end - ecg_abs_start
    target_len = int(round(target_duration * mon.fs))

    mon_start = float(mon.t_sec[0])
    mon_end = float(mon.t_sec[-1])

    overlap_start = max(ecg_abs_start, mon_start)
    overlap_end = min(ecg_abs_end, mon_end)

    if overlap_end <= overlap_start:
        raise ValueError(
            f"ECG segment too short for pair {pair_id}: no overlap. "
            f"requested={ecg_abs_start:.3f}-{ecg_abs_end:.3f}s, "
            f"monitor_available={mon_start:.3f}-{mon_end:.3f}s"
        )

    missing_start_sec = max(0.0, mon_start - ecg_abs_start)
    missing_end_sec = max(0.0, ecg_abs_end - mon_end)
    total_missing_sec = missing_start_sec + missing_end_sec

    if total_missing_sec > max_pad_sec:
        raise ValueError(
            f"ECG segment too short for pair {pair_id}: missing {total_missing_sec:.3f}s "
            f"(start {missing_start_sec:.3f}s, end {missing_end_sec:.3f}s). "
            f"requested={ecg_abs_start:.3f}-{ecg_abs_end:.3f}s, "
            f"monitor_available={mon_start:.3f}-{mon_end:.3f}s, "
            f"offset/window may be wrong."
        )

    mask = (mon.t_sec >= overlap_start) & (mon.t_sec <= overlap_end)
    segment = mon.signal[mask]

    if len(segment) == 0:
        raise ValueError(
            f"ECG segment too short for pair {pair_id}: overlap exists but no samples selected."
        )

    pad_start = int(round(missing_start_sec * mon.fs))
    pad_end = int(round(missing_end_sec * mon.fs))

    if pad_start or pad_end:
        segment = np.pad(segment, (pad_start, pad_end), mode="edge")

    # Force exact expected length for stable downstream plots/calculations.
    if len(segment) < target_len:
        segment = np.pad(segment, (0, target_len - len(segment)), mode="edge")
    elif len(segment) > target_len:
        segment = segment[:target_len]

    t = np.arange(len(segment)) / mon.fs

    info = {
        "ecg_requested_start_sec": ecg_abs_start,
        "ecg_requested_end_sec": ecg_abs_end,
        "ecg_monitor_available_start_sec": mon_start,
        "ecg_monitor_available_end_sec": mon_end,
        "ecg_missing_start_sec": missing_start_sec,
        "ecg_missing_end_sec": missing_end_sec,
        "ecg_padded_samples_start": pad_start,
        "ecg_padded_samples_end": pad_end,
        "ecg_segment_duration_sec": len(segment) / mon.fs,
    }
    return t, segment, info


def analyze_pair(pair_id: str, app_path: Path, monitor_path: Path, output_dir: Path, monitor_utc_offset_hours: int, skip_penalty_bpm: float, skip_error_bpm: float) -> Dict[str, object]:
    app = parse_app_pdf(app_path)
    mon = parse_monitor_txt(monitor_path, monitor_utc_offset_hours)
    offset_sec = (app.start_utc - mon.start_utc).total_seconds()

    app_start, app_end = APP_WINDOW_START_SEC, APP_WINDOW_END_SEC
    ecg_abs_start, ecg_abs_end = offset_sec + app_start, offset_sec + app_end
    ecg_t, ecg_signal, ecg_segment_info = extract_ecg_segment_with_padding(
        mon=mon,
        ecg_abs_start=ecg_abs_start,
        ecg_abs_end=ecg_abs_end,
        pair_id=pair_id,
        max_pad_sec=0.75,
    )
    if len(ecg_signal) < mon.fs * 5:
        raise ValueError(
            f"ECG segment too short for pair {pair_id}: only {len(ecg_signal) / mon.fs:.3f}s "
            f"after extraction. requested={ecg_abs_start:.3f}-{ecg_abs_end:.3f}s"
        )

    ecg_peaks = detect_ecg_r_peaks(ecg_t, ecg_signal, mon.fs)
    app_peaks = app.peaks_sec[(app.peaks_sec >= app_start) & (app.peaks_sec <= app_end)] - app_start

    t_app_all = np.arange(len(app.clean_signal)) / app.fps
    ppg_mask = (t_app_all >= app_start) & (t_app_all <= app_end)
    ppg_t = t_app_all[ppg_mask] - app_start
    ppg_signal = app.clean_signal[ppg_mask]

    ecg_interval_times, ecg_hr = interval_hr(ecg_peaks)
    app_interval_times, app_hr = interval_hr(app_peaks)

    (
        match,
        ecg_interval_times_for_match,
        ecg_hr_for_match,
        app_interval_times_for_match,
        app_hr_for_match,
        edge_info,
        edge_candidate_rows,
    ) = edge_offset_sweep_match(
        pair_id=pair_id,
        ecg_interval_times=ecg_interval_times,
        ecg_hr=ecg_hr,
        app_interval_times=app_interval_times,
        app_hr=app_hr,
        skip_penalty_bpm=skip_penalty_bpm,
        skip_error_bpm=skip_error_bpm,
        max_drop_start_intervals=DEFAULT_MAX_DROP_START_INTERVALS,
        max_drop_end_intervals=DEFAULT_MAX_DROP_END_INTERVALS,
    )
    EDGE_SWEEP_ROWS.extend(edge_candidate_rows)

    matched_metrics = compute_metrics(match.ecg_matched_hr, match.app_matched_hr)

    ecg_intervals_count = len(ecg_hr)
    app_intervals_count = len(app_hr)
    matched_interval_count = len(match.ecg_matched_idx)

    # Use selected edge-aware counts, where dropped edge intervals are still counted
    # as omitted reference/app intervals for fair coverage and penalized metrics.
    total_skipped = int(edge_info["dynamic_skipped_ecg_intervals"]) + int(edge_info["dynamic_skipped_app_intervals"])
    total_intervals_considered = ecg_intervals_count + app_intervals_count

    ecg_interval_coverage_pct = float(edge_info["ecg_interval_coverage_pct"])
    app_interval_coverage_pct = float(edge_info["app_interval_coverage_pct"])
    artifact_interval_rate_pct = float(edge_info["artifact_interval_rate_pct"])

    tp = matched_interval_count
    fn = int(edge_info["dynamic_skipped_ecg_intervals"])
    fp = int(edge_info["dynamic_skipped_app_intervals"])
    sensitivity = tp / (tp + fn) * 100 if (tp + fn) else np.nan
    ppv = tp / (tp + fp) * 100 if (tp + fp) else np.nan
    f1 = 2 * sensitivity * ppv / (sensitivity + ppv) if (sensitivity + ppv) else np.nan

    penalized = {
        "penalized_n": edge_info["penalized_n"],
        "penalized_mae_bpm": edge_info["penalized_mae_bpm"],
        "penalized_rmse_bpm": edge_info["penalized_rmse_bpm"],
        "penalized_within_5_bpm_pct": edge_info["penalized_within_5_bpm_pct"],
    }

    viz_dir = output_dir / "visualizations"
    viz_dir.mkdir(parents=True, exist_ok=True)
    save_signal_plot(viz_dir / f"{pair_id}_full_24s.png", pair_id, ecg_t, ecg_signal, ecg_peaks, ppg_t, ppg_signal, app_peaks)
    save_bland_altman_plot(viz_dir / f"{pair_id}_bland_altman_dynamic.png", pair_id, match.ecg_matched_hr, match.app_matched_hr, matched_metrics)
    save_alignment_plot(
        viz_dir / f"{pair_id}_dynamic_alignment.png",
        pair_id,
        ecg_interval_times_for_match,
        ecg_hr_for_match,
        app_interval_times_for_match,
        app_hr_for_match,
        match,
    )

    return {
        "pair_id": pair_id,
        "app_file": str(app_path),
        "monitor_file": str(monitor_path),
        "offset_sec_app_minus_monitor": offset_sec,
        **ecg_segment_info,
        "ecg_peaks_full": len(ecg_peaks),
        "app_peaks_full": len(app_peaks),
        "ecg_intervals_full": ecg_intervals_count,
        "app_intervals_full": app_intervals_count,
        "dynamic_matched_intervals": matched_interval_count,
        "dynamic_skipped_ecg_intervals": int(edge_info["dynamic_skipped_ecg_intervals"]),
        "dynamic_skipped_app_intervals": int(edge_info["dynamic_skipped_app_intervals"]),
        "dynamic_total_cost": match.total_cost,
        "edge_drop_ecg_start": edge_info["edge_drop_ecg_start"],
        "edge_drop_app_start": edge_info["edge_drop_app_start"],
        "edge_drop_ecg_end": edge_info["edge_drop_ecg_end"],
        "edge_drop_app_end": edge_info["edge_drop_app_end"],
        "edge_dropped_ecg_intervals": edge_info["edge_dropped_ecg_intervals"],
        "edge_dropped_app_intervals": edge_info["edge_dropped_app_intervals"],
        "edge_quality_score": edge_info["edge_quality_score"],
        "edge_selection_rule": edge_info["edge_selection_rule"],
        "artifact_interval_rate_pct": artifact_interval_rate_pct,
        "ecg_interval_coverage_pct": ecg_interval_coverage_pct,
        "app_interval_coverage_pct": app_interval_coverage_pct,
        "interval_sensitivity_pct": sensitivity,
        "interval_ppv_pct": ppv,
        "interval_f1_pct": f1,
        "matched_bias_bpm": matched_metrics.bias_bpm,
        "matched_mae_bpm": matched_metrics.mae_bpm,
        "matched_rmse_bpm": matched_metrics.rmse_bpm,
        "matched_loa_low_bpm": matched_metrics.loa_low_bpm,
        "matched_loa_high_bpm": matched_metrics.loa_high_bpm,
        "matched_within_5_bpm_pct": matched_metrics.within_5_bpm_pct,
        "matched_pearson_r": matched_metrics.pearson_r,
        **penalized,
        "skip_penalty_bpm": skip_penalty_bpm,
        "skip_error_bpm": skip_error_bpm,
    }


def save_signal_plot(path: Path, pair_id: str, ecg_t: np.ndarray, ecg_signal: np.ndarray, ecg_peaks: np.ndarray, ppg_t: np.ndarray, ppg_signal: np.ndarray, app_peaks: np.ndarray) -> None:
    ecg_plot = robust_norm(ecg_signal)
    ppg_plot = robust_norm(ppg_signal)
    ecg_peak_y = np.interp(ecg_peaks, ecg_t, ecg_plot)
    app_peak_y = np.interp(app_peaks, ppg_t, ppg_plot)
    plt.figure(figsize=(16, 7))
    plt.plot(ecg_t, ecg_plot + 2, linewidth=1, label="ECG monitor, normalized")
    plt.scatter(ecg_peaks, ecg_peak_y + 2, s=35, marker="o", label="Detected ECG R-peaks")
    plt.plot(ppg_t, ppg_plot - 2, linewidth=1, label="App PPG clean signal, normalized")
    plt.scatter(app_peaks, app_peak_y - 2, s=35, marker="x", label="App PPG peaks")
    plt.axvline(0, linestyle="--", linewidth=1)
    plt.axvline(24, linestyle="--", linewidth=1)
    plt.title(f"{pair_id}: full synchronized 24s ECG vs app PPG")
    plt.xlabel("Time in synchronized analysis window (seconds)")
    plt.yticks([2, -2], ["ECG", "App PPG"])
    plt.grid(True, axis="x", alpha=0.3)
    plt.legend(loc="upper right")
    plt.tight_layout()
    plt.savefig(path, dpi=200)
    plt.close()


def save_bland_altman_plot(path: Path, pair_id: str, ecg_hr: np.ndarray, app_hr: np.ndarray, metrics: Metrics) -> None:
    avg = (ecg_hr + app_hr) / 2
    diff = app_hr - ecg_hr
    plt.figure(figsize=(8, 6))
    plt.scatter(avg, diff, s=35)
    plt.axhline(metrics.bias_bpm, linestyle="-", linewidth=1, label=f"Bias {metrics.bias_bpm:.2f}")
    plt.axhline(metrics.loa_low_bpm, linestyle="--", linewidth=1, label=f"LoA low {metrics.loa_low_bpm:.2f}")
    plt.axhline(metrics.loa_high_bpm, linestyle="--", linewidth=1, label=f"LoA high {metrics.loa_high_bpm:.2f}")
    plt.title(f"{pair_id}: Bland-Altman matched dynamic HR intervals")
    plt.xlabel("Mean HR of ECG and app (bpm)")
    plt.ylabel("App HR - ECG HR (bpm)")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(path, dpi=200)
    plt.close()


def save_alignment_plot(path: Path, pair_id: str, ecg_times: np.ndarray, ecg_hr: np.ndarray, app_times: np.ndarray, app_hr: np.ndarray, match: DynamicMatchResult) -> None:
    plt.figure(figsize=(14, 6))
    plt.plot(ecg_times, ecg_hr, marker="o", linewidth=1, label="ECG RR-derived HR")
    plt.plot(app_times, app_hr, marker="x", linewidth=1, label="App PP-derived HR")
    for ei, ai in zip(match.ecg_matched_idx, match.app_matched_idx):
        plt.plot([ecg_times[ei], app_times[ai]], [ecg_hr[ei], app_hr[ai]], linewidth=0.7, alpha=0.35)
    if match.skipped_ecg_idx:
        plt.scatter(ecg_times[match.skipped_ecg_idx], ecg_hr[match.skipped_ecg_idx], s=90, facecolors="none", edgecolors="black", label="Skipped ECG intervals")
    if match.skipped_app_idx:
        plt.scatter(app_times[match.skipped_app_idx], app_hr[match.skipped_app_idx], s=90, facecolors="none", edgecolors="black", marker="s", label="Skipped app intervals")
    plt.title(f"{pair_id}: dynamic interval alignment")
    plt.xlabel("Time in synchronized analysis window (seconds)")
    plt.ylabel("Instantaneous HR from interval (bpm)")
    plt.grid(True, alpha=0.3)
    plt.legend()
    plt.tight_layout()
    plt.savefig(path, dpi=200)
    plt.close()


def find_pairs(input_dir: Path) -> List[Tuple[str, Path, Path]]:
    app_files, monitor_files = {}, {}
    for p in input_dir.iterdir():
        if not p.is_file():
            continue
        lower = p.name.lower()
        m_app = re.search(r"(.+)-app\.pdf$", lower)
        m_monitor = re.search(r"(.+)-monitor\.txt$", lower)
        if m_app:
            app_files[m_app.group(1)] = p
        elif m_monitor:
            monitor_files[m_monitor.group(1)] = p
    return [(pair_id, app_files[pair_id], monitor_files[pair_id]) for pair_id in sorted(app_files.keys() & monitor_files.keys())]


def write_csv(path: Path, rows: List[Dict[str, object]]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(rows[0].keys())
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def summarize(rows: List[Dict[str, object]]) -> Dict[str, object]:
    metric_keys = [
        "ecg_peaks_full", "app_peaks_full", "ecg_intervals_full", "app_intervals_full",
        "edge_drop_ecg_start", "edge_drop_app_start", "edge_drop_ecg_end", "edge_drop_app_end",
        "edge_dropped_ecg_intervals", "edge_dropped_app_intervals",
        "dynamic_matched_intervals", "dynamic_skipped_ecg_intervals", "dynamic_skipped_app_intervals",
        "artifact_interval_rate_pct", "ecg_interval_coverage_pct", "app_interval_coverage_pct",
        "interval_sensitivity_pct", "interval_ppv_pct", "interval_f1_pct",
        "matched_bias_bpm", "matched_mae_bpm", "matched_rmse_bpm",
        "matched_loa_low_bpm", "matched_loa_high_bpm", "matched_within_5_bpm_pct", "matched_pearson_r",
        "penalized_mae_bpm", "penalized_rmse_bpm", "penalized_within_5_bpm_pct",
    ]
    summary = {"n_pairs": len(rows)}
    for key in metric_keys:
        vals = []
        for r in rows:
            try:
                v = float(r[key])
                if not math.isnan(v):
                    vals.append(v)
            except Exception:
                pass
        vals = np.array(vals, dtype=float)
        summary[f"{key}_mean"] = float(np.mean(vals)) if len(vals) else float("nan")
        summary[f"{key}_sd"] = float(np.std(vals, ddof=1)) if len(vals) > 1 else (0.0 if len(vals) == 1 else float("nan"))
    return summary


def main() -> None:
    global DEFAULT_MAX_DROP_START_INTERVALS, DEFAULT_MAX_DROP_END_INTERVALS

    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=Path, help="Folder containing *-app.pdf and *-monitor.txt pairs")
    parser.add_argument("--output-dir", type=Path, default=Path("results"))
    parser.add_argument("--monitor-utc-offset-hours", type=int, default=DEFAULT_MONITOR_UTC_OFFSET_HOURS)
    parser.add_argument("--skip-penalty-bpm", type=float, default=DEFAULT_SKIP_PENALTY_BPM)
    parser.add_argument("--skip-error-bpm", type=float, default=DEFAULT_SKIP_ERROR_BPM)
    parser.add_argument("--max-drop-start-intervals", type=int, default=DEFAULT_MAX_DROP_START_INTERVALS)
    parser.add_argument("--max-drop-end-intervals", type=int, default=DEFAULT_MAX_DROP_END_INTERVALS)
    args = parser.parse_args()
    DEFAULT_MAX_DROP_START_INTERVALS = args.max_drop_start_intervals
    DEFAULT_MAX_DROP_END_INTERVALS = args.max_drop_end_intervals
    args.output_dir.mkdir(parents=True, exist_ok=True)

    pairs = find_pairs(args.input_dir)
    if not pairs:
        raise SystemExit("No pairs found. Expected names like '<name>-01-app.pdf' and '<name>-01-monitor.txt'.")

    rows = []
    for pair_id, app_path, monitor_path in pairs:
        print(f"Analyzing {pair_id}...")
        try:
            rows.append(analyze_pair(pair_id, app_path, monitor_path, args.output_dir, args.monitor_utc_offset_hours, args.skip_penalty_bpm, args.skip_error_bpm))
        except Exception as e:
            print(f"  ERROR in {pair_id}: {e}")

    write_csv(args.output_dir / "per_pair_results.csv", rows)
    write_csv(args.output_dir / "edge_sweep_results.csv", EDGE_SWEEP_ROWS)
    write_csv(args.output_dir / "overall_summary.csv", [summarize(rows)])
    print("\nDone.")
    print(f"Pairs analyzed: {len(rows)}")
    print(f"Per-pair results: {args.output_dir / 'per_pair_results.csv'}")
    print(f"Overall summary: {args.output_dir / 'overall_summary.csv'}")
    print(f"Edge sweep results: {args.output_dir / 'edge_sweep_results.csv'}")
    print(f"Visualizations: {args.output_dir / 'visualizations'}")


if __name__ == "__main__":
    main()
