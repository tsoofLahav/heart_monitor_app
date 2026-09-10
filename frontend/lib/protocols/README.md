# Training protocols

The forest trail selects `ProtocolFlowScreen` for PPG training or `ControlProtocolFlowScreen` for audio training. Both contain two rounds of measurement/listening, guessed count and confidence, HR slider, round feedback, and final score.

PPG recording draws 20–40 stable seconds independently per round and adds 3 seconds for backend trimming. Bad ML readings show the retry note without choosing a new duration. Audio control uses `control_beep_sequence.dart` and `control_listen_screen.dart`.

`protocol_models.dart` supplies timing, slider mapping, quality interpretation and 50/50 count/HR scoring. `ecg/` renders and schedules the slider's rhythm. Shared screens also support assessments.

QA skip controls remain reachable in debug/explicit-QA builds. The removed standalone quick-test menu is not an application entry point.

Tests: protocol models, control beep sequence, rhythm scheduler, count scores. Full specification: `../../docs/protocol.md`.
