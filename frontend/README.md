# Monitor frontend

Flutter mobile app for heartbeat perception training, with English and Hebrew localization. The companion API lives in `../backend`.

## Run and verify

Use the Flutter SDK compatible with `pubspec.yaml` and the committed lockfile:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Camera/flash capture, audio, sound-state checks, and local notifications need device verification. Unit tests do not establish on-device behavior. iOS also requires Xcode and CocoaPods.

## Current application

`lib/main.dart` initializes locale, reminders, and audio, then launches `shell/app.dart`. Language selection and welcome lead to the preparation screen and forest trail.

Preparation requires profile, before questionnaire, camera identification, and successful pulse practice. Reminder scheduling is available from the bottom menu; it is not one of the four mandatory preparation steps.

The trail has ten steps: PRE assessment, eight training sessions, POST assessment. During external QA, Profile selects Regular (PPG) or Control (audio) training; new installations default to Regular. Both groups use the same assessments. Progress is fetched/saved through `/data/*`; local preferences cache progress and preparation settings.

Set `--dart-define=BACKEND_URL=https://your-backend-host` when running or building. Both video uploads and experiment requests use that host. Startup/resume warms the backend. Use a device-accessible HTTPS endpoint for phone testing.

QA skip menus and training-mode overrides are active in debug builds or with `--dart-define=QA_SKIP=true`; these are reachable development controls.

See [module map](lib/README.md), [study protocol](docs/protocol.md), and the backend's `docs/experiment-db.md` for persistence setup.

For private Android APK builds, signing, and the device checklist, see [Android preparation](docs/android-preparation.md).
