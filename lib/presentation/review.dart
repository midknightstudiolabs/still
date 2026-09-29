import 'package:flutter/material.dart';

import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'editors.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.controller,
    this.comeback = false,
  });
  final StillController controller;
  final bool comeback;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ids = widget.controller.active.map((v) => v.id).toList();
  int index = 0;
  bool busy = false, done = false;
  Future<void> respond(CheckResponse response) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final id = ids[index];
      String? reason;
      if (response == CheckResponse.letGo) {
        reason = await letGoReason(context);
        if (reason == null) {
          if (mounted) setState(() => busy = false);
          return;
        }
      }
      await widget.controller.checkIn(id, response, reason: reason);
      if (!mounted) return;
      if (response == CheckResponse.stillMine) {
        await sheet(
          context,
          MoveEditor(controller: widget.controller, visionId: id),
        );
        if (!mounted) return;
        final add = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Anything that counts\nas proof?',
              style: editorial(30),
            ),
            content: const Text('Even the little things belong here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip for now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add a moment'),
              ),
            ],
          ),
        );
        if (add == true && mounted) {
          await sheet(
            context,
            ProofEditor(controller: widget.controller, visionId: id),
          );
        }
      }
      if (index + 1 == ids.length) {
        await widget.controller.finishReview();
        if (mounted) {
          setState(() {
            done = true;
            busy = false;
          });
        }
      } else if (mounted) {
        setState(() {
          index++;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        toast(context, '$e');
        setState(() => busy = false);
      }
    }
  }

  Future<void> close() async {
    if (busy) return;
    try {
      if (!done) await widget.controller.finishReview(postponed: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ids.isEmpty || done ? null : widget.controller.vision(ids[index]);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) close();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Eyebrow(
            widget.comeback ? 'Room to begin again' : 'Your weekly pause',
          ),
          actions: [
            IconButton(
              onPressed: busy ? null : close,
              icon: const Icon(Icons.close),
              tooltip: 'Come back later',
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
              child: v == null
                  ? EmptyMoment(
                      title: 'You’re clear again.',
                      body:
                          'Keep what feels like you.\nCome back when you’re ready.',
                      action: FilledButton(
                        onPressed: close,
                        child: const Text('Back to today'),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.comeback
                              ? 'Welcome back.'
                              : 'Does this\nstill matter?',
                          style: editorial(44),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.comeback
                              ? 'A lot can change. Let’s see what still feels like you.'
                              : 'No catching up. Just a moment to see what still feels like you.',
                          style: const TextStyle(color: muted, height: 1.75),
                        ),
                        const SizedBox(height: 26),
                        Photo(v.imagePath, height: 230),
                        const SizedBox(height: 22),
                        Eyebrow(
                          '${index + 1} of ${ids.length} · ${rhythmName(v.rhythm)}',
                        ),
                        const SizedBox(height: 10),
                        Text(v.title, style: editorial(32)),
                        if (v.why.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            v.why,
                            style: const TextStyle(color: muted, height: 1.7),
                          ),
                        ],
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: busy
                                ? null
                                : () => respond(CheckResponse.stillMine),
                            child: Text(
                              widget.comeback ? 'Keep' : 'Still Mine',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => respond(CheckResponse.slowDown),
                                child: const Text('Slow Down'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => respond(CheckResponse.later),
                                child: const Text('Later'),
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => respond(CheckResponse.letGo),
                            child: const Text('Let Go'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'There’s no wrong answer.',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
