# Experiment database (Azure SQL)

The Flutter app never talks to SQL directly. All participant / trial / assessment /
session reads and writes go through HTTPS routes under `/data/*` on this App Service.

## Schema

Your live DB already has `Participants`, `Trials`, `Assessments`, `Sessions`.

**Required one-time fix** if bootstrap logs `Invalid column name 'ClientInstallId'`:
run [`sql/002_add_client_install_id.sql`](../sql/002_add_client_install_id.sql) in Azure Query editor.

Fresh databases can instead run [`sql/001_experiment_schema.sql`](../sql/001_experiment_schema.sql).

`Participants` must include **`ClientInstallId`** (unique) — the app identity key.

`Participants.Condition` (`real` | `control`) is assigned only on the server and
**must never** be returned to the client.

Compatible live nuances (no code change needed):
- `Sessions.DurationSeconds` as `int` is fine
- `Assessments.Phase` as `nvarchar(10)` is fine

## App Service configuration

Set one of:

1. **Preferred:** `AZURE_SQL_CONNECTION_STRING`  
   Example ODBC string:

   ```
   Driver={ODBC Driver 18 for SQL Server};Server=tcp:YOUR_SERVER.database.windows.net,1433;Database=YOUR_DB;Uid=YOUR_USER;Pwd=YOUR_PASSWORD;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;
   ```

2. Or discrete vars: `SQL_SERVER`, `SQL_DATABASE`, `SQL_USER`, `SQL_PASSWORD`  
   Optional: `SQL_DRIVER` (default `ODBC Driver 18 for SQL Server`).

The App Service Python runtime must have **ODBC Driver 18 for SQL Server** installed
(or use a custom startup / container that includes it). `pyodbc` is listed in
`requirements.txt`.

## API

| Method | Path | Body / query |
|--------|------|----------------|
| POST | `/data/bootstrap` | `{ "client_install_id": "<uuid>" }` |
| GET | `/data/progress?client_install_id=<uuid>` | — |
| POST | `/data/assessments` | `{ client_install_id, trial_id, phase, heartbeat_score?, questionnaire_score? }` |
| POST | `/data/sessions` | `{ client_install_id, trial_id, session_number, score, ... }` |
| PATCH | `/data/participants/me` | `{ client_install_id, name?, age? }` |

Progress JSON never includes `condition`. It includes neutral `training_mode`:

- `"ppg"` when Condition is `real` (finger PPG training sessions)
- `"audio"` when Condition is `control` (external beep-counting sessions)

Prep, PRE, and POST are identical for both arms; only training sessions (trail 2–9) differ.

Trail steps: `1` = PRE, `2–9` = sessions 1–8, `10` = POST.
