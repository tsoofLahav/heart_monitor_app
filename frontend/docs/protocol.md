# Current study protocol

## Entry and progression

Language selection → welcome → preparation → forest trail. Four preparation requirements: profile, before appreciation questionnaire, camera identification, pulse practice. Reminder scheduling is available separately.

Trail step 1 is PRE; steps 2–9 are training sessions 1–8; step 10 is POST. For the external-QA phase, new installations default to Regular (`ppg`); random assignment is disabled. Profile exposes Regular/Control choices in normal builds and saves `training_mode: ppg` or `audio` through `PATCH /data/participants/me`. Existing participants retain their saved group until changed. Both arms share preparation and assessments. Developer debug controls remain separate and may override training mode or skip steps.

## PPG training

Each session has two rounds: recording → beat-count guess and confidence → HR slider → round feedback, followed by a final score reveal.

Each round independently draws an integer stable duration from 20–40 seconds. Capture warms up for 3 seconds before the start cue, counts for the requested duration, plays the end cue, then captures a 1-second tail. The existing duration argument is net + 3; the recording screen adds the tail internally. Duration hints are hidden. Failed uploads or bad readings retry the same round duration. `quality_label: bad` is the ML rejection result (0 bad windows allowed for 1–3 parts, 1 for 4–5, 2 for 6+); the client also accepts legacy `not_reading` responses.

## Audio control training

`ControlProtocolFlowScreen` follows the two-round structure using generated external beeps instead of video measurement. `control_beep_sequence.dart` defines the sequence; guessing and slider responses are compared with its count and rate.

## Slider and scores

Slider position 0 maps to 150 BPM, 0.5 to 90 BPM, and 1 to 40 BPM, piecewise linearly. The rhythm uses 23 waypoints. ECG rhythm scheduling is implemented under `lib/protocols/ecg/`.

Count accuracy is `clamp(1 - abs(guess - actual) / max(actual, 1), 0, 1)`. Exact counts score `0.7 + 0.3 * confidence/100`; inaccurate counts receive a penalty for confidence above count accuracy. HR accuracy is `clamp(1 - abs(sliderBpm - actualBpm)/110, 0, 1)`.

Each training round weights count and HR equally. The final session score averages both rounds on a 0–100 scale. Missing measured HR contributes zero HR score.

## PRE and POST assessments

`assessment_models.dart` defines 12 steps:

1. Five count/confidence trials: 15 stable seconds first, then shuffled 25/35/45/60 seconds.
2. Six HR-matching trials: 20 stable seconds each; three start 15 BPM above measured HR and three below, shuffled and clamped to 40–150 BPM.
3. A 60-stable-second relax recording for vitals.

Recordings use the same 3-second warmup, cue interval and 1-second tail as PPG training. HeartbeatScore averages count scores; QuestionnaireScore averages HR-match accuracy. Relax mean HR, RMSSD, IBI CV, duration and peak count are saved separately. RMSSD is in milliseconds.

## Data ownership

Video processing returns normalized signal, real/fake peaks, signal/window timing, numeric vitals and ML quality. The client packages `quality.peaks_count` into `peaks_count` and `signal` into `clean_signal`.

Participant/trial progress, aggregate session scores, assessments, questionnaire answers and schedules are persisted through `/data/*` in Azure SQL. Raw video is a temporary processing input and is removed by the backend after the request. See the backend database documentation for migrations and fields.

## Counting boundaries

`recording/recording_timing.dart` schedules the cues with one monotonic clock. The video upload includes actual cue-command offsets (`counting_start_sec`, `counting_end_sec`). The backend limits scored peaks and ML input to that interval; it retains bad-window beats when the overall recording is accepted. ML window zero is reported as `quality_window_origin_sec` on the video timeline.

The client checks the returned peak-window boundaries before accepting a measurement. Deploy the compatible backend first. The old app does not send cue offsets and retains legacy behavior until updated.

Offsets are relative to camera-start acknowledgement and audio playback requests. Verify audible beep timing against camera timing on a physical phone before claiming exact alignment; platform latency is not measured by Dart timers.


## Spoken guidance

Quality practice teaches finger placement, with voice only. The first counting assessment teaches “count between the two beeps”; later rounds use short reminders. PPG training repeats the rule in its introduction. Non-counting assessment measurements explicitly require no counting and use voice only. The control arm still counts its external beep sequence.

Spoken clips follow the selected English/Hebrew locale: preparation (“Get ready. Keep still.”), capture completion (“You can lift your finger.”), blocked baseline detection (“Lift your finger, then place it back on the camera.”), and wrong-camera guidance. Camera setup has its own spoken confirmation. Audio guidance is cancelled with the screen and detection hints are rate-limited. Images will be replaced separately by the project owner.
