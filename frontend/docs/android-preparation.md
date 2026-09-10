# Android preparation and private builds

Android uses the shared Flutter flows and backend. Package: `com.tsooflahav.heartfeedback` (based on the existing iOS identity, lowercase Android naming); display name: Monitor. Version comes from pubspec.yaml. The current Flutter SDK sets Android 7.0/API 24 as the minimum and API 36 as the target. No Google Play account is needed for a private APK.

## Build

Install Flutter and an Android SDK with the SDK/platform/build tools required by Flutter. Use JDK 17 for the current Gradle wrapper and Kotlin 2.1.0. Existing plugins compile against API 31, 34, 35, and Flutter's API 36, so install those platform packages as well as build tools 34.0.0/36.0.0. Flutter currently selects NDK 28.2.13676358. Set `ANDROID_HOME` to your installed Android SDK directory.

```sh
export ANDROID_HOME="$HOME/Library/Android/sdk" # typical macOS location
export JAVA_HOME="$(/usr/libexec/java_home -v 17)" # macOS
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug --target-platform android-arm64
flutter build apk --release --dart-define=BACKEND_URL=https://YOUR_BACKEND_HOST
```

Output: `build/app/outputs/flutter-apk/app-release.apk` (universal release). The debug command above builds for ARM64 phones; omit `--target-platform` if other architectures are needed and sufficient disk space is available. Release uses the ordinary app flow, including the QA group selector in Profile. Do not enable internal debug shortcuts when distributing to external testers.

## Signing and updates

Run `python3 tool/setup_android_signing.py` once on the signing machine. Signing files from the working app are not included in this repository. It creates `android/private-release.jks` and `android/key.properties` with restrictive file permissions. Both are ignored by Git. The script refuses to replace existing signing files; release signing never falls back to a debug key.

Back up both files securely before distributing the first APK. Keep the package ID and signing key for subsequent updates and increase the build number. Changing either identity or signing key requires a separate installation, which can affect locally saved data. APK sideloading requires the tester to allow installation from their chosen file/browser app. Store publishing and Play signing enrollment remain separate work.

## Code preparation

- Internet permission is in the release manifest. Camera/flash hardware is required. The camera plugin supplies camera permission; controllers keep `enableAudio: false`. Unused microphone and shared-storage permissions from plugins are removed during manifest merging. Files remain in app-private storage.
- Notifications have Java library desugaring, a retained monochrome small icon, notification/boot permissions, and reboot receivers. Reminders use `inexactAllowWhileIdle`; no exact-alarm permission is requested. Android may delay delivery during power-saving modes.
- Audio uses Android media usage, matching the music-volume stream checked by SoundGuard. Android side buttons are explicitly assigned to that stream even while the app is idle. Existing transient audio focus and iOS audio settings are preserved.
- Finger detection respects both row and chroma pixel strides for Android YUV420 frames. Detection thresholds and backend signal processing are unchanged.
- Camera screens release cameras when interrupted, hidden, or paused and reopen on resume. An interrupted capture is discarded rather than uploaded as a complete reading. An inactive transition during initial permission setup (before a camera is initialized) does not trigger this reset.
- Camera initialization errors expose a retry action; missing-finger detection still runs without a retry button. Assessment recording Back now asks for session-exit confirmation, matching its other steps. Training already confirms cancellation in the parent flow.
- Shared text sizes, keyboard behavior, Hebrew RTL, and safe-area components are retained.

## Physical-device verification before distribution

Use at least two Android camera families if available (for example Samsung and Pixel), plus an iPhone regression check:

1. Fresh installation: camera allowed/denied/retried, notifications allowed/denied, no microphone prompt for silent recording.
2. Identify the main rear lens; verify flash, finger readjustment, and quality practice.
3. Complete assessment and real/control sessions in Hebrew and English; compare audible beeps with the captured counting interval.
4. Change media volume, silent/vibrate and Do Not Disturb; test speaker/Bluetooth routing and ensure instructions can actually be heard.
5. Background/lock the phone during finger detection, recording, and upload; verify recovery, no late beeps or scoring of interrupted captures.
6. Check notification delivery after reboot and battery-saving mode, and installed-APK updates preserving progress.
7. Check Android Back, keyboard Next/Done, Hebrew layout, large text, gesture navigation and three-button navigation.

A passing build does not establish physical camera accuracy, audio-output latency, or reminder delivery on a particular phone.

## Verification on 2026-09-09

- Full Flutter suite: 67 tests passed, including Android chroma-stride and camera permission/resume regression coverage. Focused camera and cue-timing tests also passed after final interruption guards.
- Analyzer: no errors or warnings; 48 existing informational lint notes.
- Unsigned iOS debug build succeeded. Its generated output was subsequently removed to recover disk space.
- Universal Android release APK built; signature verified. Packaged manifest has Internet, camera, notification, reboot, and vibration permissions, without microphone, shared-storage, or exact-alarm permission. Package ID, API 24 minimum, API 36 target, and the media-volume button handler were verified in the APK.
- Physical-device testing remains pending. Private signing files are ignored by Git and must be backed up before APK distribution.

The debug APK build (including an ARM64-only retry) was blocked by insufficient disk space on this Mac. The signed universal release APK is available for phone testing. Generated failed build intermediates were removed; free additional disk space before retrying debug builds.
