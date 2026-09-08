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

`POST /process_video` accepts multipart `video` and optional `recording_started_at` UTC timestamp. Each request gets a unique temporary file, cleaned up in `finally`.

OpenCV extracts inverted red-channel intensity from a central circular region. Filtering uses a 0.8–3 Hz bandpass, removes the first 3 seconds, and normalizes the stable signal. Peak detection and numeric HR/HRV metrics are separate from quality classification. `session_timing.py` supplies video-relative and optional UTC peak-window metadata.

The PyTorch classifier evaluates 10-second windows (short recordings use one shorter window; the final full window may overlap). Any bad window makes the entire recording bad; good probability uses the minimum window probability, with a 0.5 threshold. Responses include `quality_label`, probabilities and per-window results. The frontend presents bad-reading feedback from this ML label.

The former disabled heuristic rejection code has been removed. Filtering, peak detection, ML input features, metric calculation and the response contract remain in place. `fake_peaks` remains in the response because the active client packages it. Invalid uploads and processing exceptions retain their existing error responses.

## Verification

```sh
python test_ppg_classifier.py
python -m unittest discover -s tests
```

The classifier smoke test requires the installed numerical/PyTorch dependencies and checkpoint. Route regression tests stub expensive processing and SQL imports so they need Flask but no live database, camera or ML model. Frontend quality decisions are covered by Flutter tests in the companion project.

SQL migration order and API fields: [experiment database](docs/experiment-db.md). Potential future deployment work: [scaling notes](docs/future-scaling.md).
