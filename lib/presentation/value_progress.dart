import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'progress.dart';

class ValueProgressEditor extends StatefulWidget {
  const ValueProgressEditor({
    super.key,
    required this.controller,
    required this.id,
    required this.measure,
  });
  final StillController controller;
  final String id;
  final ProgressMeasure measure;
  @override
  State<ValueProgressEditor> createState() => _ValueProgressEditorState();
}

class _ValueProgressEditorState extends State<ValueProgressEditor> {
  late ProgressMeasure measure;
  late List<ValueEntry> entries;
  final target = TextEditingController(), unit = TextEditingController();
  DateTime? targetDate;
  bool saving = false;
  String? error;
  bool get money => measure == ProgressMeasure.money;
  int get total => entries.fold(0, (sum, e) => sum + e.amount);
  @override
  void initState() {
    super.initState();
    final v = widget.controller.vision(widget.id);
    measure = widget.measure;
    entries = List.of(v.entries);
    target.text = v.valueTarget > 0 ? valueText(v.valueTarget) : '';
    unit.text = v.valueUnit.isNotEmpty
        ? v.valueUnit
        : money
        ? 'PHP'
        : '';
    targetDate = v.targetDate;
  }

  @override
  void dispose() {
    target.dispose();
    unit.dispose();
    super.dispose();
  }

  Future<void> addEntry() async {
    final entry = await showDialog<ValueEntry>(
      context: context,
      builder: (_) =>
          _EntryDialog(money: money, now: widget.controller.clock()),
    );
    if (entry != null && mounted) {
      setState(() {
        entries.add(entry);
        error = null;
      });
    }
  }

  Future<void> save() async {
    final amount = parseValue(target.text);
    if (amount == null ||
        amount <= 0 ||
        unit.text.trim().isEmpty ||
        total < 0 ||
        total > 100000000000) {
      setState(
        () => error =
            'Enter a positive target and a currency or unit. Use up to two decimals, without commas. Your total must be between 0 and 1 billion.',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.controller.saveValueProgress(
        widget.id,
        measure,
        amount,
        unit.text,
        entries,
        targetDate,
      );
      if (!mounted) return;
      setState(() => saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error =
              'Could not save. Your changes are still here; check the values and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = parseValue(target.text) ?? 0;
    final percent = goal > 0
        ? ((total / goal).clamp(0, 1) * 100).floor()
        : null;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(money ? 'Money progress' : 'Value progress'),
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
                Text(
                  money
                      ? 'Every deposit brings it closer.'
                      : 'Make your progress measurable.',
                  style: editorial(34),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Milestones'),
                      selected: false,
                      onSelected: saving
                          ? null
                          : (_) => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ProgressEditor(
                                  controller: widget.controller,
                                  id: widget.id,
                                ),
                              ),
                            ),
                    ),
                    for (final m in [
                      ProgressMeasure.money,
                      ProgressMeasure.value,
                    ])
                      ChoiceChip(
                        label: Text(
                          m == ProgressMeasure.money ? 'Money' : 'Other value',
                        ),
                        selected: measure == m,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => measure = m),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Progress = recorded total ÷ target. Save before switching to milestones to keep edits. Existing milestones stay available.',
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: target,
                  enabled: !saving,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Target value',
                    hintText: '10000',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unit,
                  enabled: !saving,
                  maxLength: 20,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: money ? 'Currency' : 'Unit',
                    hintText: money ? 'PHP, USD, EUR' : 'books, hours, km',
                  ),
                ),
                const Text(
                  'Use one currency or unit for all entries. Changing its label does not convert existing values. Up to two decimal places.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                Paper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        percent == null ? 'Set your target' : '$percent%',
                        style: editorial(36),
                      ),
                      Text(
                        '${valueText(total)} / ${goal > 0 ? valueText(goal) : '—'} ${unit.text}',
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      ),
                      if (goal > 0)
                        Text(
                          total >= goal
                              ? 'Target reached. Your actual total is kept.'
                              : '${valueText(goal - total)} ${unit.text} to go',
                          style: const TextStyle(height: 1.6),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: saving ? null : addEntry,
                  icon: const Icon(Icons.add),
                  label: Text(
                    money ? 'Record deposit or withdrawal' : 'Record value',
                  ),
                ),
                const Text(
                  'Record an opening balance as your first entry if you have already started. Entries are recorded manually.',
                  style: TextStyle(height: 1.6),
                ),
                const SizedBox(height: 14),
                for (final entry in entries.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${entry.amount > 0 ? '+' : ''}${valueText(entry.amount)} ${unit.text}',
                    ),
                    subtitle: Text(
                      '${shortDate(entry.when)}${entry.note.isEmpty ? '' : '\n${entry.note}'}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove entry',
                      icon: const Icon(Icons.close),
                      onPressed: saving
                          ? null
                          : () => setState(() => entries.remove(entry)),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  targetDate == null
                      ? 'No target date set'
                      : 'Target ${shortDate(targetDate!)}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Choose target date'),
                      onPressed: saving
                          ? null
                          : () async {
                              final chosen = await showDatePicker(
                                context: context,
                                initialDate:
                                    targetDate ?? widget.controller.clock(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2200),
                              );
                              if (chosen != null && mounted) {
                                setState(() => targetDate = chosen);
                              }
                            },
                    ),
                    if (targetDate != null)
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => setState(() => targetDate = null),
                        child: const Text('Clear date'),
                      ),
                  ],
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
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

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.money, required this.now});
  final bool money;
  final DateTime now;
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final amount = TextEditingController(), note = TextEditingController();
  late DateTime when = widget.now;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.money ? 'Record a deposit or withdrawal' : 'Record a value',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: '500 or -100',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Positive to add; negative to subtract. Use up to two decimals, without commas.',
          ),
          TextField(
            controller: note,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          TextButton(
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: when,
                firstDate: DateTime(1900),
                lastDate: widget.now,
                helpText: 'When did this happen?',
              );
              if (chosen != null && mounted) setState(() => when = chosen);
            },
            child: Text('Date: ${shortDate(when)}'),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final value = parseValue(amount.text);
          if (value == null || value == 0 || value.abs() > 100000000000) {
            setState(
              () => error =
                  'Enter a nonzero amount up to 1 billion, with up to two decimals.',
            );
            return;
          }
          Navigator.pop(
            context,
            ValueEntry(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              amount: value,
              when: when,
              note: note.text.trim(),
            ),
          );
        },
        child: const Text('Keep entry'),
      ),
    ],
  );
}
