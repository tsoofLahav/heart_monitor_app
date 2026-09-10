# Experiment

`ExperimentApi` sends participant, progress, profile, questionnaire, schedule, assessment and training-session requests to `/data/*` on the same host as video processing.

`ExperimentStore` is a ChangeNotifier with a SharedPreferences cache. The server is the source of truth; installation UUID comes from `PulseGuideProgressStore`. A failed refresh can return cached progress; saves return failure when the API fails.

`experiment_models.dart` decodes server progress including neutral `training_mode` (`ppg`/`audio`). `assessment_screen.dart` runs the same 12-step PRE/POST sequence for both arms. `assessment_models.dart` defines schedules, scoring and final relax vitals.

PRE/POST have five count trials, six rhythm matches and one relax recording. See `../../docs/protocol.md`. SQL migrations and API setup are documented in the backend's `docs/experiment-db.md`.
