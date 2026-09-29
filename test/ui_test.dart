import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:still/main.dart';
import 'package:still/application/still_controller.dart';

import 'journeys_test.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Use the actual bundled fonts instead of the test-only Ahem font.
    final sans = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    final serif = FontLoader('Cormorant')
      ..addFont(rootBundle.load('assets/fonts/CormorantGaramond.ttf'));
    await Future.wait([sans.load(), serif.load()]);
  });
  testWidgets('Welcome to first vision and Next Move', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = StillController(MemoryRepository());
    await c.initialize();
    await tester.pumpWidget(StillApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('What matters to you?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Take my parents to Japan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'While we still can.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep this close'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Check passport expiry.');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep this move'));
    await tester.pumpAndSettle();
    expect(c.active.single.title, 'Take my parents to Japan');
    expect(c.move(c.active.single)!.text, 'Check passport expiry.');
    expect(find.text('Keep this alive.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Demo Today is calm; Not today preserves the move', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = StillController(MemoryRepository());
    await c.initialize();
    await c.loadDemo();
    await tester.pumpWidget(StillApp(controller: c));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Not today'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Not today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not today'));
    await tester.pumpAndSettle();
    expect(find.text('It can wait. This is still yours.'), findsOneWidget);
    expect(c.data.moves.where((m) => m.completedAt != null), isEmpty);
    expect(c.data.proofs.length, 2);
    expect(tester.takeException(), isNull);
  });
}
