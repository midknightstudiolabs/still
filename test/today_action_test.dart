import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/domain/models.dart';
import 'package:still/presentation/today_action.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  test(
    'Quick entries serialize safely and failed completion leaves data unchanged',
    () async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.loadDemo();
      final id = c.active.first.id;
      await c.saveValueProgress(
        id,
        ProgressMeasure.money,
        100000,
        'PHP',
        [],
        null,
      );
      await Future.wait([
        c.appendValueEntry(
          id,
          ValueEntry(id: 'a', amount: 10000, when: DateTime(2026)),
        ),
        c.appendValueEntry(
          id,
          ValueEntry(id: 'b', amount: 20000, when: DateTime(2026)),
        ),
      ]);
      expect(c.vision(id).valueTotal, 30000);
      await c.appendValueEntry(
        id,
        ValueEntry(id: 'a', amount: 10000, when: DateTime(2026)),
      );
      expect(c.vision(id).entries.length, 2);
      await c.saveProgress(id, [
        Milestone(id: 'm', title: 'Book flights'),
      ], null);
      repo.fail = true;
      await expectLater(c.setMilestoneDone(id, 'm', true), throwsStateError);
      expect(c.vision(id).progressPercent, 0);
      repo.fail = false;
      final move = c.move(c.vision(id))!;
      final proofs = c.proofs(id).length;
      await c.completeMove(id);
      await c.undoMove(id, move.id);
      expect(c.move(c.vision(id))!.id, move.id);
      expect(c.proofs(id).length, proofs);
    },
  );

  testWidgets(
    'One tap completes milestone, undo restores it, no planning form',
    (tester) async {
      final c = StillController(MemoryRepository());
      await c.loadDemo();
      final id = c.active.first.id;
      await c.saveProgress(id, [
        Milestone(id: 'm', title: 'Book flights'),
      ], null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TodayAction(controller: c, id: id, onOpen: () {}),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Complete milestone'));
      await tester.pumpAndSettle();
      expect(c.vision(id).progressPercent, 100);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(c.vision(id).progressPercent, 0);
    },
  );

  testWidgets('Direct deposit retains input after failure and saves on retry', (
    tester,
  ) async {
    final repo = MemoryRepository();
    final c = StillController(repo);
    await c.loadDemo();
    final id = c.active.first.id;
    await c.saveValueProgress(
      id,
      ProgressMeasure.money,
      100000,
      'PHP',
      [],
      null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodayAction(controller: c, id: id, onOpen: () {}),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add deposit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (PHP)'),
      '200',
    );
    repo.fail = true;
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    expect(c.vision(id).valueTotal, 0);
    repo.fail = false;
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(c.vision(id).progressPercent, 20);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
