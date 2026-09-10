# Calibration

Active entry functions in `pulse_guide_navigation.dart`:

- `openCameraIdentify`: camera selection for preparation and the bottom menu.
- `openQualityCheckFlow`: illustrated instructions followed by practice.
- `openPulseGuideComics`: instruction images and final collage from the bottom menu.

`pulse_reading_tutorial_screen.dart` launches `LearnPracticeRecordingScreen`, checks ML `quality_label`, displays feedback/signal charts, and stores completion through `pulse_guide_progress_store.dart`. Camera preference and device install identity also live in that store.

`pulse_guide_assets.dart` and `pulse_guide_step_image.dart` supply shared instructions. The chart in `game/signal_chart_painter.dart` remains shared with tutorial practice.
