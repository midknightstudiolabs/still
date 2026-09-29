import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';

Future<void> editProgress(BuildContext context, StillController c, String id) =>
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProgressEditor(controller: c, id: id),
      ),
    );

class VisionProgress extends StatelessWidget {
  const VisionProgress({
    super.key,
    required this.controller,
    required this.vision,
  });
  final StillController controller;
  final Vision vision;
  @override
  Widget build(BuildContext context) {
    final v = vision, percent = v.progressPercent;
    final dates = [
      ...v.milestones.where((m) => m.done).map((m) => m.completedAt!),
      ...controller.proofs(v.id).map((p) => p.createdAt),
    ]..sort();
    return Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Your progress'),
          const SizedBox(height: 10),
          Text(
            percent == null ? 'Every small step counts.' : '$percent%',
            style: editorial(36),
          ),
          if (percent != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: v.milestonesDone / v.milestones.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'Milestones completed',
              semanticsValue: '$percent',
            ),
            const SizedBox(height: 12),
            Text(
              '${v.milestonesDone} of ${v.milestones.length} milestones complete',
            ),
            if (percent == 100)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Your milestones are complete. You decide when the vision has happened.',
                  style: TextStyle(height: 1.5),
                ),
              ),
          ] else
            const Text(
              'Add milestones to see your percentage. Your existing moments are still part of your story.',
              style: TextStyle(height: 1.5),
            ),
          const SizedBox(height: 16),
          Text(
            'Started ${shortDate(v.createdAt)}',
            style: const TextStyle(height: 1.7),
          ),
          Text(
            v.targetDate == null
                ? 'Target date · Whenever you’re ready'
                : 'Target ${shortDate(v.targetDate!)}',
            style: const TextStyle(height: 1.7),
          ),
          if (dates.isNotEmpty)
            Text(
              'Latest step or proof ${shortDate(dates.last)}',
              style: const TextStyle(height: 1.7),
            ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => editProgress(context, controller, v.id),
            icon: const Icon(Icons.checklist_rounded),
            label: Text(
              v.milestones.isEmpty
                  ? 'Set milestones & date'
                  : 'Update milestones & date',
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressEditor extends StatefulWidget {
  const ProgressEditor({super.key, required this.controller, required this.id});
  final StillController controller;
  final String id;
  @override
  State<ProgressEditor> createState() => _ProgressEditorState();
}

class _ProgressEditorState extends State<ProgressEditor> {
  late List<Milestone> milestones;
  DateTime? target;
  bool saving = false;
  String? error;
  int sequence = 0;
  final nameInputs = <TextEditingController>[];
  @override
  void dispose() {
    for (final input in nameInputs) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final v = widget.controller.vision(widget.id);
    milestones = v.milestones
        .map((m) => Milestone.fromJson(m.toJson()))
        .toList();
    target = v.targetDate;
  }

  Future<void> nameMilestone([Milestone? milestone]) async {
    final input = TextEditingController(text: milestone?.title ?? '');
    nameInputs.add(input);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          milestone == null ? 'One meaningful milestone' : 'Edit milestone',
        ),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 120,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'For example, book our flights',
            labelText: 'Milestone',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: input,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, value.text.trim()),
              child: const Text('Keep milestone'),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (value != null) {
      setState(() {
        if (milestone != null) {
          milestone.title = value;
        } else {
          milestones.add(
            Milestone(
              id: '${DateTime.now().microsecondsSinceEpoch}-${sequence++}',
              title: value,
            ),
          );
        }
      });
    }
  }

  Future<void> chooseDate() async {
    final now = widget.controller.clock();
    final selected = await showDatePicker(
      context: context,
      initialDate: target ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      helpText: 'An optional date to aim for',
    );
    if (selected != null && mounted) setState(() => target = selected);
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.saveProgress(widget.id, milestones, target);
      if (!mounted) return;
      setState(() => saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Your progress could not be saved. Your changes are still here. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = milestones.where((m) => m.done).length;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Milestones & date'),
          leading: IconButton(
            tooltip: 'Cancel changes',
            onPressed: saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('See how far you’ve come.', style: editorial(36)),
                const SizedBox(height: 14),
                const Text(
                  'Each milestone counts equally. Tick one when it happens; untick it if plans change. Save to update your vision.',
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 18),
                if (milestones.isNotEmpty)
                  Text(
                    '${(done * 100 / milestones.length).round()}% · $done of ${milestones.length} complete',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 12),
                for (final m in milestones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Paper(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: m.done,
                            onChanged: saving
                                ? null
                                : (done) => setState(() {
                                    m.completedAt = done == true
                                        ? widget.controller.clock()
                                        : null;
                                  }),
                            title: Text(m.title),
                            subtitle: m.done
                                ? Text('Completed ${shortDate(m.completedAt!)}')
                                : null,
                          ),
                          Wrap(
                            spacing: 10,
                            children: [
                              TextButton(
                                onPressed: saving
                                    ? null
                                    : () => nameMilestone(m),
                                child: const Text('Edit milestone'),
                              ),
                              TextButton(
                                onPressed: saving
                                    ? null
                                    : () =>
                                          setState(() => milestones.remove(m)),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (milestones.length < 20)
                  OutlinedButton.icon(
                    onPressed: saving ? null : () => nameMilestone(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add milestone'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Use up to 20 milestones. Adding or removing one recalculates the percentage. Next Moves and proof do not automatically tick milestones.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 26),
                const Eyebrow('A date to aim for · Optional'),
                const SizedBox(height: 8),
                Text(
                  target == null ? 'No target date set' : shortDate(target!),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: saving ? null : chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        target == null
                            ? 'Choose target date'
                            : 'Change target date',
                      ),
                    ),
                    if (target != null)
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => setState(() => target = null),
                        child: const Text('Clear date'),
                      ),
                  ],
                ),
                const Text(
                  'A guide, not a deadline. You can move this date whenever life changes.',
                  style: TextStyle(height: 1.6),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save progress'),
            ),
          ),
        ),
      ),
    );
  }
}
