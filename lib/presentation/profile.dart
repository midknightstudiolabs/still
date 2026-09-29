import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import '../domain/guidance.dart';
import 'design.dart';
import 'onboarding.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    this.first = false,
  });
  final StillController controller;
  final bool first;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final roles = {...widget.controller.data.preferences.profile.roles};
  late String priority = widget.controller.data.preferences.profile.priority;
  late String barrier = widget.controller.data.preferences.profile.barrier;
  late String capacity = widget.controller.data.preferences.profile.capacity;
  bool saving = false;

  void next() {
    if (widget.first) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              VisionWizard(controller: widget.controller, first: true),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> save({bool clear = false}) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.controller.saveProfile(
        clear
            ? UserProfile()
            : UserProfile(
                roles: roles.toList(),
                priority: priority,
                barrier: barrier,
                capacity: capacity,
                saved: true,
              ),
      );
      if (mounted) next();
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() => saving = false);
      }
    }
  }

  Widget question(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: editorial(28)),
        const SizedBox(height: 9),
        Text(body, style: const TextStyle(color: muted, height: 1.6)),
      ],
    ),
  );
  Widget choices(
    Map<String, String> options,
    String value,
    ValueChanged<String> select,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options.entries
        .map(
          (e) => ChoiceChip(
            label: Text(e.value),
            selected: value == e.key,
            onSelected: saving ? null : (_) => setState(() => select(e.key)),
          ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('A little about you')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 40),
          children: [
            const Eyebrow('Your life has its own shape'),
            const SizedBox(height: 14),
            Text('Let’s start with\nwhere you are.', style: editorial(40)),
            const SizedBox(height: 16),
            const Text(
              'Every answer is optional. These choices tailor examples and planning prompts; they do not label or assess you. Saved only in this browser or device. You can change or clear them in Settings.',
              style: TextStyle(height: 1.7, color: muted),
            ),
            if (widget.first)
              TextButton(
                onPressed: saving ? null : next,
                child: const Text('Skip for now'),
              ),
            question(
              'What is part of your life right now?',
              'Choose any that fit. Your role does not decide your goals.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lifeRoles
                  .map(
                    (r) => FilterChip(
                      label: Text(r),
                      selected: roles.contains(r),
                      onSelected: saving
                          ? null
                          : (on) => setState(() {
                              if (on) {
                                roles.add(r);
                              } else {
                                roles.remove(r);
                              }
                            }),
                    ),
                  )
                  .toList(),
            ),
            question(
              'What would you like more room for?',
              'This becomes the starting area for your next vision. Every area stays available.',
            ),
            choices(
              {'': 'I will choose later', for (final a in areas) a: a},
              priority,
              (v) => priority = v,
            ),
            question(
              'When something matters, what can get in the way?',
              'Think about recent situations. Putting something off can have different reasons; you can choose a different obstacle for each vision.',
            ),
            choices(barriers, barrier, (v) => barrier = v),
            if (barrier.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  barrierHelp(barrier),
                  style: const TextStyle(height: 1.6),
                ),
              ),
            question(
              'What feels realistic for a small step?',
              'A planning preference, not a daily commitment or a timer.',
            ),
            choices(capacities, capacity, (v) => capacity = v),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: saving ? null : () => save(),
              child: Text(
                saving
                    ? 'Saving…'
                    : widget.first
                    ? 'Continue to my vision'
                    : 'Save my preferences',
              ),
            ),
            if (!widget.first)
              TextButton(
                onPressed: saving ? null : () => save(clear: true),
                child: const Text('Clear these answers'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Clearing these answers keeps your visions, their obstacles, and your saved moves. Guidance uses preset rules, not AI.',
              style: TextStyle(fontSize: 12, color: muted, height: 1.6),
            ),
          ],
        ),
      ),
    ),
  );
}

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Why these questions')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(26),
          children: [
            Text('Research informs\nthe questions.', style: editorial(38)),
            const SizedBox(height: 18),
            const Text(
              'You choose what matters, notice an obstacle, and decide on a manageable action. Still uses preset suggestions based on those choices. It does not diagnose procrastination or infer your personality.',
              style: TextStyle(height: 1.7),
            ),
            const SizedBox(height: 22),
            const Text(
              'Personal meaning',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Self-determination theory motivates asking what you value and keeping choices optional. A job or study role is context, not a prescription for what you should want.',
              style: TextStyle(height: 1.7),
            ),
            const SelectableText(
              'Ryan & Deci (2000)\nhttps://doi.org/10.1037/0003-066X.55.1.68',
            ),
            const SizedBox(height: 22),
            const Text(
              'Obstacles without blame',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Research describes how task discomfort and short-term mood regulation can contribute to procrastination. We ask what gets in the way rather than calling you lazy or assigning a score.',
              style: TextStyle(height: 1.7),
            ),
            const SelectableText(
              'Sirois & Pychyl (2013)\nhttps://doi.org/10.1111/spc3.12011',
            ),
            const SizedBox(height: 22),
            const Text(
              'An action linked to a cue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Research on implementation intentions supports trying a specific when or if cue paired with an action. Your cue is a saved plan, not a scheduled notification.',
              style: TextStyle(height: 1.7),
            ),
            const SelectableText(
              'Gollwitzer & Sheeran (2006)\nhttps://doi.org/10.1016/S0065-2601(06)38002-1',
            ),
            const SizedBox(height: 22),
            const Text(
              'What the evidence does not establish',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'These exact questions, examples, time choices, and tone options have not been validated as an intervention. Findings do not guarantee results: a 2017 study of 177 students found no significant reduction in procrastination from its goal-setting interventions. Still is a planning tool, not treatment. Manifestation is a writing style, not a scientific claim that thoughts cause events.',
              style: TextStyle(height: 1.7),
            ),
            const SelectableText(
              'Gustavson & Miyake (2017)\nhttps://doi.org/10.1016/j.lindif.2017.01.010',
            ),
          ],
        ),
      ),
    ),
  );
}
