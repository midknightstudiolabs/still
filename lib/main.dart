import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/still_controller.dart';
import 'data/repository.dart';
import 'presentation/design.dart';
import 'presentation/home.dart';
import 'presentation/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = await SharedPreferences.getInstance();
    final controller = StillController(LocalVisionRepository(storage));
    await controller.initialize();
    runApp(StillApp(controller: controller));
  } catch (error) {
    runApp(
      MaterialApp(
        theme: stillTheme(Brightness.light),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Your space is still here.', style: editorial(36)),
                    const SizedBox(height: 20),
                    const Text(
                      'We couldn’t open the saved data. It hasn’t been replaced. Please close and reopen Still, or contact support before clearing app data.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      '$error',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StillApp extends StatelessWidget {
  const StillApp({super.key, required this.controller});
  final StillController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'Still · Keep what matters close',
      debugShowCheckedModeBanner: false,
      theme: stillTheme(Brightness.light),
      darkTheme: stillTheme(Brightness.dark),
      themeMode: switch (controller.data.preferences.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: controller.data.preferences.onboardingComplete
          ? HomeShell(controller: controller)
          : Welcome(controller: controller),
    ),
  );
}

class Welcome extends StatefulWidget {
  const Welcome({super.key, required this.controller});
  final StillController controller;
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool loading = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
            children: [
              Row(
                children: [
                  Text('still', style: editorial(42, weight: FontWeight.w600)),
                  const Spacer(),
                  const Eyebrow('A little closer'),
                ],
              ),
              const SizedBox(height: 28),
              Stack(
                children: [
                  Photo(photos.first, height: 330, radius: 120),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'For the things that feel like you.',
                          style: TextStyle(color: pine, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Some things deserve\nto stay close.',
                textAlign: TextAlign.center,
                style: editorial(43),
              ),
              const SizedBox(height: 18),
              const Text(
                'A quiet place for your visions.\nSmall moves. Real moments. Room to begin again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12, height: 1.9),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisionWizard(
                            controller: widget.controller,
                            first: true,
                          ),
                        ),
                      ),
                child: const Text('What matters to you?'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() => loading = true);
                        try {
                          await widget.controller.loadDemo();
                        } catch (e) {
                          if (mounted && context.mounted) {
                            toast(context, '$e');
                            setState(() => loading = false);
                          }
                        }
                      },
                child: Text(
                  loading
                      ? 'Opening your space…'
                      : 'Take a look around · Try the demo',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NO STREAKS. NO CATCHING UP. JUST YOU.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, letterSpacing: 1.7, color: muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
