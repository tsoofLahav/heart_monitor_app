# Frontend source map

Use `package:heart_feedback/<module>/...` imports. Entry point: `main.dart`.

- `shell/`: app/locale/audio setup, welcome, preparation entry, profile, leave confirmation, QA controls, shared styling.
- `prep/`: mandatory-preparation state, before/after questionnaires, profile storage, scheduling and reminders.
- `calibration/`: camera identification, illustrated pulse instructions, practice and completion storage.
- `recording/`: shared camera lifecycle, finger-placement gate, upload and response packaging. Active modes are tutorial practice and protocol/assessment recording.
- `experiment/`: participant bootstrap, HTTP API, cached server progress, PRE/POST assessment models and screens.
- `game/`: forest trail, count scoring, score reveal, shared signal chart.
- `protocols/`: PPG and audio training, guessing, HR slider, summaries, beep generation and ECG rendering.
- `l10n/`: English/Hebrew ARB sources and generated localization classes. Regenerate with `flutter gen-l10n` after editing ARB files.

Navigation starts in `shell/app.dart`; `shell/selection_screen.dart` embeds `ForestTrailHome` after preparation. The trail launches assessments or the server-selected training mode and saves completion through `ExperimentStore`.

Recording returns data to its caller. Training and assessments interpret ML quality and retry; calibration interprets ML quality to guide practice. Preserve the shared chart, QA controls, and audio branch: each has active callers.

See [protocol](../docs/protocol.md) for timing and scoring.
