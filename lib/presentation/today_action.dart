import 'package:flutter/material.dart';
import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'editors.dart';
import 'value_progress.dart';

class TodayAction extends StatefulWidget {
  const TodayAction({
    super.key,
    required this.controller,
    required this.id,
    required this.onOpen,
  });
  final StillController controller;
  final String id;
  final VoidCallback onOpen;
  @override
  State<TodayAction> createState() => _TodayActionState();
}

class _TodayActionState extends State<TodayAction> {
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Could not save. Your progress is unchanged; please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void confirmation(String message, Future<void> Function() undo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(label: 'Undo', onPressed: () => run(undo)),
      ),
    );
  }

  Future<void> finishMove(NextMove move) async {
    await widget.controller.completeMove(widget.id);
    if (mounted) {
      confirmation(
        'A step taken. You can stop here.',
        () => widget.controller.undoMove(widget.id, move.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller,
          v = c.vision(widget.id),
          rest = c.isResting(widget.id);
      final move = c.move(v),
          next = v.milestones.where((m) => !m.done).firstOrNull;
      final numeric =
          v.measure != ProgressMeasure.milestones && v.valueTarget > 0;
      final hasMilestones = !numeric && v.milestones.isNotEmpty;
      return Paper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Eyebrow('Just one thing'),
            const SizedBox(height: 8),
            Text(v.title, style: editorial(26)),
            const SizedBox(height: 12),
            Text(
              rest
                  ? 'It can wait. This is still yours.'
                  : numeric
                  ? '${valueText(v.valueTotal)} of ${valueText(v.valueTarget)} ${v.valueUnit} · ${v.progressPercent}%'
                  : hasMilestones
                  ? next?.title ?? 'Your milestones are complete.'
                  : move?.text ??
                        'Choose an action small enough to start today.',
              style: const TextStyle(fontSize: 17, height: 1.5),
            ),
            if (!rest &&
                !hasMilestones &&
                !numeric &&
                move?.cue.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'When or if: ${move!.cue}',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      if (rest) {
                        await c.restToday(v.id, undo: true);
                      } else if (numeric) {
                        await recordValue(context, c, v.id);
                      } else if (hasMilestones && next != null) {
                        await c.setMilestoneDone(v.id, next.id, true);
                        if (mounted) {
                          confirmation(
                            'Milestone complete · ${c.vision(v.id).progressPercent}%',
                            () => c.setMilestoneDone(v.id, next.id, false),
                          );
                        }
                      } else if (hasMilestones) {
                        widget.onOpen();
                      } else if (move != null) {
                        await finishMove(move);
                      } else {
                        await sheet(
                          context,
                          MoveEditor(
                            controller: c,
                            visionId: v.id,
                            smaller: true,
                          ),
                        );
                      }
                    }),
              child: Text(
                busy
                    ? 'One moment…'
                    : rest
                    ? 'Resume when ready'
                    : numeric
                    ? (v.measure == ProgressMeasure.money
                          ? 'Add deposit'
                          : 'Record progress')
                    : hasMilestones
                    ? (next != null ? 'Complete milestone' : 'Review my vision')
                    : move != null
                    ? 'I did this'
                    : 'Choose a small start',
              ),
            ),
            if (!rest) ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => sheet(
                            context,
                            MoveEditor(
                              controller: c,
                              visionId: v.id,
                              smaller: true,
                            ),
                          ),
                    child: const Text('Make it smaller'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => run(() => c.restToday(v.id)),
                    child: const Text('Not today'),
                  ),
                ],
              ),
              if ((numeric || hasMilestones) && move != null)
                Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Your small starting step'),
                    children: [
                      Text(move.text, style: const TextStyle(height: 1.6)),
                      if (move.cue.isNotEmpty) Text('When or if: ${move.cue}'),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => run(() => finishMove(move)),
                        child: const Text('I did this small step'),
                      ),
                    ],
                  ),
                ),
            ],
            if (rest)
              TextButton(
                onPressed: busy
                    ? null
                    : () => run(() => c.restToday(v.id, undo: true)),
                child: const Text('Undo rest'),
              ),
          ],
        ),
      );
    },
  );
}
