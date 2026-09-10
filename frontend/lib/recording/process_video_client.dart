import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'backend_connection.dart';
import 'recording_timing.dart';

// Presentation copy: supply your own deployment at build/run time.
const String processVideoApiBase = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://your-backend.example.com',
);

/// Upload video file; returns raw JSON map, `{not_reading: true}`, or null on failure.
Future<Map<String, dynamic>?> processVideo({
  required String filePath,
  DateTime? recordingStartedAtUtc,
  CountingCueWindow? countingWindow,
}) async {
  if (!BackendConnection.isRecentlyWarm) {
    await BackendConnection.establishConnectionInBackground();
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$processVideoApiBase/process_video'),
  );
  request.files.add(await http.MultipartFile.fromPath('video', filePath));
  if (recordingStartedAtUtc != null) {
    request.fields['recording_started_at'] =
        recordingStartedAtUtc.toUtc().toIso8601String();
  }

  if (countingWindow != null) {
    request.fields['counting_start_sec'] =
        countingWindow.startSeconds.toString();
    request.fields['counting_end_sec'] = countingWindow.endSeconds.toString();
  }

  try {
    final streamedResponse =
        await request.send().timeout(BackendConnection.processVideoTimeout);
    final response = await http.Response.fromStream(streamedResponse).timeout(
      BackendConnection.processVideoTimeout,
    );
    debugPrint('process_video: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded);
      if (data['not_reading'] == true) {
        return {'not_reading': true};
      }
      if (countingWindow != null &&
          !backendMatchesCountingWindow(data, countingWindow)) {
        debugPrint('Backend did not acknowledge counting cue interval');
        return null;
      }
      if (data['signal'] != null && data['real_peaks'] != null) {
        return data;
      }
      return null;
    }
    return null;
  } catch (e) {
    debugPrint('Error sending video: $e');
    return null;
  }
}

Map<String, dynamic> packageSessionData(Map<String, dynamic> data) {
  final qualityRaw = data['quality'];
  final quality = qualityRaw is Map
      ? Map<String, dynamic>.from(qualityRaw)
      : <String, dynamic>{};

  final realPeaks =
      (data['real_peaks'] as List).map((e) => (e as num).toDouble()).toList();
  final signal =
      (data['signal'] as List).map((e) => (e as num).toDouble()).toList();

  return {
    'peaks_count': quality['peaks_count'] ?? realPeaks.length,
    'real_peaks': realPeaks,
    'fake_peaks':
        (data['fake_peaks'] as List).map((e) => (e as num).toDouble()).toList(),
    'duration': (quality['duration_sec'] as num?)?.toDouble() ?? 0.0,
    'clean_signal': signal,
    'quality': quality,
    if (quality['fps'] != null) 'fps': (quality['fps'] as num).toDouble(),
    if (quality['video_width'] != null)
      'video_width': (quality['video_width'] as num).toInt(),
    if (quality['video_height'] != null)
      'video_height': (quality['video_height'] as num).toInt(),
    if (data['signal_start_sec'] != null)
      'signal_start_sec': (data['signal_start_sec'] as num).toDouble(),
    if (data['signal_end_sec'] != null)
      'signal_end_sec': (data['signal_end_sec'] as num).toDouble(),
    if (data['peak_window_start_sec'] != null)
      'peak_window_start_sec':
          (data['peak_window_start_sec'] as num).toDouble(),
    if (data['peak_window_end_sec'] != null)
      'peak_window_end_sec': (data['peak_window_end_sec'] as num).toDouble(),
    if (data['peak_window_start_utc'] != null)
      'peak_window_start_utc': data['peak_window_start_utc'].toString(),
    if (data['peak_window_end_utc'] != null)
      'peak_window_end_utc': data['peak_window_end_utc'].toString(),
    if (data['quality_label'] != null)
      'quality_label': data['quality_label'].toString(),
    if (data['quality_prob_good'] != null)
      'quality_prob_good': (data['quality_prob_good'] as num).toDouble(),
    if (data['quality_prob_bad'] != null)
      'quality_prob_bad': (data['quality_prob_bad'] as num).toDouble(),
    for (final key in [
      'quality_window_origin_sec',
      'quality_bad_windows',
      'quality_allowed_bad_windows'
    ])
      if (data[key] != null) key: data[key],
    if (data['quality_windows'] != null)
      'quality_windows': (data['quality_windows'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
  };
}
