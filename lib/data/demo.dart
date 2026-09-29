import '../domain/models.dart';

AppData demoData(DateTime now) {
  final data = AppData();
  data.preferences
    ..onboardingComplete = true
    ..demo = true
    ..lastAppOpen = now
    ..lastReview = now.subtract(const Duration(days: 8));
  final items = [
    [
      'japan',
      'Japan with Mom & Dad',
      'Do this while we still can.',
      'Travel',
      'Check passport expiry.',
    ],
    [
      'business',
      'Build my own business',
      'I want more control over my time.',
      'Career / Business',
      'Send one proposal.',
    ],
    [
      'calm',
      'A calmer life',
      'I don’t want everything to feel rushed.',
      'How I Want Life to Feel',
      'Keep Sunday morning clear.',
    ],
  ];
  for (var i = 0; i < items.length; i++) {
    final x = items[i];
    data.visions.add(
      Vision(
        id: x[0],
        title: x[1],
        why: x[2],
        area: x[3],
        imagePath: 'assets/images/${x[0]}.jpg',
        rhythm: i == 2 ? Rhythm.occasional : Rhythm.weekly,
        createdAt: now.subtract(Duration(days: 28 - i)),
        nextMoveId: 'move-${x[0]}',
      ),
    );
    data.moves.add(
      NextMove(
        id: 'move-${x[0]}',
        visionId: x[0],
        text: x[4],
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    );
  }
  data.proofs.add(
    Proof(
      id: 'passport',
      visionId: 'japan',
      note: 'Renewed Mom’s passport. One little thing closer.',
      createdAt: now.subtract(const Duration(days: 6)),
      proofType: ProofType.action,
    ),
  );
  data.proofs.add(
    Proof(
      id: 'conversation',
      visionId: 'japan',
      note:
          'Asked Dad where he would go first. Kyoto, without a second thought.',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  );
  return data;
}
