# Preparation and reminders

The four mandatory steps are profile, before appreciation questionnaire, camera identification, and successful pulse practice. `PrepProgressStore` combines local flags and pulse-guide completion; `SelectionScreen` unlocks the trail when all four are done.

`profile_store.dart` manages local profile information; server writes use `ExperimentStore`. `appreciation_questionnaire_screen.dart` supports before/after phases and saves answers through `/data/appreciations`.

`session_timing_screen.dart` and `session_reminder_service.dart` manage scheduled sessions and local notifications in Asia/Jerusalem time. Scheduling is accessible separately from mandatory preparation. The API stores UTC plus local wall time through `/data/session-schedule`.
