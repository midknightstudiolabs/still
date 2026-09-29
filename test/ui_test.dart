import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/main.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/presentation/profile.dart';
import 'package:still/presentation/home.dart';
import 'package:still/presentation/editors.dart';
import 'package:still/domain/models.dart';
import 'package:still/domain/guidance.dart';
import 'package:still/presentation/question_flow.dart';

import 'journeys_test.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the actual bundled fonts instead of the test-only Ahem font.
    final sans = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    final serif = FontLoader('Cormorant')
      ..addFont(rootBundle.load('assets/fonts/CormorantGaramond.ttf'));
    await Future.wait([sans.load(), serif.load()]);
  });
  testWidgets('Welcome to first vision and Next Move', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = StillController(MemoryRepository());
    await c.initialize();
    await tester.pumpWidget(StillApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('What matters to you?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Take my parents to Japan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'While we still can.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review my vision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep this close'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Check passport expiry.',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Keep this move'));
    await tester.tap(find.text('Keep this move'));
    await tester.pumpAndSettle();
    expect(c.active.single.title, 'Take my parents to Japan');
    expect(c.move(c.active.single)!.text, 'Check passport expiry.');
    expect(find.text('Keep this alive.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Demo Today is calm; Not today preserves the move', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = StillController(MemoryRepository());
    await c.initialize();
    await c.loadDemo();
    await tester.pumpWidget(StillApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Not today'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Not today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect(find.text('It can wait. This is still yours.'), findsOneWidget);
    expect(c.data.moves.where((m) => m.completedAt != null), isEmpty);
    expect(c.data.proofs.length, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Optional profile saves multiple roles and priority on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = StillController(MemoryRepository());
      await c.initialize();
      await tester.pumpWidget(
        MaterialApp(home: ProfileScreen(controller: c, first: true)),
      );
      await tester.pumpAndSettle();
      Future<void> choose(String label) async {
        await tester.scrollUntilVisible(find.text(label), 180);
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await choose('Student');
      await choose('Working professional');
      await choose('Continue');
      await choose('Learning / Study');
      await choose('Continue');
      await choose('It feels too big');
      await choose('Continue');
      await choose('About 5 minutes');
      await choose('Continue');
      await choose('Continue to my vision');
      expect(c.data.preferences.profile.roles, [
        'Student',
        'Working professional',
      ]);
      expect(c.data.preferences.profile.barrier, 'overwhelmed');
      expect(c.data.preferences.profile.capacity, 'small');
      expect(
        tester
            .widget<AnswerCard>(
              find.widgetWithText(AnswerCard, 'Learning / Study'),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(visionExample(c.data.preferences.profile)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Suggested move is opt in and cue persists', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = StillController(MemoryRepository());
    await c.initialize();
    final id = await c.createVision(
      title: 'Learn',
      why: '',
      image: '',
      area: 'Learning / Study',
      obstacle: 'unclear',
      rhythm: Rhythm.weekly,
      tone: Tone.grounded,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoveEditor(controller: c, visionId: id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help me find a starting point'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use this as a starting point'));
    await tester.tap(find.text('Use this as a starting point'));
    await tester.pumpAndSettle();
    expect(c.move(c.vision(id)), isNull);
    await tester.enterText(find.byType(TextField).at(1), 'After breakfast');
    await tester.ensureVisible(find.text('Keep this move'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep this move'));
    await tester.pumpAndSettle();
    expect(c.move(c.vision(id))!.text, contains('question'));
    expect(c.move(c.vision(id))!.cue, 'After breakfast');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings explains every tone and offers research and profile', (
    tester,
  ) async {
    final c = StillController(MemoryRepository());
    await c.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsScreen(controller: c)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A little about you'), findsOneWidget);
    expect(find.text('Why these questions'), findsOneWidget);
    for (final tone in Tone.values) {
      final preview = find.text(
        '${toneDescription(tone)}\n\nToday preview: “${toneExample(tone)}”',
      );
      await tester.scrollUntilVisible(preview, 200);
      expect(preview, findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
