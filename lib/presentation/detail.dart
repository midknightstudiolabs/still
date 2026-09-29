import 'package:flutter/material.dart';

import '../application/still_controller.dart';
import '../domain/models.dart';
import 'design.dart';
import 'editors.dart';

Future<void> showProof(
  BuildContext context,
  StillController c,
  String id, {
  bool complete = false,
}) async {
  final saved = await sheet<bool>(
    context,
    ProofEditor(controller: c, visionId: id, complete: complete),
  );
  if (saved == true && context.mounted) {
    toast(context, complete ? 'A vision became a memory.' : 'That counts.');
  }
}

Future<void> markMove(
  BuildContext context,
  StillController c,
  String id,
) async {
  try {
    await c.completeMove(id);
    if (!context.mounted) return;
    toast(context, 'A little more real. Kept as proof.');
    await sheet(context, MoveEditor(controller: c, visionId: id));
  } catch (e) {
    if (context.mounted) toast(context, '$e');
  }
}

class VisionDetail extends StatelessWidget {
  const VisionDetail({super.key, required this.controller, required this.id});
  final StillController controller;
  final String id;
  Future<void> more(BuildContext context, Vision v) async {
    final choice = await sheet<String>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (v.status != VisionStatus.completed)
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('It Happened'),
                subtitle: const Text('A vision becomes a memory'),
                onTap: () => Navigator.pop(context, 'complete'),
              ),
            if (v.status != VisionStatus.active)
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Keep this close again'),
                onTap: () => Navigator.pop(context, 'active'),
              ),
            if (v.status == VisionStatus.active)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('Not right now'),
                subtitle: const Text('Keep it in Later'),
                onTap: () => Navigator.pop(context, 'later'),
              ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Change rhythm'),
              onTap: () => Navigator.pop(context, 'rhythm'),
            ),
            if (v.status != VisionStatus.letGo)
              ListTile(
                leading: const Icon(Icons.air),
                title: const Text('Let Go'),
                subtitle: const Text('It’s okay to change your mind'),
                onTap: () => Navigator.pop(context, 'letgo'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    try {
      if (choice == 'complete') {
        await showProof(context, controller, id, complete: true);
        return;
      }
      if (choice == 'later') {
        await controller.setStatus(id, VisionStatus.later);
        return;
      }
      if (choice == 'active') {
        String? replace;
        if (controller.active.length >= 3) {
          replace = await chooseRoom(context, controller);
          if (replace == null || replace == 'save-later') return;
        }
        await controller.setStatus(
          id,
          VisionStatus.active,
          replaceActiveId: replace,
        );
        return;
      }
      if (choice == 'letgo') {
        final reason = await letGoReason(context);
        if (reason != null) {
          await controller.setStatus(id, VisionStatus.letGo, reason: reason);
        }
        return;
      }
      if (choice == 'rhythm') {
        final r = await sheet<Rhythm>(
          context,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: Rhythm.values
                  .map(
                    (r) => ListTile(
                      title: Text(rhythmName(r)),
                      trailing: r == v.rhythm ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(context, r),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (r != null) {
          await controller.transact(
            (d) => d.visions.firstWhere((v) => v.id == id)
              ..rhythm = r
              ..updatedAt = controller.clock(),
          );
        }
      }
    } catch (e) {
      if (context.mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final v = controller.vision(id),
          move = controller.move(controller.vision(id));
      final proofs = controller.proofs(id);
      final nowImage = proofs
          .where((p) => p.imagePath != null)
          .firstOrNull
          ?.imagePath;
      return Scaffold(
        appBar: AppBar(
          title: const Eyebrow('A little closer'),
          actions: [
            IconButton(
              onPressed: () => more(context, v),
              icon: const Icon(Icons.more_horiz),
              tooltip: 'Vision options',
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Photo(v.imagePath, height: 290),
                const SizedBox(height: 26),
                Eyebrow('${v.area} · ${rhythmName(v.rhythm)}'),
                const SizedBox(height: 12),
                Text(v.title, style: editorial(40)),
                if (v.why.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '“${v.why}”',
                    style: const TextStyle(color: muted, height: 1.8),
                  ),
                ],
                const SizedBox(height: 26),
                if (v.status == VisionStatus.completed)
                  Paper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('It happened'),
                        const SizedBox(height: 10),
                        Text(
                          'Once a vision.\nNow part of your story.',
                          style: editorial(29),
                        ),
                        if (v.completedAt != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            shortDate(v.completedAt!),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Photo(v.imagePath, height: 120),
                                  const SizedBox(height: 8),
                                  const Eyebrow('Then'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  if (nowImage != null)
                                    Photo(nowImage, height: 120)
                                  else
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: muted.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.photo_camera_outlined,
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  const Eyebrow('Now'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else if (v.status == VisionStatus.active)
                  Paper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('Your next small move'),
                        const SizedBox(height: 12),
                        Text(
                          move?.text ?? 'A little room for what comes next.',
                          style: const TextStyle(fontSize: 17, height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (move != null)
                              FilledButton.icon(
                                onPressed: () =>
                                    markMove(context, controller, id),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('I did this'),
                              ),
                            TextButton(
                              onPressed: () => sheet(
                                context,
                                MoveEditor(
                                  controller: controller,
                                  visionId: id,
                                ),
                              ),
                              child: Text(
                                move == null
                                    ? 'Add a Next Move'
                                    : 'Update Next Move',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Paper(
                    child: Text(
                      v.status == VisionStatus.later
                          ? 'Not right now. Come back when you’re ready.'
                          : 'You made room for what matters now.${v.letGoReason?.isNotEmpty == true ? '\n${v.letGoReason}' : ''}',
                      style: const TextStyle(height: 1.8),
                    ),
                  ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'The little things count.',
                        style: editorial(29),
                      ),
                    ),
                    IconButton(
                      onPressed: () => showProof(context, controller, id),
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add Proof',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${proofs.length} ${proofs.length == 1 ? 'moment' : 'moments'} kept',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 24),
                ProofTimeline(proofs: proofs),
                TimelineEntry(
                  title: 'A vision began.',
                  subtitle: shortDate(v.createdAt),
                  icon: Icons.spa_outlined,
                ),
                if (controller.data.moves.any((m) => m.visionId == id)) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Your small moves',
                      style: TextStyle(fontSize: 13),
                    ),
                    children: controller.data.moves
                        .where((m) => m.visionId == id)
                        .toList()
                        .reversed
                        .map(
                          (m) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              m.text,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${m.status == MoveStatus.completed
                                  ? 'Kept as proof'
                                  : m.status == MoveStatus.replaced
                                  ? 'Made room for another move'
                                  : 'Current move'} · ${shortDate(m.completedAt ?? m.createdAt)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            leading: Icon(
                              m.status == MoveStatus.completed
                                  ? Icons.check_circle_outline
                                  : Icons.circle_outlined,
                              size: 18,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ProofTimeline extends StatelessWidget {
  const ProofTimeline({super.key, required this.proofs, this.controller});
  final List<Proof> proofs;
  final StillController? controller;
  @override
  Widget build(BuildContext context) {
    String? previous;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in proofs) ...[
          if (previous != monthDate(p.createdAt))
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: Eyebrow(previous = monthDate(p.createdAt)),
            ),
          TimelineEntry(
            title: p.note.isEmpty ? 'A moment worth keeping.' : p.note,
            subtitle:
                '${shortDate(p.createdAt)}${controller != null ? ' · ${controller!.vision(p.visionId).title}' : ''}',
            image: p.imagePath,
            icon: p.proofType == ProofType.action
                ? Icons.check
                : p.proofType == ProofType.milestone
                ? Icons.auto_awesome_outlined
                : Icons.favorite_border,
          ),
        ],
      ],
    );
  }
}

class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.image,
  });
  final String title, subtitle;
  final String? image;
  final IconData icon;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: muted.withValues(alpha: .12),
                ),
                child: Icon(icon, size: 15, color: muted),
              ),
              Expanded(
                child: Container(width: 1, color: muted.withValues(alpha: .2)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, height: 1.7)),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
                if (image != null) ...[
                  const SizedBox(height: 14),
                  Photo(image!, height: 200),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
