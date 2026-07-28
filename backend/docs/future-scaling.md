# Future scaling notes (monitor backend)

Notes for when traffic grows beyond a small TestFlight group. Not required for current single-worker Azure deployment.

## Concurrent `/process_video` requests

**Done (TestFlight):** each upload uses a unique temp file (`tempfile.NamedTemporaryFile`) so concurrent requests no longer overwrite `./temp_video.mp4`.

**Later, at higher load:**

- **Multiple Gunicorn/uWSGI workers** — each worker is a separate process with its own memory; temp files are already per-request. Scale horizontally by increasing worker count on Azure App Service.
- **Request queue** — if CPU-bound processing (OpenCV + PyTorch) saturates the instance, add a short queue (Redis + worker, or Azure Queue) so bursts do not time out.
- **PyTorch inference under threads** — the shared model cache is read-only; if you ever run threaded concurrency inside one worker, prefer one inference at a time per process (lock) or use multiple processes instead of many threads.

## Saved data and History

**Auth is only needed when persisting or reading user-specific data** (e.g. `/data/get_sessions`). Stateless `/process_video` does not require auth.

When adding History or session storage:

- Issue a stable user or device identity (Sign in with Apple, anonymous UUID on first launch).
- Scope all DB reads/writes by that ID.
- Do not expose global session lists without authentication.

## Deployment / performance (optional)

- Export the quality model to **ONNX** for faster/lighter inference if PyTorch cold start or memory becomes an issue.
- Set explicit **request timeouts** and **max upload size** on the App Service / reverse proxy.
- Monitor **503/504** and p95 latency; scale up the App Service plan before adding complexity.
