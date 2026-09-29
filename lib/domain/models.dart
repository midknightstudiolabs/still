enum VisionStatus { active, later, completed, letGo }

enum Rhythm { daily, weekly, occasional }

enum Tone { grounded, motivational, manifestation, none }

enum MoveStatus { current, completed, replaced }

enum ProofType { note, photo, action, milestone }

enum CheckResponse { stillMine, slowDown, later, letGo }

enum ProgressMeasure { milestones, money, value }

// Store hundredths as integers so deposits such as 0.10 + 0.20 are exact.
int? parseValue(String text) {
  final raw = text.trim();
  if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(raw)) return null;
  final parts = raw.replaceFirst('-', '').split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null || whole > 1000000000) return null;
  final result =
      whole * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return raw.startsWith('-') ? -result : result;
}

String valueText(int value) {
  final raw = value.abs();
  final fraction = raw % 100;
  return '${value < 0 ? '-' : ''}${raw ~/ 100}${fraction == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}'}';
}

class ValueEntry {
  ValueEntry({
    required this.id,
    required this.amount,
    required this.when,
    this.note = '',
  });
  final String id, note;
  final int amount;
  final DateTime when;
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'when': stamp(when),
    'note': note,
  };
  factory ValueEntry.fromJson(Map<String, dynamic> j) => ValueEntry(
    id: j['id'],
    amount: j['amount'],
    when: date(j['when']),
    note: j['note'] ?? '',
  );
}

DateTime date(dynamic value) => DateTime.parse(value as String);
String? stamp(DateTime? value) => value?.toIso8601String();

class Milestone {
  Milestone({required this.id, required this.title, this.completedAt});
  final String id;
  String title;
  DateTime? completedAt;
  bool get done => completedAt != null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completedAt': stamp(completedAt),
  };
  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
    id: j['id'],
    title: j['title'],
    completedAt: j['completedAt'] == null ? null : date(j['completedAt']),
  );
}

