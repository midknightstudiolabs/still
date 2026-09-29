import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/domain/models.dart';
import 'package:still/presentation/progress.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  test(
    'Milestone percentage, dates, undo, migration and failed saves',
    () async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.loadDemo();
      final id = c.data.visions.first.id;
      final legacy = c.vision(id).toJson()
        ..remove('milestones')
        ..remove('targetDate');
      expect(Vision.fromJson(legacy).progressPercent, isNull);
      expect(Vision.fromJson(legacy).targetDate, isNull);
      final created = c.vision(id).createdAt;
      final move = c.vision(id).nextMoveId;
      final list = List.generate(
        5,
        (i) => Milestone(
          id: '$i',
          title: 'Step $i',
          completedAt: i < 2 ? DateTime(2026, 9, 29) : null,
        ),
      );
      await c.saveProgress(id, list, DateTime(2027, 3, 12, 18));
      expect(c.vision(id).progressPercent, 40);
      expect(c.vision(id).targetDate, DateTime(2027, 3, 12));
      expect(c.vision(id).createdAt, created);
      expect(c.vision(id).nextMoveId, move);
      final loaded = StillController(repo);
      await loaded.initialize();
      expect(loaded.vision(id).progressPercent, 40);
      expect(
        loaded.vision(id).milestones.first.completedAt,
        DateTime(2026, 9, 29),
      );
      list.first.completedAt = null;
      expect(c.vision(id).progressPercent, 40);
      repo.fail = true;
      await expectLater(c.saveProgress(id, list, null), throwsStateError);
      expect(c.vision(id).progressPercent, 40);
      repo.fail = false;
      await c.saveProgress(id, list, null);
      expect(c.vision(id).progressPercent, 20);
      expect(c.vision(id).targetDate, isNull);
      list.removeLast();
      await c.saveProgress(id, list, null);
      expect(c.vision(id).progressPercent, 25);
      for (final m in list) {
        m.completedAt = DateTime(2026, 9, 29);
      }
      await c.saveProgress(id, list, null);
      expect(c.vision(id).progressPercent, 100);
      expect(c.vision(id).status, VisionStatus.active);
      await c.saveProgress(id, [], null);
      expect(c.vision(id).progressPercent, isNull);
    },
  );

  testWidgets('Add, complete, save and cancel milestones; clear target date', (
    tester,
  ) async {
    final c = StillController(MemoryRepository());
    await c.loadDemo();
    final id = c.data.visions.first.id;
    await c.saveProgress(id, [], DateTime(2027, 3, 12));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => editProgress(context, c, id),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add milestone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Book flights');
    await tester.pump();
    await tester.tap(find.text('Keep milestone'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('100% · 1 of 1 complete'), findsOneWidget);
    expect(c.vision(id).milestones, isEmpty);
    await tester.ensureVisible(find.text('Clear date'));
    await tester.tap(find.text('Clear date'));
    await tester.tap(find.text('Save progress'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(c.vision(id).progressPercent, 100);
    expect(c.vision(id).targetDate, isNull);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.byTooltip('Cancel changes'));
    await tester.pumpAndSettle();
    expect(c.vision(id).progressPercent, 100);
  });
}
