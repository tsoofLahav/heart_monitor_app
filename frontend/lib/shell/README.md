# Shell

`app.dart` configures theme, localization, backend warmup, and the sound guard. `main.dart` performs initialization before launching it. Language onboarding leads to welcome, then `selection_screen.dart`.

Selection presents the four mandatory preparation steps and embeds the forest trail after completion. Its bottom menu opens profile, camera identification, pulse instruction comics, and reminders. `profile_screen.dart` and locale controls remain active.

`qa_skip.dart` provides debug/explicit-QA skip actions and training-arm overrides. `leave_session_dialog.dart` is shared by active sessions. `app_config.dart` holds shared layout padding; there is no flight-test feature flag.


## Sound requirements

`SoundGuard` requires media volume at least 55% and a non-silent/non-vibrate phone. It checks after language selection on launch, listens to volume changes, polls sound mode while foregrounded, and performs a fresh check on every resume. Continue is disabled until both checks pass. Dismissing the dialog does not relax the threshold or persist an exemption.

`sound_status.dart` isolates device checks for testing. Android uses the music stream and ringer mode. iOS uses `monitor/sound` in `ios/Runner/AppDelegate.swift` to await the next Mute probe rather than accepting the sound_mode plugin's cached result. iOS detection is an audio-timing heuristic, not a direct hardware-switch API; test silent-switch behavior on the target phone.

Background transitions invalidate pending reads. At launch/resume, checks must complete before interaction resumes. Silent-mode failures are confirmed across two readings; an isolated failed probe after a healthy reading does not reopen the modal. Persistent unknown/failed readings block Continue and retry; a fresh volume event takes precedence over an older read. Polling stops in the background and restarts on resume. This requires a rebuilt iOS app for the native channel.


iOS volume polling reads `AVAudioSession.outputVolume` through `monitor/sound` without activating the audio session on each poll. `silent_status_filter.dart` debounces silent-mode probe failures, not the 55% volume threshold. Camera capture stays `enableAudio: false`; `camera_avfoundation >=0.9.22+1` is required because older versions incorrectly initialized microphone input despite this setting.
