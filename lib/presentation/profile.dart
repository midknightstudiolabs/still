import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import '../domain/guidance.dart';
import 'design.dart';
import 'onboarding.dart';
import 'question_flow.dart';

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
  final Set<String> roles = {};
  String priority = '', barrier = '', capacity = '';
  int step = 0;
  bool saving = false, editing = false, leaving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.data.preferences;
    final draft = p.profileDraft;
    final v = draft.isEmpty ? p.profile : UserProfile.fromJson(draft);
    roles.addAll(v.roles);
    priority = v.priority;
    barrier = v.barrier;
    capacity = v.capacity;
    step = (draft['step'] as int? ?? 0).clamp(0, 4);
  }

  UserProfile get value => UserProfile(
    roles: roles.toList(),
    priority: priority,
    barrier: barrier,
    capacity: capacity,
    saved: true,
  );
  Future<void> checkpoint(int next) async {
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.saveDraft('profile', {
        ...value.toJson(),
        'step': next,
      });
      if (mounted) {
        setState(() {
          step = next;
          saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Your answers could not be saved. Please try again. They are still here.';
        });
      }
    }
  }

  Future<void> close() async {
    await checkpoint(step);
    if (!mounted || error != null) return;
    setState(() => leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  void back() {
    if (saving) return;
    if (editing) {
      editing = false;
      checkpoint(4);
    } else if (step > 0) {
      checkpoint(step - 1);
    } else {
      close();
    }
  }

  Future<void> finish({bool clear = false}) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.saveProfile(clear ? UserProfile() : value);
      if (!mounted) return;
      setState(() => leaving = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Your preferences could not be saved. Please try again.';
        });
      }
    }
  }

  void edit(int index) {
    setState(() {
      editing = true;
      step = index;
    });
  }

  Widget options(
    Map<String, String> values,
    String current,
    ValueChanged<String> onSelect,
  ) => Column(
    children: values.entries
        .map(
          (e) => AnswerCard(
            label: e.value,
            selected: e.key == current,
            onTap: saving ? null : () => setState(() => onSelect(e.key)),
          ),
        )
        .toList(),
  );
  @override
  Widget build(BuildContext context) {
    final titles = [
      'What is part of your life right now?',
      'What would you like more room for?',
      'What tends to get in the way?',
      'What feels realistic for one small step?',
      'Does this feel like you?',
    ];
    final hints = [
      'Choose any that fit, or skip. Roles shape examples, never the goals you are allowed to choose.',
      'This is a starting point for your next vision. You can always choose another area.',
      'Think about recent situations, not a label for yourself. Each vision can have a different obstacle.',
      'Choose a starting size, not a daily commitment. Some days will be different.',
      'These optional answers tailor preset examples. No scoring, diagnosis, or AI. Stored only on this device.',
    ];
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: QuestionFlow(
        section: 'A little about you',
        step: step,
        total: 5,
        title: titles[step],
        hint: hints[step],
        busy: saving,
        error: error,
        optional: step < 4,
        onBack: back,
        onClose: close,
        button: step == 4
            ? (widget.first ? 'Continue to my vision' : 'Save my preferences')
            : editing
            ? 'Back to review'
            : 'Continue',
        onContinue: step == 4
            ? () => finish()
            : () {
                final next = editing ? 4 : step + 1;
                editing = false;
                checkpoint(next);
              },
        onSkip: step < 4
            ? () {
                final next = editing ? 4 : step + 1;
                editing = false;
                checkpoint(next);
              }
            : null,
        child: switch (step) {
          0 => Column(
            children: [
              for (final r in lifeRoles)
                AnswerCard(
                  label: r,
                  selected: roles.contains(r),
                  multiple: true,
                  onTap: saving
                      ? null
                      : () => setState(() {
                          if (!roles.add(r)) roles.remove(r);
                        }),
                ),
              const SizedBox(height: 12),
              const Text(
                'Four optional questions, then a review. You can save and close at any point.',
                style: TextStyle(height: 1.6),
              ),
            ],
          ),
          1 => options(
            {'': 'I will choose later', for (final a in areas) a: a},
            priority,
            (v) => priority = v,
          ),
          2 => options(barriers, barrier, (v) => barrier = v),
          3 => options(capacities, capacity, (v) => capacity = v),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReviewAnswer(
                'Life roles',
                roles.isEmpty ? 'Not specified' : roles.join(', '),
                () => edit(0),
              ),
              ReviewAnswer(
                'Starting area',
                priority.isEmpty ? 'Choose later' : priority,
                () => edit(1),
              ),
              ReviewAnswer(
                'Possible obstacle',
                barriers[barrier] ?? 'Not specified',
                () => edit(2),
              ),
              ReviewAnswer(
                'Time for a step',
                capacities[capacity] ?? 'Not specified',
                () => edit(3),
              ),
              Text(barrierHelp(barrier), style: const TextStyle(height: 1.6)),
              if (!widget.first)
                TextButton(
                  onPressed: saving ? null : () => finish(clear: true),
                  child: const Text('Clear these answers'),
                ),
              const Text(
                'Clearing your profile keeps existing visions and their saved plans.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        },
      ),
    );
  }
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
