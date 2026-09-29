import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/domain/models.dart';
import 'package:still/presentation/value_progress.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  test(
    'Money uses exact decimals, deposit total, withdrawals and a capped percentage',
    () async {
      expect(parseValue('0.10')! + parseValue('0.20')!, 30);
      for (final invalid in ['NaN', 'Infinity', '1,000', '0.001', '1e9']) {
        expect(parseValue(invalid), isNull);
      }
      final repo = MemoryRepository(), now = DateTime(2026, 9, 29);
      final c = StillController(repo);
      await c.loadDemo();
      final id = c.data.visions.first.id;
      await c.saveProgress(id, [Milestone(id: 'm', title: 'Plan')], now);
      final entries = [
        ValueEntry(id: 'a', amount: 200000, when: now, note: 'Deposit'),
      ];
      await c.saveValueProgress(
        id,
        ProgressMeasure.money,
        1000000,
        'PHP',
        entries,
        now,
      );
      expect(c.vision(id).progressPercent, 20);
      expect(c.vision(id).milestones.length, 1);
      entries.add(ValueEntry(id: 'b', amount: -50000, when: now));
      await c.saveValueProgress(
        id,
        ProgressMeasure.money,
        1000000,
        'PHP',
        entries,
        now,
      );
      expect(c.vision(id).progressPercent, 15);
      final loaded = StillController(repo);
      await loaded.initialize();
      expect(loaded.vision(id).valueTotal, 150000);
      expect(loaded.vision(id).entries.first.note, 'Deposit');
      repo.fail = true;
      await expectLater(
        c.saveValueProgress(
          id,
          ProgressMeasure.money,
          2000000,
          'PHP',
          entries,
          now,
        ),
        throwsStateError,
      );
      expect(c.vision(id).valueTarget, 1000000);
      repo.fail = false;
      await expectLater(
        c.saveValueProgress(id, ProgressMeasure.money, 0, 'PHP', entries, now),
        throwsArgumentError,
      );
      await expectLater(
        c.saveValueProgress(id, ProgressMeasure.value, 100, 'km', [
          ValueEntry(id: 'c', amount: -1, when: now),
        ], now),
        throwsArgumentError,
      );
      await c.saveValueProgress(
        id,
        ProgressMeasure.value,
        100000,
        'km',
        entries,
        now,
      );
      expect(c.vision(id).progressPercent, 100);
      expect(c.vision(id).valueTotal, 150000);
      expect(c.vision(id).status, VisionStatus.active);
      await c.saveProgress(id, c.vision(id).milestones, now);
      expect(c.vision(id).progressPercent, 0);
      expect(c.vision(id).entries.length, 2);
    },
  );

  testWidgets('Money target and dated deposit save then reload', (
    tester,
  ) async {
    final repo = MemoryRepository();
    final c = StillController(repo);
    await c.loadDemo();
    final id = c.data.visions.first.id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ValueProgressEditor(
                    controller: c,
                    id: id,
                    measure: ProgressMeasure.money,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Target value'),
      '10000',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Record deposit or withdrawal'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Record deposit or withdrawal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '2000');
    await tester.tap(find.text('Keep entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save progress'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    final loaded = StillController(repo);
    await loaded.initialize();
    expect(loaded.vision(id).progressPercent, 20);
    expect(loaded.vision(id).valueUnit, 'PHP');
    expect(loaded.vision(id).entries.length, 1);
  });
}
