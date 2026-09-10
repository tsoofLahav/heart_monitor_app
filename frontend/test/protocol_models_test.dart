import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';

void main() {
  test('ML bad readings trigger rejection and good readings proceed', () {
    expect(isBadProtocolReading({'quality_label': 'bad'}), isTrue);
    expect(isBadProtocolReading({'quality_label': 'good'}), isFalse);
    expect(isBadProtocolReading({'not_reading': true}), isTrue);
  });

  test('bpm mapping center and extremes', () {
    expect(bpmFromSliderValue(0.5).round(), 90);
    expect(bpmFromSliderValue(0.0).round(), 150);
    expect(bpmFromSliderValue(1.0).round(), 40);
  });

  test('random net stable in range', () {
    for (var i = 0; i < 50; i++) {
      final n = drawRandomNetStableSec();
      expect(n, inInclusiveRange(netStableMinSec, netStableMaxSec));
      expect(videoSecondsForNetStable(n), n + backendTrimSeconds);
    }
  });

  test('slider waypoints map to bpm range', () {
    expect(bpmForWaypoint(0).round(), 150);
    expect(bpmForWaypoint(hrSliderWaypointCount - 1).round(), 40);
    final mid = hrWaypointIndexFromSlider(0.5);
    expect(bpmForWaypoint(mid).round(), 90);
  });
}
