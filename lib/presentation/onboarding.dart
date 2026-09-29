import 'package:flutter/material.dart';

import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'editors.dart';

class VisionWizard extends StatefulWidget {
  const VisionWizard({super.key, required this.controller, this.first = false});
  final StillController controller;
  final bool first;
  @override
  State<VisionWizard> createState() => _VisionWizardState();
}

class _VisionWizardState extends State<VisionWizard> {
  int step = 0;
  String area = 'Travel', image = photos.first;
  final customArea = TextEditingController(),
      title = TextEditingController(),
      why = TextEditingController();
  Rhythm rhythm = Rhythm.weekly;
  late Tone tone = widget.controller.data.preferences.tone;
  bool saving = false;
  @override
  void dispose() {
    customArea.dispose();
    title.dispose();
    why.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (saving) return;
    setState(() => saving = true);
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
      );
      if (!mounted) return;
      await sheet(
        context,
        MoveEditor(controller: widget.controller, visionId: id),
      );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headings = [
      'What matters to\nyou right now?',
      'What are you hoping\nbecomes real?',
      'Why does\nthis matter?',
      'Give it\na little life.',
      'How often does this\nneed attention?',
      'How should this\napp talk to you?',
    ];
    final subtitles = [
      'You don’t need your whole life figured out. Start with what feels important.',
      'Big or small. Specific or still taking shape. Make it yours.',
      'A few words to come back to. This one is optional.',
      'Choose a photo that brings you back to the feeling.',
      'Choose a rhythm, not a deadline.',
      'A little support, in your own language.',
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: saving
              ? null
              : () {
                  if (step > 0) {
                    setState(() => step--);
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: Text('still', style: editorial(30)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(child: Eyebrow('${step + 1} of 6')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        height: 2,
                        color: i <= step
                            ? Theme.of(context).colorScheme.primary
                            : muted.withValues(alpha: .2),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      key: ValueKey(step),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(
                          widget.first
                              ? 'A beginning, not a big plan'
                              : 'A little space for something new',
                        ),
                        const SizedBox(height: 20),
                        Text(headings[step], style: editorial(42)),
                        const SizedBox(height: 18),
                        Text(
                          subtitles[step],
                          style: const TextStyle(
                            color: muted,
                            height: 1.75,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (step == 0) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: areas
                                .map(
                                  (a) => ChoiceChip(
                                    label: Text(a),
                                    selected: area == a,
                                    onSelected: (_) => setState(() => area = a),
                                    showCheckmark: false,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    side: BorderSide(
                                      color: muted.withValues(alpha: .2),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          if (area == 'Something Else')
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: TextField(
                                controller: customArea,
                                maxLength: 60,
                                decoration: const InputDecoration(
                                  hintText: 'What feels important?',
                                ),
                              ),
                            ),
                        ],
                        if (step == 1)
                          TextField(
                            controller: title,
                            maxLength: 100,
                            minLines: 3,
                            maxLines: 4,
                            autofocus: true,
                            style: editorial(29),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Take my parents to Japan.',
                            ),
                          ),
                        if (step == 2)
                          TextField(
                            controller: why,
                            onChanged: (_) => setState(() {}),
                            maxLength: 240,
                            minLines: 3,
                            maxLines: 5,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'I want to do this while we still can.',
                            ),
                          ),
                        if (step == 3) ...[
                          Photo(image, height: 250),
                          const SizedBox(height: 16),
                          Row(
                            children: photos
                                .map(
                                  (p) => Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => image = p),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: image == p
                                                ? pine
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Photo(p, height: 68, radius: 9),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final p = await choosePhoto();
                                  if (p != null && mounted) {
                                    setState(() => image = p);
                                  }
                                } catch (e) {
                                  if (context.mounted) toast(context, '$e');
                                }
                              },
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                              ),
                              label: const Text('Choose your own photo'),
                            ),
                          ),
                        ],
                        if (step == 4)
                          ...Rhythm.values.map(
                            (r) => option(
                              rhythmName(r),
                              switch (r) {
                                Rhythm.daily => 'For something that benefits from frequent action.',
                                Rhythm.weekly => 'For bigger hopes. One meaningful step is enough.',
                                Rhythm.occasional =>
                                  'Stay connected, without constant action.',
                              },
                              rhythm == r,
                              () => setState(() => rhythm = r),
                              badge: r == Rhythm.weekly ? 'RECOMMENDED' : null,
                            ),
                          ),
                        if (step == 5)
                          ...Tone.values.map(
                            (t) => option(
                              toneName(t),
                              switch (t) {
                                Tone.grounded => 'Keep one thing alive. One small move is enough.',
                                Tone.motivational =>
                                  'You’ve already started. Keep moving.',
                                Tone.manifestation => 'Picture it clearly. Then take one step toward it.',
                                Tone.none => 'Just your visions, next moves, and real-life moments.',
                              },
                              tone == t,
                              () => setState(() => tone = t),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          saving || (step == 1 && title.text.trim().isEmpty)
                          ? null
                          : () {
                              if (step == 5) {
                                finish();
                              } else {
                                FocusScope.of(context).unfocus();
                                setState(() => step++);
                              }
                            },
                      child: Text(
                        saving
                            ? 'Making room…'
                            : step == 5
                            ? 'Keep this close'
                            : step == 2 && why.text.isEmpty
                            ? 'Continue · optional'
                            : 'Continue',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget option(
    String title,
    String body,
    bool selected,
    VoidCallback onTap, {
    String? badge,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .07)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : muted.withValues(alpha: .22),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.2,
                          color: muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 7),
                  Text(
                    body,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19,
              color: selected ? Theme.of(context).colorScheme.primary : muted,
            ),
          ],
        ),
      ),
    ),
  );
}
