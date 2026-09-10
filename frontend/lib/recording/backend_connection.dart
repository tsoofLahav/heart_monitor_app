import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'process_video_client.dart';

/// Azure App Service cold starts can take 30–90s; warm the app with a cheap GET.
class BackendConnection {
  BackendConnection._();

  static const Duration _warmupRequestTimeout = Duration(seconds: 90);
  static const Duration _warmupRetryDelay = Duration(seconds: 2);
  static const int _warmupMaxAttempts = 3;

  /// Full upload + server processing (after warm instance).
  static const Duration processVideoTimeout = Duration(seconds: 180);

  static DateTime? _lastSuccessfulWarmup;
  static Future<bool>? _warmupInFlight;

  static bool get isRecentlyWarm {
    final t = _lastSuccessfulWarmup;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(minutes: 10);
  }

  /// Fire-and-forget safe: dedupes concurrent calls.
  static Future<bool> establishConnectionInBackground() {
    _warmupInFlight ??= _runWarmup().whenComplete(() {
      _warmupInFlight = null;
    });
    return _warmupInFlight!;
  }

  static Future<bool> _runWarmup() async {
    for (var attempt = 1; attempt <= _warmupMaxAttempts; attempt++) {
      try {
        final uri = Uri.parse('$processVideoApiBase/');
        final response = await http.get(uri).timeout(_warmupRequestTimeout);
        if (response.statusCode == 200) {
          _lastSuccessfulWarmup = DateTime.now();
          debugPrint('Backend warm-up OK (attempt $attempt)');
          return true;
        }
        debugPrint(
          'Backend warm-up HTTP ${response.statusCode} (attempt $attempt)',
        );
      } catch (e) {
        debugPrint('Backend warm-up failed (attempt $attempt): $e');
      }
      if (attempt < _warmupMaxAttempts) {
        await Future<void>.delayed(_warmupRetryDelay);
      }
    }
    return false;
  }
}
