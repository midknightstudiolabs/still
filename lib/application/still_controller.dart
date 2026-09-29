import 'package:flutter/foundation.dart';

import '../data/demo.dart';
import '../data/repository.dart';
import '../domain/models.dart';

class ActiveLimit implements Exception {
  const ActiveLimit();
  @override
  String toString() =>
      'Make a little room. Move one vision to Later to keep this one close.';
}

class StillController extends ChangeNotifier {
  StillController(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final VisionRepository repository;
  final DateTime Function() clock;
  AppData data = AppData();
  bool needsComeback = false;
  Future<void> _queue = Future.value();
  int _sequence = 0;
  String _id() => '${clock().microsecondsSinceEpoch}-${_sequence++}';
  List<Vision> get active =>
      data.visions.where((v) => v.status == VisionStatus.active).toList();
  List<WidgetVision> get widgetSnapshot => active
      .map((v) => WidgetVision(v.id, v.title, v.why, v.imagePath))
      .toList();
  Vision vision(String id) => data.visions.firstWhere((v) => v.id == id);
  NextMove? move(Vision v) => data.moves
      .where((m) => m.id == v.nextMoveId && m.status == MoveStatus.current)
      .firstOrNull;
  List<Proof> proofs(String id) =>
      data.proofs.where((p) => p.visionId == id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  bool get reviewDue =>
      active.isNotEmpty &&
      (data.preferences.lastReview == null ||
          clock().difference(data.preferences.lastReview!).inDays >= 7);
  List<Vision> get surfaced {
    final list = active;
    // Weight the initial focus, but keep every active vision within one swipe.
    final ticket = clock().difference(DateTime(2020)).inDays % 10;
    list.sort((a, b) => _priority(b, ticket).compareTo(_priority(a, ticket)));
    return list;
  }

  int _priority(Vision v, int ticket) => switch (v.rhythm) {
    Rhythm.daily => 3,
    Rhythm.weekly => ticket < 7 ? 4 : 2,
    Rhythm.occasional => ticket == 9 ? 5 : 1,
  };
  Future<void> initialize() async {
    data = await repository.load();
    final last = data.preferences.lastAppOpen;
    needsComeback =
        last != null &&
        clock().difference(last).inDays >= 14 &&
        active.isNotEmpty;
    // Preserve the old visit until the return review is finished or postponed.
    if (!needsComeback) {
      await transact((d) => d.preferences.lastAppOpen = clock());
    }
    notifyListeners();
  }

  Future<void> transact(void Function(AppData) change) {
    final result = _queue.then((_) async {
      final draft = AppData.fromJson(data.toJson());
      change(draft);
      await repository.save(draft);
      data = draft;
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> loadDemo() async {
    await _queue;
    final draft = demoData(clock());
    await repository.save(draft);
    data = draft;
    needsComeback = false;
    notifyListeners();
  }

  Future<String> createVision({
    required String title,
    required String why,
    required String image,
    required String area,
    required Rhythm rhythm,
    required Tone tone,
    String? replaceActiveId,
    bool saveForLater = false,
    String obstacle = '',
  }) async {
    final id = _id();
    await transact((d) {
      if (title.trim().isEmpty) throw ArgumentError('Give your vision a name.');
      if (replaceActiveId != null) {
        final old = d.visions.firstWhere((v) => v.id == replaceActiveId);
        old
          ..status = VisionStatus.later
          ..updatedAt = clock();
      }
      if (!saveForLater &&
          d.visions.where((v) => v.status == VisionStatus.active).length >= 3) {
        throw const ActiveLimit();
      }
      d.visions.add(
        Vision(
          id: id,
          title: title.trim(),
          why: why.trim(),
          imagePath: image,
          area: area,
          rhythm: rhythm,
          tone: tone,
          obstacle: obstacle,
          createdAt: clock(),
          status: saveForLater ? VisionStatus.later : VisionStatus.active,
        ),
      );
      d.preferences
        ..visionDraft = {}
        ..onboardingComplete = true
        ..tone = tone;
    });
    return id;
  }

  Future<void> setMove(
    String visionId,
    String text, {
    String cue = '',
    String? obstacle,
  }) => transact((d) {
    if (text.trim().isEmpty) throw ArgumentError('What’s one small move?');
    final v = d.visions.firstWhere((v) => v.id == visionId);
    if (obstacle != null) v.obstacle = obstacle;
    for (final m in d.moves.where(
      (m) => m.visionId == visionId && m.status == MoveStatus.current,
    )) {
      m.status = MoveStatus.replaced;
    }
    final m = NextMove(
      id: _id(),
      visionId: visionId,
      text: text.trim(),
      cue: cue.trim(),
      createdAt: clock(),
    );
    d.moves.add(m);
    v
      ..nextMoveId = m.id
      ..updatedAt = clock();
  });
  Future<void> completeMove(String visionId) => transact((d) {
    final v = d.visions.firstWhere((v) => v.id == visionId);
    final m = d.moves
        .where((m) => m.id == v.nextMoveId && m.status == MoveStatus.current)
        .firstOrNull;
    if (m == null) return;
    m
      ..status = MoveStatus.completed
      ..completedAt = clock();
    d.proofs.add(
      Proof(
        id: _id(),
        visionId: visionId,
        note: m.text,
        createdAt: clock(),
        proofType: ProofType.action,
      ),
    );
    v
      ..nextMoveId = null
      ..updatedAt = clock();
  });
  Future<void> addProof(
    String visionId,
    String note, {
    String? image,
    DateTime? when,
    bool complete = false,
  }) => transact((d) {
    if (note.trim().isEmpty && image == null && !complete) {
      throw ArgumentError('Add a note or a photo.');
    }
    final v = d.visions.firstWhere((v) => v.id == visionId);
    if (note.trim().isNotEmpty || image != null) {
      d.proofs.add(
        Proof(
          id: _id(),
          visionId: visionId,
          note: note.trim(),
          imagePath: image,
          createdAt: when ?? clock(),
          proofType: complete
              ? ProofType.milestone
              : image != null
              ? ProofType.photo
              : ProofType.note,
        ),
      );
    }
    if (complete) {
      v
        ..status = VisionStatus.completed
        ..completedAt = when ?? clock();
    }
    v.updatedAt = clock();
  });
  Future<void> setStatus(
    String id,
    VisionStatus status, {
    String? reason,
    String? replaceActiveId,
  }) => transact((d) {
    final v = d.visions.firstWhere((v) => v.id == id);
    if (replaceActiveId != null && replaceActiveId != id) {
      d.visions.firstWhere((v) => v.id == replaceActiveId)
        ..status = VisionStatus.later
        ..updatedAt = clock();
    }
    if (status == VisionStatus.active &&
        v.status != VisionStatus.active &&
        d.visions.where((v) => v.status == VisionStatus.active).length >= 3) {
      throw const ActiveLimit();
    }
    v
      ..status = status
      ..letGoReason = reason
      ..updatedAt = clock();
    if (status != VisionStatus.completed) v.completedAt = null;
  });
  Future<void> checkIn(String id, CheckResponse response, {String? reason}) =>
      transact((d) {
        final v = d.visions.firstWhere((v) => v.id == id);
        switch (response) {
          case CheckResponse.stillMine:
            break;
          case CheckResponse.slowDown:
            v.rhythm = v.rhythm == Rhythm.daily
                ? Rhythm.weekly
                : Rhythm.occasional;
          case CheckResponse.later:
            v.status = VisionStatus.later;
          case CheckResponse.letGo:
            v
              ..status = VisionStatus.letGo
              ..letGoReason = reason;
        }
        v.updatedAt = clock();
        d.checkIns.add(
          CheckIn(id: _id(), visionId: id, date: clock(), response: response),
        );
      });
  Future<void> finishReview({bool postponed = false}) async {
    await transact((d) {
      d.preferences.lastAppOpen = clock();
      if (!postponed) d.preferences.lastReview = clock();
    });
    needsComeback = false;
    notifyListeners();
  }

  Future<void> preferences({Tone? tone, String? theme}) => transact((d) {
    if (tone != null) {
      d.preferences.tone = tone;
      for (final v in d.visions) {
        v.tone = tone;
      }
    }
    if (theme != null) d.preferences.theme = theme;
  });
  Future<void> saveProfile(UserProfile profile) => transact((d) {
    d.preferences.profile = UserProfile.fromJson(profile.toJson());
    d.preferences.profileDraft = {};
  });
  Future<void> saveDraft(String kind, Map<String, dynamic> draft) =>
      transact((d) {
        final copy = Map<String, dynamic>.from(draft);
        if (kind == 'vision') {
          d.preferences.visionDraft = copy;
        } else if (kind == 'profile') {
          d.preferences.profileDraft = copy;
        } else {
          throw ArgumentError('Unknown draft');
        }
      });
  String get todayKey => '${clock().year}-${clock().month}-${clock().day}';
  bool isResting(String id) => data.preferences.restDays[id] == todayKey;
  Future<void> restToday(String id, {bool undo = false}) => transact((d) {
    d.preferences.restDays.removeWhere((_, day) => day != todayKey);
    if (undo) {
      d.preferences.restDays.remove(id);
    } else {
      d.preferences.restDays[id] = todayKey;
    }
  });
  Future<void> simulateReturn() async {
    await transact(
      (d) => d.preferences.lastAppOpen = clock().subtract(
        const Duration(days: 15),
      ),
    );
    needsComeback = active.isNotEmpty;
    notifyListeners();
  }

  Future<void> reset() async {
    await _queue;
    final empty = AppData();
    await repository.save(empty);
    data = empty;
    needsComeback = false;
    notifyListeners();
  }
}