class Vision {
  Vision({
    required this.id,
    required this.title,
    this.why = '',
    this.imagePath = 'assets/images/japan.jpg',
    this.area = 'Travel',
    this.status = VisionStatus.active,
    this.rhythm = Rhythm.weekly,
    this.tone = Tone.grounded,
    required this.createdAt,
    DateTime? updatedAt,
    this.completedAt,
    this.nextMoveId,
    this.letGoReason,
    this.obstacle = '',
    this.targetDate,
    List<Milestone>? milestones,
    this.measure = ProgressMeasure.milestones,
    this.valueTarget = 0,
    this.valueUnit = '',
    List<ValueEntry>? entries,
  }) : updatedAt = updatedAt ?? createdAt,
       milestones = milestones ?? [],
       entries = entries ?? [];
  final String id;
  String title, why, imagePath, area;
  VisionStatus status;
  Rhythm rhythm;
  Tone tone;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? completedAt, targetDate;
  String? nextMoveId, letGoReason;
  String obstacle;
  List<Milestone> milestones;
  ProgressMeasure measure;
  int valueTarget;
  String valueUnit;
  List<ValueEntry> entries;
  int get valueTotal => entries.fold(0, (sum, e) => sum + e.amount);
  double? get progressRatio => measure == ProgressMeasure.milestones
      ? (milestones.isEmpty ? null : milestonesDone / milestones.length)
      : (valueTarget <= 0 ? null : (valueTotal / valueTarget).clamp(0, 1));
  int get milestonesDone => milestones.where((m) => m.done).length;
  int? get progressPercent =>
      progressRatio == null ? null : (progressRatio! * 100).floor();
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'why': why,
    'imagePath': imagePath,
    'area': area,
    'status': status.name,
    'rhythm': rhythm.name,
    'tone': tone.name,
    'createdAt': stamp(createdAt),
    'updatedAt': stamp(updatedAt),
    'completedAt': stamp(completedAt),
    'nextMoveId': nextMoveId,
    'letGoReason': letGoReason,
    'obstacle': obstacle,
    'targetDate': stamp(targetDate),
    'milestones': milestones.map((m) => m.toJson()).toList(),
    'measure': measure.name,
    'valueTarget': valueTarget,
    'valueUnit': valueUnit,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
  factory Vision.fromJson(Map<String, dynamic> j) => Vision(
    id: j['id'],
    title: j['title'],
    why: j['why'],
    imagePath: j['imagePath'],
    area: j['area'],
    status: VisionStatus.values.byName(j['status']),
    rhythm: Rhythm.values.byName(j['rhythm']),
    tone: Tone.values.byName(j['tone']),
    createdAt: date(j['createdAt']),
    updatedAt: date(j['updatedAt']),
    completedAt: j['completedAt'] == null ? null : date(j['completedAt']),
    nextMoveId: j['nextMoveId'],
    letGoReason: j['letGoReason'],
    obstacle: j['obstacle'] ?? '',
    targetDate: j['targetDate'] == null ? null : date(j['targetDate']),
    milestones: (j['milestones'] as List? ?? [])
        .map((m) => Milestone.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    measure: ProgressMeasure.values.byName(j['measure'] ?? 'milestones'),
    valueTarget: j['valueTarget'] ?? 0,
    valueUnit: j['valueUnit'] ?? '',
    entries: (j['entries'] as List? ?? [])
        .map((e) => ValueEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

class NextMove {
  NextMove({
    required this.id,
    required this.visionId,
    required this.text,
    required this.createdAt,
    this.completedAt,
    this.status = MoveStatus.current,
    this.cue = '',
  });
  final String id, visionId, text;
  final String cue;
  final DateTime createdAt;
  DateTime? completedAt;
  MoveStatus status;
  Map<String, dynamic> toJson() => {
    'id': id,
    'visionId': visionId,
    'text': text,
    'cue': cue,
    'createdAt': stamp(createdAt),
    'completedAt': stamp(completedAt),
    'status': status.name,
  };
  factory NextMove.fromJson(Map<String, dynamic> j) => NextMove(
    id: j['id'],
    visionId: j['visionId'],
    text: j['text'],
    cue: j['cue'] ?? '',
    createdAt: date(j['createdAt']),
    completedAt: j['completedAt'] == null ? null : date(j['completedAt']),
    status: MoveStatus.values.byName(j['status']),
  );
}

class Proof {
  Proof({
    required this.id,
    required this.visionId,
    this.note = '',
    this.imagePath,
    required this.createdAt,
    this.proofType = ProofType.note,
  });
  final String id, visionId, note;
  final String? imagePath;
  final DateTime createdAt;
  final ProofType proofType;
  Map<String, dynamic> toJson() => {
    'id': id,
    'visionId': visionId,
    'note': note,
    'imagePath': imagePath,
    'createdAt': stamp(createdAt),
    'proofType': proofType.name,
  };
  factory Proof.fromJson(Map<String, dynamic> j) => Proof(
    id: j['id'],
    visionId: j['visionId'],
    note: j['note'],
    imagePath: j['imagePath'],
    createdAt: date(j['createdAt']),
    proofType: ProofType.values.byName(j['proofType']),
  );
}

class CheckIn {
  CheckIn({
    required this.id,
    required this.visionId,
    required this.date,
    required this.response,
  });
  final String id, visionId;
  final DateTime date;
  final CheckResponse response;
  Map<String, dynamic> toJson() => {
    'id': id,
    'visionId': visionId,
    'date': stamp(date),
    'response': response.name,
  };
  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
    id: j['id'],
    visionId: j['visionId'],
    date: DateTime.parse(j['date']),
    response: CheckResponse.values.byName(j['response']),
  );
}

class UserPreferences {
  Map<String, dynamic> visionDraft = {}, profileDraft = {};
  Map<String, String> restDays = {};
  UserProfile profile = UserProfile();
  Tone tone = Tone.grounded;
  String theme = 'system';
  DateTime? lastAppOpen, lastReview;
  bool onboardingComplete = false, notificationsEnabled = false, demo = false;
  Map<String, dynamic> toJson() => {
    'tone': tone.name,
    'theme': theme,
    'lastAppOpen': stamp(lastAppOpen),
    'lastReview': stamp(lastReview),
    'onboardingComplete': onboardingComplete,
    'notificationsEnabled': notificationsEnabled,
    'demo': demo,
    'profile': profile.toJson(),
    'visionDraft': visionDraft,
    'profileDraft': profileDraft,
    'restDays': restDays,
  };
  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences()
    ..tone = Tone.values.byName(j['tone'])
    ..theme = j['theme']
    ..lastAppOpen = j['lastAppOpen'] == null ? null : date(j['lastAppOpen'])
    ..lastReview = j['lastReview'] == null ? null : date(j['lastReview'])
    ..onboardingComplete = j['onboardingComplete']
    ..notificationsEnabled = j['notificationsEnabled'] ?? false
    ..demo = j['demo'] ?? false
    ..profile = UserProfile.fromJson(j['profile'] ?? <String, dynamic>{})
    ..visionDraft = Map<String, dynamic>.from(j['visionDraft'] ?? {})
    ..profileDraft = Map<String, dynamic>.from(j['profileDraft'] ?? {})
    ..restDays = Map<String, String>.from(j['restDays'] ?? {});
  UserPreferences();
}

class UserProfile {
  UserProfile({
    List<String>? roles,
    this.priority = '',
    this.barrier = '',
    this.capacity = '',
    this.saved = false,
  }) : roles = roles ?? [];
  final List<String> roles;
  final String priority, barrier, capacity;
  final bool saved;
  Map<String, dynamic> toJson() => {
    'roles': roles,
    'priority': priority,
    'barrier': barrier,
    'capacity': capacity,
    'saved': saved,
  };
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    roles: List<String>.from(j['roles'] ?? []),
    priority: j['priority'] ?? '',
    barrier: j['barrier'] ?? '',
    capacity: j['capacity'] ?? '',
    saved: j['saved'] ?? false,
  );
}

class AppData {
  AppData({
    List<Vision>? visions,
    List<NextMove>? moves,
    List<Proof>? proofs,
    List<CheckIn>? checkIns,
    UserPreferences? preferences,
  }) : visions = visions ?? [],
       moves = moves ?? [],
       proofs = proofs ?? [],
       checkIns = checkIns ?? [],
       preferences = preferences ?? UserPreferences();
  final List<Vision> visions;
  final List<NextMove> moves;
  final List<Proof> proofs;
  final List<CheckIn> checkIns;
  final UserPreferences preferences;
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'visions': visions.map((v) => v.toJson()).toList(),
    'moves': moves.map((v) => v.toJson()).toList(),
    'proofs': proofs.map((v) => v.toJson()).toList(),
    'checkIns': checkIns.map((v) => v.toJson()).toList(),
    'preferences': preferences.toJson(),
  };
  factory AppData.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Unsupported data version');
    }
    return AppData(
      visions: (j['visions'] as List).map((v) => Vision.fromJson(v)).toList(),
      moves: (j['moves'] as List).map((v) => NextMove.fromJson(v)).toList(),
      proofs: (j['proofs'] as List).map((v) => Proof.fromJson(v)).toList(),
      checkIns: (j['checkIns'] as List)
          .map((v) => CheckIn.fromJson(v))
          .toList(),
      preferences: UserPreferences.fromJson(j['preferences']),
    );
  }
}

/// Read-only projection for a future native widget adapter.
class WidgetVision {
  const WidgetVision(this.id, this.title, this.why, this.imagePath);
  final String id, title, why, imagePath;
  Map<String, String> toJson() => {
    'id': id,
    'title': title,
    'why': why,
    'imagePath': imagePath,
  };
}
