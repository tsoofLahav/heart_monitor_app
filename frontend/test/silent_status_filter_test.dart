import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/shell/silent_status_filter.dart';

void main() {
  test('isolated playback probe failures preserve a confirmed normal state',
      () {
    final filter = SilentStatusFilter();
    expect(filter.update(false), false);
    expect(filter.update(true), false);
    expect(filter.update(false), false);
    expect(filter.update(null), false);
    expect(filter.update(false), false);
  });
  test('sustained silent state blocks and recovery is immediate', () {
    final filter = SilentStatusFilter();
    filter.update(false);
    expect(filter.update(true), false);
    expect(filter.update(true), true);
    expect(filter.update(false), false);
  });
  test('launch and resume never inherit an old successful check', () {
    final filter = SilentStatusFilter();
    filter.update(false);
    filter.reset();
    expect(filter.update(true), null);
    expect(filter.pending, true);
    expect(filter.update(true), true);
    expect(filter.pending, false);
  });
  test('persistent unknown readings become a failed check', () {
    final filter = SilentStatusFilter();
    filter.update(false);
    expect(filter.update(null), false);
    expect(filter.update(null), null);
    expect(filter.pending, false);
  });
}
