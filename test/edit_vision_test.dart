import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/domain/models.dart';
import 'package:still/presentation/detail.dart';
import 'package:still/presentation/question_flow.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  testWidgets('Edit saved vision commits once; cancel keeps saved answers', (
    tester,
  ) async {
    final repo = MemoryRepository();
    final c = StillController(repo);
    await c.loadDemo();
    final v = c.data.visions.first;
    final originalCount = c.data.visions.length;
    final moveId = v.nextMoveId;
    final proofIds = c.proofs(v.id).map((p) => p.id).toList();
    await c.saveDraft('vision', {'title': 'Separate unfinished vision'});
    await tester.pumpWidget(
      MaterialApp(
        home: VisionDetail(controller: c, id: v.id),
      ),
    );
    await tester.tap(find.byTooltip('Edit vision'));
    await tester.pumpAndSettle();
    final change = find.descendant(
      of: find.byType(ReviewAnswer).first,
      matching: find.text('Change'),
    );
    await tester.ensureVisible(change);
    await tester.tap(change);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A revised vision');
    await tester.tap(find.text('Back to review'));
    await tester.pumpAndSettle();
    expect(c.vision(v.id).title, v.title);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(c.vision(v.id).title, 'A revised vision');
    expect(c.data.visions.length, originalCount);
    expect(c.vision(v.id).nextMoveId, moveId);
    expect(c.proofs(v.id).map((p) => p.id), proofIds);
    expect(
      c.data.preferences.visionDraft['title'],
      'Separate unfinished vision',
    );
    final reloaded = StillController(repo);
    await reloaded.initialize();
    expect(reloaded.vision(v.id).title, 'A revised vision');
    await tester.tap(find.byTooltip('Edit vision'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(change);
    await tester.tap(change);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unsaved change');
    await tester.tap(find.byTooltip('Cancel changes'));
    await tester.pumpAndSettle();
    expect(c.vision(v.id).title, 'A revised vision');
  });

  test(
    'Updating a completed vision preserves history and handles failed saves',
    () async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.loadDemo();
      final id = c.data.visions.first.id;
      await c.setStatus(id, VisionStatus.completed);
      final before = c.vision(id).toJson();
      Future<void> update(String title) => c.updateVision(
        id: id,
        title: title,
        why: 'New reason',
        image: 'assets/images/japan.jpg',
        area: 'Custom area',
        rhythm: Rhythm.occasional,
        tone: Tone.none,
        obstacle: 'time',
      );
      repo.fail = true;
      await expectLater(update('New title'), throwsStateError);
      expect(c.vision(id).toJson(), before);
      repo.fail = false;
      await expectLater(update('  '), throwsArgumentError);
      await update('New title');
      expect(c.vision(id).status, VisionStatus.completed);
      expect(
        c.vision(id).completedAt?.toIso8601String(),
        before['completedAt'],
      );
      expect(c.vision(id).createdAt.toIso8601String(), before['createdAt']);
      expect(c.vision(id).area, 'Custom area');
      expect(c.vision(id).tone, Tone.none);
    },
  );
}
