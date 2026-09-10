import 'heartbeat_recording_screen.dart';
import 'recording_flow.dart';

/// Tutorial practice: 3s warmup, 5s counting, then a 1s tail.
class LearnPracticeRecordingScreen extends HeartbeatRecordingScreen {
  const LearnPracticeRecordingScreen({super.key})
      : super(flow: RecordingFlow.learn);
}

/// Protocol step: variable-length capture; returns packaged data via [Navigator.pop].
class ProtocolRecordingScreen extends HeartbeatRecordingScreen {
  const ProtocolRecordingScreen({
    super.key,
    required int maxSessionSeconds,
    required int recordingNumber,
    int totalRounds = 2,
    bool countingBeeps = true,
    String? sessionTitle,
    String? footerLabel,
  }) : super(
          flow: RecordingFlow.protocol,
          countingBeeps: countingBeeps,
          maxSessionSecondsOverride: maxSessionSeconds,
          protocolRecordingNumber: recordingNumber,
          protocolTotalRounds: totalRounds,
          sessionTitle: sessionTitle,
          footerLabel: footerLabel,
        );
}
