import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/domain/models.dart';
import 'package:still/presentation/design.dart';
import 'package:still/presentation/onboarding.dart';
import 'package:still/presentation/profile.dart';
import 'package:still/presentation/question_flow.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  test('Question foregrounds meet ordinary text contrast in both themes', () {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final brightness in Brightness.values) {
      final c = stillTheme(brightness).colorScheme;
      expect(ratio(c.onSurfaceVariant, c.surface), greaterThanOrEqualTo(4.5));
      expect(
        ratio(c.onSurface, c.surfaceContainerLow),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        ratio(c.onPrimaryContainer, c.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
  setUpAll(() async {
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
    await (FontLoader(
      'Cormorant',
    )..addFont(rootBundle.load('assets/fonts/CormorantGaramond.ttf'))).load();
  });
  final shotKey = GlobalKey();
  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    final boundary =
        shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final picture = await boundary.toImage(pixelRatio: 1);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/ux-previews');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    bool dark = false,
    double width = 390,
    double scale = 1,
  }) async {
    await tester.pumpWidget(const SizedBox());
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          theme: stillTheme(dark ? Brightness.dark : Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final f = find.text(label);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'One question at a time, back preserves answers, review edits return directly',
    (tester) async {
      final c = StillController(MemoryRepository());
      await c.initialize();
      await mount(tester, ProfileScreen(controller: c));
      expect(find.text('Step 1 of 5 · Optional'), findsOneWidget);
      expect(find.text('What would you like more room for?'), findsNothing);
      await tap(tester, 'Student');
      await capture(tester, '01-profile-light');
      await tap(tester, 'Continue');
      await tap(tester, 'Learning / Study');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnswerCard>(find.widgetWithText(AnswerCard, 'Student'))
            .selected,
        isTrue,
      );
      await tap(tester, 'Continue');
      expect(
        tester
            .widget<AnswerCard>(
              find.widgetWithText(AnswerCard, 'Learning / Study'),
            )
            .selected,
        isTrue,
      );
      await tap(tester, 'Continue');
      await capture(tester, '02-obstacle-light');
      await tap(tester, 'Skip this question');
      await tap(tester, 'About 5 minutes');
      await capture(tester, '03-capacity-light');
      await tap(tester, 'Continue');
      await capture(tester, '04-profile-review');
      expect(c.data.preferences.profile.saved, isFalse);
      final changeRoles = find.descendant(
        of: find.byType(ReviewAnswer).first,
        matching: find.text('Change'),
      );
      await tester.ensureVisible(changeRoles);
      await tester.tap(changeRoles);
      await tester.pumpAndSettle();
      await tap(tester, 'Working professional');
      await tap(tester, 'Back to review');
      expect(find.text('Step 5 of 5 · Review'), findsOneWidget);
      await tap(tester, 'Save my preferences');
      expect(c.data.preferences.profile.roles.length, 2);
      expect(c.data.preferences.profileDraft, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Vision draft resumes and requires a name with visible validation',
    (tester) async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.initialize();
      await mount(tester, VisionWizard(controller: c));
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      expect(
        find.text(
          'Give your vision a name to continue. A few words are enough.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'More time together');
      await tap(tester, 'Continue');
      await tester.enterText(
        find.byType(TextField),
        'Reconnect with my family',
      );
      await tap(tester, 'Continue');
      final reopened = StillController(repo);
      await reopened.initialize();
      await mount(tester, VisionWizard(controller: reopened));
      expect(find.text('Step 4 of 8 · Optional'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tap(tester, 'Continue');
      }
      await tap(tester, 'Review my vision');
      expect(find.text('More time together'), findsOneWidget);
      await capture(tester, '05-vision-review');
      expect(reopened.data.visions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Dark narrow screen and large text keep question and actions usable',
    (tester) async {
      final c = StillController(MemoryRepository());
      await c.initialize();
      await mount(
        tester,
        ProfileScreen(controller: c),
        dark: true,
        width: 320,
        scale: 1.6,
      );
      await capture(tester, '06-profile-dark-large');
      for (var i = 0; i < 4; i++) {
        await tap(tester, 'Skip this question');
      }
      expect(find.text('Save my preferences').hitTestable(), findsOneWidget);
      await capture(tester, '07-review-dark-large');
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Draft failures preserve committed data and drafts clear only after successful save',
    () async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.initialize();
      await c.saveDraft('vision', {'step': 1, 'title': 'Existing'});
      repo.fail = true;
      await expectLater(
        c.saveDraft('vision', {'step': 2, 'title': 'Changed'}),
        throwsStateError,
      );
      expect(c.data.preferences.visionDraft['title'], 'Existing');
      repo.fail = false;
      await c.createVision(
        title: 'Existing',
        why: '',
        image: '',
        area: 'Home',
        rhythm: Rhythm.weekly,
        tone: Tone.grounded,
      );
      expect(c.data.preferences.visionDraft, isEmpty);
    },
  );
  test(
    'Rest persists across reload, can be undone and expires next calendar day',
    () async {
      final repo = MemoryRepository();
      var now = DateTime(2026, 9, 29, 23, 59);
      final c = StillController(repo, clock: () => now);
      await c.initialize();
      await c.restToday('v');
      final reopened = StillController(repo, clock: () => now);
      await reopened.initialize();
      expect(reopened.isResting('v'), isTrue);
      await reopened.restToday('v', undo: true);
      expect(reopened.isResting('v'), isFalse);
      await reopened.restToday('v');
      now = DateTime(2026, 9, 30);
      expect(reopened.isResting('v'), isFalse);
      expect(reopened.data.moves, isEmpty);
      expect(reopened.data.proofs, isEmpty);
    },
  );
}
