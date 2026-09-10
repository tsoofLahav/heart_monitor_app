import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_feedback/calibration/pulse_guide_step_image.dart';
import 'package:heart_feedback/experiment/experiment_store.dart';
import 'package:heart_feedback/shell/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prep_design_test.dart' show host;

Map<String, dynamic> progress(String mode) => {
      'participant_code': 'P001',
      'trial_id': 9,
      'status': 'training',
      'current_session': 2,
      'trail_step': 4,
      'has_pre_assessment': true,
      'has_post_assessment': false,
      'completed_session_numbers': [1, 2],
      'training_mode': mode,
    };

void main() {
  test('first profile save bootstraps then saves the selected group', () async {
    SharedPreferences.setMockInitialValues({});
    final paths = <String>[];
    await http.runWithClient(() async {
      final saved = await ExperimentStore.instance.updateParticipantProfile(
          firstName: 'QA',
          lastName: 'Tester',
          phone: '0500000000',
          trainingMode: 'audio');
      expect(saved, isTrue);
      expect(paths.indexOf('/data/bootstrap'),
          lessThan(paths.indexOf('/data/participants/me')));
      expect(ExperimentStore.instance.progress!.trainingMode, 'audio');
      final prefs = await SharedPreferences.getInstance();
      expect(
          jsonDecode(
              prefs.getString('experiment_progress_v1')!)['training_mode'],
          'audio');
    },
        () => MockClient((request) async {
              paths.add(request.url.path);
              if (request.url.path == '/') return http.Response('OK', 200);
              if (request.method == 'PATCH') {
                expect(jsonDecode(request.body)['training_mode'], 'audio');
                return http.Response(jsonEncode(progress('audio')), 200);
              }
              return http.Response(jsonEncode(progress('ppg')), 200);
            }));
  });

  test(
      'a backend that ignores the selected group is not treated as a successful save',
      () async {
    await http.runWithClient(() async {
      final saved = await ExperimentStore.instance.updateParticipantProfile(
          firstName: 'QA',
          lastName: 'Tester',
          phone: '0500000000',
          trainingMode: 'audio');
      expect(saved, isFalse);
    },
        () => MockClient(
            (_) async => http.Response(jsonEncode(progress('ppg')), 200)));
  });

  for (final language in ['en', 'he']) {
    testWidgets('$language profile shows and saves external QA selection',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile_first_name': 'QA',
        'profile_last_name': 'Tester',
        'profile_phone': '0500000000',
        'experiment_progress_v1': jsonEncode(progress('ppg')),
      });
      await ExperimentStore.instance.loadCached();
      String? requested;
      await http.runWithClient(() async {
        await tester.pumpWidget(host(
            Builder(
                builder: (context) => Scaffold(
                      body: TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const ProfileScreen())),
                          child: const Text('Open profile')),
                    )),
            language: language));
        await tester.tap(find.text('Open profile'));
        await tester.pumpAndSettle();
        final control = find.byKey(const ValueKey('profile-group-control'));
        await tester.scrollUntilVisible(control, 250,
            scrollable: find
                .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable))
                .first);
        await tester.tap(control);
        await tester.pump();
        expect(
            find.descendant(
                of: control, matching: find.byIcon(Icons.radio_button_checked)),
            findsOneWidget);
        final save = find.byType(ElevatedButton);
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(requested, 'audio');
        expect(find.text('Open profile'), findsOneWidget);
        expect(ExperimentStore.instance.progress!.trainingMode, 'audio');
        expect(
            ExperimentStore.instance.progress!.completedSessionNumbers, [1, 2]);
      },
          () => MockClient((request) async {
                requested = jsonDecode(request.body)['training_mode'] as String;
                return http.Response(jsonEncode(progress(requested!)), 200);
              }));
    });

    testWidgets('$language image overview is a square with a Done action',
        (tester) async {
      var finished = false;
      await tester.pumpWidget(host(
          Scaffold(
              body: PulseGuideInstructionsPager(
            finale: PulseGuideInstructionsFinale.comics,
            onFinished: () => finished = true,
          )),
          language: language));
      for (var i = 0; i < 4; i++) {
        await tester.drag(
            find.byType(PageView), Offset(language == 'he' ? 700 : -700, 0));
        await tester.pumpAndSettle();
      }
      final grid = find.byType(GridView);
      expect(grid, findsOneWidget);
      final images = find.descendant(of: grid, matching: find.byType(Image));
      expect(images, findsNWidgets(4));
      expect(tester.getTopLeft(images.at(0)).dy,
          tester.getTopLeft(images.at(1)).dy);
      expect(tester.getTopLeft(images.at(2)).dy,
          tester.getTopLeft(images.at(3)).dy);
      expect(tester.getTopLeft(images.at(0)).dy,
          lessThan(tester.getTopLeft(images.at(2)).dy));
      final size = tester.getSize(grid);
      expect(size.width, closeTo(size.height, 1));
      expect(find.text(language == 'he' ? 'סיום' : 'Done'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(finished, isTrue);
    });
  }
}
