import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:still/application/still_controller.dart';
import 'package:still/data/repository.dart';
import 'package:still/domain/models.dart';

class MemoryRepository implements VisionRepository {
  String? raw;
  bool fail = false;
  @override
  Future<AppData> load() async =>
      raw == null ? AppData() : AppData.fromJson(jsonDecode(raw!));
  @override
  Future<void> save(AppData data) async {
    if (fail) throw StateError('Disk full');
    raw = jsonEncode(data.toJson());
  }
}

void main() {
  late MemoryRepository repo;
  late StillController c;
  var now = DateTime(2026, 9, 29, 12);
  Future<String> create([String name = 'Japan with Mom & Dad']) =>
      c.createVision(
        title: name,
        why: 'Do this while we still can.',
        image: 'assets/images/japan.jpg',
        area: 'Travel',
        rhythm: Rhythm.weekly,
        tone: Tone.grounded,
      );
  setUp(() async {
    now = DateTime(2026, 9, 29, 12);
    repo = MemoryRepository();
    c = StillController(repo, clock: () => now);
    await c.initialize();
  });

  test('First vision completes onboarding and survives reload', () async {
    final id = await create();
    expect(c.active.single.id, id);
    expect(c.data.preferences.onboardingComplete, isTrue);
    final reopened = StillController(repo, clock: () => now);
    await reopened.initialize();
    expect(reopened.active.single.title, 'Japan with Mom & Dad');
    expect(reopened.active.single.why, 'Do this while we still can.');
  });
  test('One Next Move, replacement history, completion is idempotent and becomes proof', () async {
    final id = await create();
    await c.setMove(id, 'Research flights');
    await c.setMove(id, 'Check passport expiry.');
    expect(c.data.moves.where((m) => m.status == MoveStatus.current).length, 1);
    expect(c.data.moves.first.status, MoveStatus.replaced);
    await c.completeMove(id);
    await c.completeMove(id);
    expect(c.move(c.vision(id)), isNull);
    expect(c.data.moves.last.completedAt, now);
    expect(c.proofs(id).single.note, 'Check passport expiry.');
    await c.setMove(id, 'Save ₱1,000');
    expect(c.data.moves.length, 3);
  });
  test('Note and photo proof preserve the chosen date and vision', () async {
    final id = await create();
    final when = DateTime(2026, 9, 20);
    await c.addProof(
      id,
      'Bought tickets',
      image: 'data:image/jpeg;base64,aGVsbG8=',
      when: when,
    );
    final stored = await repo.load();
    expect(stored.proofs.single.visionId, id);
    expect(stored.proofs.single.createdAt, when);
    expect(stored.proofs.single.imagePath, isNotNull);
    await expectLater(c.addProof(id, ''), throwsArgumentError);
  });
  test(
    'Fourth active is rejected atomically; moving one to Later makes room',
    () async {
      final first = await create();
      await create('Business');
      await create('Calm');
      await expectLater(create('Home'), throwsA(isA<ActiveLimit>()));
      expect(c.data.visions.length, 3);
      await c.createVision(
        title: 'Home',
        why: '',
        image: 'assets/images/calm.jpg',
        area: 'Home',
        rhythm: Rhythm.occasional,
        tone: Tone.grounded,
        replaceActiveId: first,
      );
      expect(c.active.length, 3);
      expect(c.vision(first).status, VisionStatus.later);
      await expectLater(
        c.setStatus(first, VisionStatus.active),
        throwsA(isA<ActiveLimit>()),
      );
    },
  );
  test('Unlimited Later visions do not use active slots', () async {
    for (var i = 0; i < 5; i++) {
      await c.createVision(
        title: 'Later $i',
        why: '',
        image: 'assets/images/calm.jpg',
        area: 'Home',
        rhythm: Rhythm.weekly,
        tone: Tone.grounded,
        saveForLater: true,
      );
    }
    expect(c.active, isEmpty);
    expect(c.data.visions.length, 5);
  });
  test('Weekly check-in keeps, slows, pauses, and gently lets go', () async {
    final id = await create();
    expect(c.reviewDue, isTrue);
    await c.checkIn(id, CheckResponse.stillMine);
    await c.setMove(id, 'Ask Mom about dates');
    await c.checkIn(id, CheckResponse.slowDown);
    expect(c.vision(id).rhythm, Rhythm.occasional);
    await c.checkIn(id, CheckResponse.later);
    expect(c.active, isEmpty);
    await c.setStatus(id, VisionStatus.active);
    await c.checkIn(id, CheckResponse.letGo, reason: 'Life changed');
    expect(c.vision(id).status, VisionStatus.letGo);
    expect(c.vision(id).letGoReason, 'Life changed');
    expect(c.data.checkIns.length, 4);
    expect(c.move(c.vision(id))!.text, 'Ask Mom about dates');
    await c.finishReview();
    expect(c.reviewDue, isFalse);
  });
  test('Review returns after a week, not on every visit', () async {
    await create();
    await c.finishReview();
    now = now.add(const Duration(days: 6));
    expect(c.reviewDue, isFalse);
    now = now.add(const Duration(days: 1));
    expect(c.reviewDue, isTrue);
  });
  test(
    'It Happened keeps milestone, date, original image and photo for memories',
    () async {
      final id = await create();
      await c.addProof(
        id,
        'We made it to Kyoto',
        image: 'data:image/jpeg;base64,aGVsbG8=',
        complete: true,
      );
      expect(c.vision(id).status, VisionStatus.completed);
      expect(c.active, isEmpty);
      expect(c.vision(id).completedAt, now);
      expect(c.vision(id).imagePath, 'assets/images/japan.jpg');
      expect(c.proofs(id).single.proofType, ProofType.milestone);
    },
  );
  test(
    '14-day return is gentle and survives restart until acknowledged',
    () async {
      final id = await create();
      await c.setMove(id, 'Check passport');
      now = now.add(const Duration(days: 14));
      final back = StillController(repo, clock: () => now);
      await back.initialize();
      expect(back.needsComeback, isTrue);
      expect(back.move(back.vision(id))!.text, 'Check passport');
      final interrupted = StillController(repo, clock: () => now);
      await interrupted.initialize();
      expect(interrupted.needsComeback, isTrue);
      await interrupted.finishReview();
      expect(interrupted.needsComeback, isFalse);
      final nextVisit = StillController(repo, clock: () => now);
      await nextVisit.initialize();
      expect(nextVisit.needsComeback, isFalse);
    },
  );
  test('Grounded to Manifestation and No Quotes are persisted', () async {
    final id = await create();
    await c.preferences(tone: Tone.manifestation, theme: 'dark');
    final stored = await repo.load();
    expect(stored.preferences.tone, Tone.manifestation);
    expect(stored.visions.single.tone, Tone.manifestation);
    expect(stored.preferences.theme, 'dark');
    await c.preferences(tone: Tone.none);
    expect(c.vision(id).tone, Tone.none);
  });
  test('Failed persistence cannot partially mutate visible state', () async {
    final id = await create();
    repo.fail = true;
    await expectLater(c.setStatus(id, VisionStatus.later), throwsStateError);
    expect(c.vision(id).status, VisionStatus.active);
    repo.fail = false;
    await c.setStatus(id, VisionStatus.later);
    expect(c.vision(id).status, VisionStatus.later);
  });
  test(
    'Concurrent creation still respects the three-vision invariant',
    () async {
      final results = await Future.wait(
        List.generate(4, (i) async {
          try {
            await create('Vision $i');
            return true;
          } on ActiveLimit {
            return false;
          }
        }),
      );
      expect(results.where((v) => v).length, 3);
      expect(c.active.length, 3);
    },
  );
  test('Local repository roundtrip and invalid data protection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = LocalVisionRepository(prefs);
    await create();
    await local.save(c.data);
    expect((await local.load()).visions.single.title, 'Japan with Mom & Dad');
    await prefs.setString(LocalVisionRepository.key, '{broken');
    await expectLater(local.load(), throwsFormatException);
    expect(prefs.getString(LocalVisionRepository.key), '{broken');
  });
  test(
    'Demo, widget projection, and reset contain only appropriate data',
    () async {
      await c.loadDemo();
      expect(c.active.length, 3);
      expect(c.data.proofs.length, 2);
      expect(c.widgetSnapshot.length, 3);
      expect(c.widgetSnapshot.first.toJson().containsKey('nextMove'), isFalse);
      await c.reset();
      expect(c.data.visions, isEmpty);
      expect(c.data.proofs, isEmpty);
      expect(c.data.preferences.onboardingComplete, isFalse);
    },
  );
}
