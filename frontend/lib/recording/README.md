# Recording

`heartbeat_recording_screen.dart` owns camera selection, flash, finger-placement detection, capture, wakelock, upload, and return navigation. `recording_screens.dart` exposes the two active entry widgets:

- `LearnPracticeRecordingScreen`: 5-second tutorial measurement interval, preceded by 3 seconds of warmup and followed by a 1-second tail.
- `ProtocolRecordingScreen`: caller-specified duration for training and assessments, including round/footer labels.

Both return packaged data using `Navigator.pop`. `process_video_client.dart` uploads multipart video and optional UTC start time to `/process_video`, then maps signal, peaks, timing, vitals and ML quality into the app payload. `backend_connection.dart` handles warmup and timeouts.

The backend's `quality_label` is the quality decision. Training/assessment callers use `isBadProtocolReading`; tutorial practice reads the label directly. The client retains `not_reading` compatibility with older backend responses.

Finger-placement gating is separate from ML quality: it checks camera frames before recording. Keep both. Tests cover finger detection and protocol quality interpretation; camera lifecycle requires a real device.

`recording_timing.dart` owns the 3-second warmup, cue timestamps, and 1-second tail. `maxSessionSeconds` arguments retain net + 3 semantics; the tail is added internally. The client uploads both cue offsets and requires the backend to echo their interval before scoring. Physical audio/camera latency remains a device verification requirement.


## Voice and counting modes

`recording_voice.dart` plays bundled English/Hebrew WAV clips. After finger detection it says “Get ready. Keep still.” before starting capture; after capture (including the tail) it says “You can lift your finger.” Speech must complete before counting begins. Detection hints have a 10-second cooldown and are stopped when a session starts or is cancelled.

Only PPG training and assessment count trials enable `countingBeeps`. Quality practice, assessment rhythm-match measurements and relaxation retain the same measurement buffers and backend interval validation but emit no boundary beeps. Camera identification uses a separate “Camera found” voice cue. The sound check plays a voice sample. Audio-control sequences and the matching slider's rhythm remain audible.

Assets are synthesized speech (macOS Samantha/Carmit, 165 words/minute, mono 22.05 kHz PCM WAV). Review pronunciation and playback on device; replace clips at the same paths to change the voices. Existing instruction images are intentionally unchanged pending replacements.


## Silent capture dependency

Both camera controllers set `enableAudio: false`; voice and beep playback require no microphone access. The explicit `camera_avfoundation` dependency floor includes the upstream fix for audio setup ignoring this flag. Do not downgrade to 0.9.21+2: its audio-setup guard initializes microphone input even when disabled and changes the shared audio session to play-and-record.
