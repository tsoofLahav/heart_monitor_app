# Future scaling notes (monitor backend)

Notes for when traffic grows beyond a small TestFlight group. Not required for current single-worker Azure deployment.

## Concurrent `/process_video` requests

**Done (TestFlight):** each upload uses a unique temp file (`tempfile.NamedTemporaryFile`) so concurrent requests no longer overwrite `./temp_video.mp4`.

**Later, at higher load:**

- **Multiple Gunicorn/uWSGI workers** — each worker is a separate process with its own memory; temp files are already per-request. Scale horizontally by increasing worker count on Azure App Service.
- **Request queue** — if CPU-bound processing (OpenCV + PyTorch) saturates the instance, add a short queue (Redis + worker, or Azure Queue) so bursts do not time out.
- **PyTorch inference under threads** — the shared model cache is read-only; if you ever run threaded concurrency inside one worker, prefer one inference at a time per process (lock) or use multiple processes instead of many threads.

## Experiment data

Experiment persistence already exists under `/data/*`, scoped by installation UUID and trial ownership checks. There is no active History page or `/data/get_sessions` route. See [experiment database](experiment-db.md) for the implemented routes and migrations.

Account-based authentication and cross-device identity would be separate future work; the current installation UUID is not an account login.

## Deployment / performance (optional)

- Export the quality model to **ONNX** for faster/lighter inference if PyTorch cold start or memory becomes an issue.
- Set explicit **request timeouts** and **max upload size** on the App Service / reverse proxy.
- Monitor **503/504** and p95 latency; scale up the App Service plan before adding complexity.
