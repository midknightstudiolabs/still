import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import '../domain/guidance.dart';
import 'design.dart';
import 'editors.dart';
import 'question_flow.dart';

class VisionWizard extends StatefulWidget {
  const VisionWizard({super.key, required this.controller, this.first = false});
  final StillController controller;
  final bool first;
  @override
  State<VisionWizard> createState() => _VisionWizardState();
}

class _VisionWizardState extends State<VisionWizard> {
  int step = 0;
  String area = 'Travel', image = photos.first, obstacle = '';
  final customArea = TextEditingController(),
      title = TextEditingController(),
      why = TextEditingController();
  Rhythm rhythm = Rhythm.weekly;
  Tone tone = Tone.grounded;
  bool saving = false, editing = false, leaving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.data.preferences,
        d = widget.controller.data.preferences.visionDraft;
    area =
        d['area'] as String? ??
        (p.profile.priority.isEmpty ? 'Travel' : p.profile.priority);
    image = d['image'] as String? ?? photos.first;
    obstacle = d['obstacle'] as String? ?? p.profile.barrier;
    title.text = d['title'] as String? ?? '';
    why.text = d['why'] as String? ?? '';
    customArea.text = d['customArea'] as String? ?? '';
    rhythm = Rhythm.values.firstWhere(
      (r) => r.name == d['rhythm'],
      orElse: () => Rhythm.weekly,
    );
    tone = Tone.values.firstWhere(
      (t) => t.name == d['tone'],
      orElse: () => p.tone,
    );
    step = (d['step'] as int? ?? 0).clamp(0, 7);
  }

  @override
  void dispose() {
    customArea.dispose();
    title.dispose();
    why.dispose();
    super.dispose();
  }

  Map<String, dynamic> draft(int next) => {
    'step': next,
    'area': area,
    'image': image,
    'obstacle': obstacle,
    'title': title.text,
    'why': why.text,
    'customArea': customArea.text,
    'rhythm': rhythm.name,
    'tone': tone.name,
  };
  Future<void> checkpoint(int next) async {
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.saveDraft('vision', draft(next));
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
              'We could not save your progress. Your answers are still here. Please try again.';
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
      checkpoint(7);
    } else if (step > 0) {
      checkpoint(step - 1);
    } else {
      close();
    }
  }

  void advance() {
    if (step == 1 && title.text.trim().isEmpty) {
      setState(
        () => error =
            'Give your vision a name to continue. A few words are enough.',
      );
      return;
    }
    final next = editing ? 7 : step + 1;
    editing = false;
    checkpoint(next);
  }

  void edit(int index) {
    setState(() {
      step = index;
      editing = true;
      error = null;
    });
  }

  Future<void> finish() async {
    if (saving) return;
    if (title.text.trim().isEmpty) {
      edit(1);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      String? replace;
      bool later = false;
      if (widget.controller.active.length >= 3) {
        final choice = await chooseRoom(context, widget.controller);
        if (choice == null) {
          if (mounted) setState(() => saving = false);
          return;
        }
        later = choice == 'save-later';
        replace = later ? null : choice;
      }
      final id = await widget.controller.createVision(
        title: title.text,
        why: why.text,
        image: image,
        area: area == 'Something Else' && customArea.text.trim().isNotEmpty
            ? customArea.text.trim()
            : area,
        rhythm: rhythm,
        tone: tone,
        replaceActiveId: replace,
        saveForLater: later,
        obstacle: obstacle,
      );
      if (!mounted) return;
      await sheet(
        context,
        MoveEditor(controller: widget.controller, visionId: id),
      );
      if (!mounted) return;
      setState(() => leaving = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Your vision could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'What matters to you right now?',
      'What are you hoping becomes real?',
      'Why does this matter to you?',
      'What might get in the way?',
      'What image brings it to life?',
      'How often does this need attention?',
      'How should Still speak to you?',
      'A little direction, made yours.',
    ];
    final hints = [
      'Seven short questions, then review. Only a vision name is required. Personal questions are optional in Settings.',
      'Big or small, write it in your own words. ${visionExample(widget.controller.data.preferences.profile)}',
      'What would change for you if this happened? Leave this blank if you are still figuring it out.',
      'Choose what fits this vision today. This is a situation to plan around, not a label for you.',
      'Choose an image or keep this one. You can use your own photo.',
      'A rhythm for attention, not a deadline or a notification schedule.',
      'Preview the actual Today wording. You can change this in Settings.',
      'Review before saving. You will choose one small move next, or leave room for it later.',
    ];
    final child = switch (step) {
      0 => Column(
        children: [
          for (final a in areas)
            AnswerCard(
              label: a,
              selected: area == a,
              onTap: saving ? null : () => setState(() => area = a),
            ),
          if (area == 'Something Else')
            TextField(
              controller: customArea,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Your area (optional)',
              ),
            ),
        ],
      ),
      1 => TextField(
        controller: title,
        maxLength: 100,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        onChanged: (_) => setState(() => error = null),
        decoration: const InputDecoration(
          labelText: 'Your vision',
          hintText: 'For example, take my parents to Japan',
        ),
      ),
      2 => TextField(
        controller: why,
        maxLength: 240,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Why it matters (optional)',
          hintText: 'For example, share time together while we can',
        ),
      ),
      3 => Column(
        children: [
          for (final b in barriers.entries)
            AnswerCard(
              label: b.value,
              selected: obstacle == b.key,
              description: obstacle == b.key && b.key.isNotEmpty
                  ? barrierHelp(b.key)
                  : null,
              onTap: saving ? null : () => setState(() => obstacle = b.key),
            ),
        ],
      ),
      4 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Photo(image, height: 220),
          const SizedBox(height: 16),
          for (var i = 0; i < photos.length; i++)
            AnswerCard(
              label: [
                'A place to discover',
                'Room to create',
                'A calmer moment',
              ][i],
              selected: image == photos[i],
              onTap: saving ? null : () => setState(() => image = photos[i]),
            ),
          OutlinedButton.icon(
            onPressed: saving
                ? null
                : () async {
                    try {
                      final selected = await choosePhoto();
                      if (selected != null && mounted) {
                        setState(() => image = selected);
                      }
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => error =
                              'We could not use that photo. Try a smaller image under 2.5 MB.',
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Choose your own photo'),
          ),
        ],
      ),
      5 => Column(
        children: [
          for (final r in Rhythm.values)
            AnswerCard(
              label: rhythmName(r),
              selected: rhythm == r,
              description: switch (r) {
                Rhythm.daily => 'Frequent attention when that helps.',
                Rhythm.weekly => 'One meaningful step at a time. The default.',
                Rhythm.occasional => 'Stay connected without constant action.',
              },
              onTap: saving ? null : () => setState(() => rhythm = r),
            ),
        ],
      ),
      6 => Column(
        children: [
          for (final t in Tone.values)
            AnswerCard(
              label: toneName(t),
              selected: tone == t,
              description:
                  '${toneDescription(t)}\n\nToday preview: “${toneExample(t)}”',
              onTap: saving ? null : () => setState(() => tone = t),
            ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Photo(image, height: 180),
          const SizedBox(height: 14),
          ReviewAnswer('Vision', title.text, () => edit(1)),
          ReviewAnswer(
            'Life area',
            area == 'Something Else' && customArea.text.isNotEmpty
                ? customArea.text
                : area,
            () => edit(0),
          ),
          ReviewAnswer(
            'What matters',
            why.text.isEmpty ? 'Room to discover this later' : why.text,
            () => edit(2),
          ),
          ReviewAnswer(
            'Possible obstacle',
            barriers[obstacle] ?? 'Not specified',
            () => edit(3),
          ),
          ReviewAnswer(
            'Image',
            photos.contains(image)
                ? 'Selected inspiration photo'
                : 'Your own photo',
            () => edit(4),
          ),
          ReviewAnswer('Rhythm', rhythmName(rhythm), () => edit(5)),
          ReviewAnswer('Tone', toneName(tone), () => edit(6)),
          Text(barrierHelp(obstacle), style: const TextStyle(height: 1.6)),
        ],
      ),
    };
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: QuestionFlow(
        section: 'Your vision',
        step: step,
        total: 8,
        title: titles[step],
        hint: hints[step],
        busy: saving,
        error: error,
        optional: step != 1 && step < 7,
        onBack: back,
        onClose: close,
        onContinue: step == 7 ? finish : advance,
        button: step == 7
            ? 'Keep this close'
            : editing
            ? 'Back to review'
            : step == 6
            ? 'Review my vision'
            : 'Continue',
        onSkip: step != 1 && step < 7 ? advance : null,
        child: child,
      ),
    );
  }
}
