import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/domain/models.dart';
import 'package:still/domain/guidance.dart';
import 'package:still/application/still_controller.dart';
import 'journeys_test.dart' show MemoryRepository;

void main() {
  test('Legacy saved boards load without profile, obstacle, or cue', () async {
    final repo = MemoryRepository();
    final c = StillController(repo);
    await c.initialize();
    final id = await c.createVision(
      title: 'Learn',
      why: '',
      image: '',
      area: 'Learning / Study',
      rhythm: Rhythm.weekly,
      tone: Tone.grounded,
    );
    await c.setMove(id, 'Open a book');
    final json = c.data.toJson();
    (json['preferences'] as Map).remove('profile');
    for (final v in json['visions']) {
      (v as Map).remove('obstacle');
    }
    for (final m in json['moves']) {
      (m as Map).remove('cue');
    }
    repo.raw = jsonEncode(json);
    final reopened = StillController(repo);
    await reopened.initialize();
    expect(reopened.data.preferences.profile.roles, isEmpty);
    expect(reopened.active.single.obstacle, '');
    expect(reopened.move(reopened.active.single)!.cue, '');
    expect(reopened.active.single.title, 'Learn');
  });
  test(
    'Profile, per vision barrier and cue survive reload; clearing profile keeps board',
    () async {
      final repo = MemoryRepository();
      final c = StillController(repo);
      await c.initialize();
      await c.saveProfile(
        UserProfile(
          roles: ['Student', 'Working professional'],
          priority: 'Relationships',
          barrier: 'distraction',
          capacity: 'small',
          saved: true,
        ),
      );
      final id = await c.createVision(
        title: 'Connect',
        why: 'My choice',
        image: '',
        area: 'Relationships',
        obstacle: 'unclear',
        rhythm: Rhythm.weekly,
        tone: Tone.none,
      );
      await c.setMove(
        id,
        'Ask about Saturday',
        cue: 'After breakfast',
        obstacle: 'resources',
      );
      final reopened = StillController(repo);
      await reopened.initialize();
      expect(reopened.data.preferences.profile.roles.length, 2);
      expect(reopened.data.preferences.profile.priority, 'Relationships');
      expect(reopened.data.preferences.profile.barrier, 'distraction');
      expect(reopened.active.single.obstacle, 'resources');
      expect(reopened.move(reopened.active.single)!.cue, 'After breakfast');
      await reopened.saveProfile(UserProfile());
      expect(reopened.active.single.obstacle, 'resources');
      expect(reopened.move(reopened.active.single)!.text, 'Ask about Saturday');
      expect(reopened.data.preferences.tone, Tone.none);
      await reopened.completeMove(id);
      expect(reopened.data.moves.single.cue, 'After breakfast');
      expect(reopened.proofs(id).single.note, 'Ask about Saturday');
    },
  );
  test('Failed profile or plan saves do not change visible data', () async {
    final repo = MemoryRepository();
    final c = StillController(repo);
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
    await c.setMove(id, 'Original');
    repo.fail = true;
    await expectLater(
      c.saveProfile(UserProfile(roles: ['Student'], saved: true)),
      throwsStateError,
    );
    await expectLater(
      c.setMove(id, 'Changed', cue: 'Later', obstacle: 'perfection'),
      throwsStateError,
    );
    expect(c.data.preferences.profile.saved, isFalse);
    expect(c.vision(id).obstacle, 'unclear');
    expect(c.move(c.vision(id))!.text, 'Original');
  });
  test('Guidance respects explicit obstacles rather than role stereotypes', () {
    final p = UserProfile(
      roles: ['Student', 'Working professional'],
      priority: 'Travel',
    );
    expect(visionExample(p), contains('alongside work'));
    expect(p.priority, 'Travel');
    expect(suggestedMove('Travel', 'resources'), contains('resource'));
    expect(
      suggestedMove('Learning / Study', 'meaning'),
      contains('still want'),
    );
    expect(toneDescription(Tone.manifestation), contains('does not guarantee'));
    expect(capacityHelp('variable'), contains('busy day'));
  });
}
