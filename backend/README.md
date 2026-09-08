# Monitor backend

Flask API paired with `../monitor_frontend_current`. Two active areas share one app:

- Video processing: `video_route.py` → `video_edit.py` → `filter_and_peaks.py` → `ppg_quality/classifier.py`.
- Experiment persistence: `experiment_routes.py` → `experiment_service.py` → `db.py` → Azure SQL.

`server.py` registers `/process_video`, `/data/*`, and health endpoints `/` and `/health`. Deployment can keep using `server:app`.

## Run

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python server.py
```

The development server listens on port 5000 unless `PORT` is set. SQL routes require connection environment variables and ODBC Driver 18; see [database setup](docs/experiment-db.md). The model checkpoint must remain at `models/ppg_quality_both.pt`.

## Video pipeline and quality

`POST /process_video` accepts multipart `video` and optional `recording_started_at` UTC timestamp. Updated clients also send `counting_start_sec` and `counting_end_sec`, the monotonic cue offsets relative to camera-start acknowledgement. Both are required together and must form a finite interval within the usable video; invalid intervals return HTTP 400. Without cue fields the legacy 3-second-start / 0.5-second-end peak window remains. Each request gets a unique temporary file, cleaned up in `finally`.

OpenCV extracts inverted red-channel intensity from a central circular region. Filtering uses a 0.8–3 Hz bandpass, removes the first 3 seconds, and normalizes the stable signal. Peak detection and numeric HR/HRV metrics are separate from quality classification. `session_timing.py` supplies video-relative and optional UTC peak-window metadata.

The PyTorch classifier evaluates 10-second windows (short recordings use one shorter window; the final full window may overlap). Recordings with 1–3 windows allow zero bad windows, 4–5 allow one, and 6+ allow two. The last overlapping window counts as a part. Individual windows still use a 0.5 threshold. Aggregate good probability remains the minimum window probability; acceptance uses `quality_label`, so an accepted recording may have a low worst-window probability. Tolerated windows and their beats are retained. Responses include `quality_label`, probabilities, per-window results, `quality_bad_windows` and `quality_allowed_bad_windows`. For cue-aware clients, peaks and ML inputs use the cue interval; `quality.duration_sec` is its duration. The returned signal keeps its original trimmed-video timeline; `quality_window_origin_sec` locates ML window zero on the video timeline. The frontend presents bad-reading feedback from this ML label.

The former disabled heuristic rejection code has been removed. Filtering, peak detection, ML input features, metric calculation and the response contract remain in place. `fake_peaks` remains in the response because the active client packages it. Invalid uploads and processing exceptions retain their existing error responses.

## Verification

```sh
python test_ppg_classifier.py
python -m unittest discover -s tests
```

The classifier smoke test requires the installed numerical/PyTorch dependencies and checkpoint. The unit suite requires Flask, NumPy, SciPy and PyTorch, but no live database, camera or model inference. It covers acceptance boundaries, cue metadata validation and route behavior with stubbed processing. Frontend quality decisions are covered by Flutter tests in the companion project.

SQL migration order and API fields: [experiment database](docs/experiment-db.md). Potential future deployment work: [scaling notes](docs/future-scaling.md).

## Cue alignment rollout

Deploy the backend before distributing the updated app. The app refuses to score a response that does not acknowledge its cue interval. Capture starts, warms up for 3 seconds, plays the start cue, waits the requested count duration, plays the end cue, and records 1 additional second. Cue offsets measure audio command requests on a monotonic clock after camera-start acknowledgement; native camera-start and audible-output latency still require physical-device validation. This is not sample-accurate hardware synchronization.
