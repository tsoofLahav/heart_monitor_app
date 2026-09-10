import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/game/score_reveal_screen.dart';
import 'package:heart_feedback/protocols/protocol_models.dart';
import 'package:heart_feedback/protocols/protocol_summary_screen.dart';
import 'package:heart_feedback/protocols/round_score_panel.dart';
import 'prep_design_test.dart' show host, capture;

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_PREP_UI')) {
      final loader = FontLoader('PreviewArial');
      loader.addFont(Future.value(ByteData.sublistView(
          File('/System/Library/Fonts/Supplemental/Arial.ttf')
              .readAsBytesSync())));
      await loader.load();
    }
  });
  for (final language in ['en', 'he']) {
    testWidgets('$language round feedback shows beats and just two scores',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var continued = false;
      const round = ProtocolRound(
          roundIndex: 0,
          netStableSec: 20,
          sessionData: {
            'peaks_count': 30,
            'quality': {'mean_hr_bpm': 90}
          },
          guessedBeats: 28,
          confidencePercent: 70,
          sliderBpm: 85);
      await tester.pumpWidget(host(
          ProtocolSummaryScreen(
              rounds: const [round], onContinue: () => continued = true),
          language: language));
      await tester.pumpAndSettle();
      final panel =
          tester.widget<RoundScorePanel>(find.byType(RoundScorePanel));
      expect(panel.actualBeats, 30);
      expect(panel.countedBeats, 28);
      expect(panel.countingScore, (round.countScoreFraction * 100).round());
      expect(panel.matchingScore, (round.hrScoreFraction * 100).round());
      expect(find.text('30'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('Target net (debug)'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture(tester, '${language}_mid_score');
      await tester.tap(find.byType(ElevatedButton));
      expect(continued, isTrue);
    });

    testWidgets(
        '$language final score stays on two stable lines through animation',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(
          const ScoreRevealScreen(roundScore: 100, showBackToMenu: true),
          language: language));
      final label = find.byKey(const ValueKey('session-score-label'));
      final value = find.byKey(const ValueKey('session-score-value'));
      final labelY = tester.getTopLeft(label).dy;
      final valueY = tester.getTopLeft(value).dy;
      expect(tester.getBottomLeft(label).dy, lessThan(valueY));
      for (final duration in [20, 300, 1000, 1680]) {
        await tester.pump(Duration(milliseconds: duration));
        expect(tester.getTopLeft(label).dy, labelY);
        expect(tester.getTopLeft(value).dy, valueY);
        expect(tester.widget<Text>(value).maxLines, 1);
      }
      expect(tester.widget<Text>(value).data, '100%');
      expect(tester.widget<Text>(label).data,
          language == 'he' ? 'ציון התרגול:' : 'Session score:');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
