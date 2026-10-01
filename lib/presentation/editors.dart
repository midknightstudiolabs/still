import 'package:flutter/material.dart';

import '../application/still_controller.dart';
import '../domain/guidance.dart';
import 'design.dart';

class MoveEditor extends StatefulWidget {
  const MoveEditor({
    super.key,
    required this.controller,
    required this.visionId,
    this.smaller = false,
  });
  final StillController controller;
  final String visionId;
  final bool smaller;
  @override
  State<MoveEditor> createState() => _MoveEditorState();
}

class _MoveEditorState extends State<MoveEditor> {
  final text = TextEditingController();
  final cue = TextEditingController();
  late String obstacle;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final vision = widget.controller.vision(widget.visionId);
    obstacle = vision.obstacle;
    cue.text = widget.controller.move(vision)?.cue ?? '';
    text.text = widget.smaller
        ? ''
        : widget.controller
                  .move(widget.controller.vision(widget.visionId))
                  ?.text ??
              '';
  }

  @override
  void dispose() {
    text.dispose();
    cue.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (text.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      await widget.controller.setMove(
        widget.visionId,
        text.text,
        cue: cue.text,
        obstacle: obstacle,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(26, 0, 26, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Eyebrow('One small move'),
        const SizedBox(height: 12),
        Text(
          widget.smaller
              ? 'What is the easiest first action?'
              : 'What would make this\na little more real?',
          style: editorial(34),
        ),
        const SizedBox(height: 12),
        Text(
          widget.smaller
              ? 'Aim for something you could start in about two minutes. Starting counts; you do not need to finish the whole task.'
              : 'One thing is enough. You can change it later.',
          style: TextStyle(color: muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        if (widget.smaller) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in [
                'Open what I need to begin.',
                'Write one rough sentence.',
                'List the first thing I need.',
              ])
                ActionChip(
                  label: Text(example),
                  onPressed: saving
                      ? null
                      : () => setState(() => text.text = example),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Help me find a starting point',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Optional ideas based on your choices',
            style: TextStyle(fontSize: 12),
          ),
          children: [
            DropdownButtonFormField<String>(
              initialValue: barriers.containsKey(obstacle) ? obstacle : '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'What gets in the way of this vision?',
              ),
              items: barriers.entries
                  .map(
                    (b) => DropdownMenuItem(
                      value: b.key,
                      child: Text(b.value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (v) => setState(() => obstacle = v ?? ''),
            ),
            const SizedBox(height: 14),
            Text(barrierHelp(obstacle), style: const TextStyle(height: 1.6)),
            const SizedBox(height: 12),
            Text(
              capacityHelp(widget.controller.data.preferences.profile.capacity),
              style: const TextStyle(height: 1.6, color: muted),
            ),
            const SizedBox(height: 12),
            Text(
              'Example: ${suggestedMove(widget.controller.vision(widget.visionId).area, obstacle)}',
              style: const TextStyle(height: 1.6),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () => setState(() {
                      text.text = suggestedMove(
                        widget.controller.vision(widget.visionId).area,
                        obstacle,
                      );
                    }),
              child: const Text('Use this as a starting point'),
            ),
            const Text(
              'Preset example, not AI. Edit it to fit your vision. Nothing is saved until you choose Keep this move.',
              style: TextStyle(fontSize: 11, color: muted, height: 1.5),
            ),
            const SizedBox(height: 16),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: text,
          autofocus: true,
          maxLength: 180,
          minLines: 2,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Check passport expiry. Save a little. Ask someone.',
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: cue,
          maxLength: 140,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'When or if… (optional)',
            hintText: 'After breakfast on Saturday, at my desk',
            helperText: 'A cue for this step, not a scheduled reminder.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: text.text.trim().isEmpty || saving ? null : save,
            child: Text(saving ? 'Keeping it…' : 'Keep this move'),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Leave some space for now'),
          ),
        ),
      ],
    ),
  );
}

class ProofEditor extends StatefulWidget {
  const ProofEditor({
    super.key,
    required this.controller,
    required this.visionId,
    this.complete = false,
  });
  final StillController controller;
  final String visionId;
  final bool complete;
  @override
  State<ProofEditor> createState() => _ProofEditorState();
}

class _ProofEditorState extends State<ProofEditor> {
  final note = TextEditingController();
  String? image;
  late DateTime when = widget.controller.clock();
  bool saving = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final photo = await choosePhoto();
      if (mounted && photo != null) setState(() => image = photo);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.controller.addProof(
        widget.visionId,
        note.text,
        image: image,
        when: when,
        complete: widget.complete,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(widget.complete ? 'It happened' : 'A little more real'),
        const SizedBox(height: 12),
        Text(
          widget.complete
              ? 'Keep the moment.'
              : 'Something happened.\nThat counts.',
          style: editorial(36),
        ),
        const SizedBox(height: 12),
        Text(
          widget.complete
              ? 'Want to add the moment that made this real?'
              : 'A conversation, a small step, a photo. It all belongs here.',
          style: const TextStyle(color: muted, height: 1.6),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: note,
          maxLength: 600,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'What would you like to remember?',
          ),
        ),
        if (image != null) ...[
          Photo(image!, height: 160),
          TextButton(
            onPressed: () => setState(() => image = null),
            child: const Text('Remove photo'),
          ),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: pick,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
              label: Text(image == null ? 'Add photo' : 'Change photo'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: when,
                  firstDate: DateTime(1900),
                  lastDate: widget.controller.clock(),
                );
                if (d != null && mounted) setState(() => when = d);
              },
              child: Text(
                shortDate(when),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                saving ||
                    (!widget.complete &&
                        note.text.trim().isEmpty &&
                        image == null)
                ? null
                : save,
            child: Text(
              saving
                  ? 'Keeping it…'
                  : widget.complete
                  ? 'Move to Memories'
                  : 'Keep this proof',
            ),
          ),
        ),
        if (widget.complete)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'A photo or note is optional. The memory is yours either way.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.6),
            ),
          ),
      ],
    ),
  );
}

Future<String?> chooseRoom(BuildContext context, StillController c) =>
    sheet<String>(
      context,
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Eyebrow('A little breathing room'),
            const SizedBox(height: 12),
            Text('Three is enough\nto keep close.', style: editorial(36)),
            const SizedBox(height: 12),
            const Text(
              'Move one to Later. It will be there when you’re ready.',
              style: TextStyle(color: muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            for (final v in c.active)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Photo(v.imagePath, width: 48, height: 48, radius: 10),
                title: Text(v.title, style: const TextStyle(fontSize: 13)),
                subtitle: const Text(
                  'Move to Later',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                trailing: const Icon(Icons.arrow_forward, size: 18),
                onTap: () => Navigator.pop(context, v.id),
              ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context, 'save-later'),
                child: const Text('Keep the new vision in Later instead'),
              ),
            ),
          ],
        ),
      ),
    );

Future<String?> letGoReason(BuildContext context) => sheet<String>(
  context,
  SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('It’s okay to change.', style: editorial(36)),
        const SizedBox(height: 12),
        const Text(
          'Want to leave a reason? Just for you.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 20),
        for (final reason in [
          'Changed my mind',
          'Wrong timing',
          'Wasn’t really mine',
          'Life changed',
          'Something else',
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(reason, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.pop(context, reason),
          ),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Let go without a reason'),
          ),
        ),
      ],
    ),
  ),
);
