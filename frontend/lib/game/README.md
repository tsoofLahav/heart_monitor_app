# Game and progress

`forest_trail_screen.dart` renders the ten-step journey and orchestrates server progress: PRE, sessions 1–8, POST. It launches `AssessmentScreen`, `ProtocolFlowScreen`, or `ControlProtocolFlowScreen`; QA overrides can change the effective training mode in QA builds. Session results are saved through `ExperimentStore` before advancing server progress.

`session_score.dart` contains the shared count/confidence calculation. `score_reveal_screen.dart` presents scores. `signal_chart_painter.dart` is used by calibration practice. `trail_unlock_store.dart` supports local trail state.

Tests cover count scoring, protocol models, and assessment models. See `../experiment/README.md` for persistence and `../../docs/protocol.md` for the protocol.
