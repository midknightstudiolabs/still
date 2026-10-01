import 'package:flutter/material.dart';

import '../application/still_controller.dart';
import '../domain/models.dart';
import '../domain/guidance.dart';
import 'design.dart';
import 'detail.dart';
import 'progress.dart';
import 'today_action.dart';
import 'onboarding.dart';
import 'review.dart';
import 'profile.dart';

Future<void> newVision(BuildContext context, StillController c) async {
  final id = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => VisionWizard(controller: c)),
  );
  if (id != null && context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisionDetail(controller: c, id: id),
      ),
    );
  }
}

void openVision(BuildContext context, StillController c, String id) =>
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisionDetail(controller: c, id: id),
      ),
    );

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final StillController controller;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int tab = 0;
  bool reviewOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(checkReturn);
    checkReturn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(checkReturn);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final last = widget.controller.data.preferences.lastAppOpen;
      if (last != null &&
          widget.controller.clock().difference(last).inDays >= 14 &&
          widget.controller.active.isNotEmpty) {
        widget.controller.needsComeback = true;
        checkReturn();
      } else {
        widget.controller
            .transact(
              (d) => d.preferences.lastAppOpen = widget.controller.clock(),
            )
            .catchError((Object e) {
              if (mounted) toast(context, '$e');
            });
      }
    }
  }

  void checkReturn() {
    if (widget.controller.needsComeback && !reviewOpen) {
      reviewOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ReviewScreen(controller: widget.controller, comeback: true),
          ),
        );
        reviewOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (tab) {
                0 => TodayScreen(
                  key: const ValueKey('today'),
                  controller: widget.controller,
                  onVisions: () => setState(() => tab = 1),
                ),
                1 => VisionsScreen(
                  key: const ValueKey('visions'),
                  controller: widget.controller,
                ),
                2 => MemoriesScreen(
                  key: const ValueKey('memories'),
                  controller: widget.controller,
                ),
                _ => SettingsScreen(
                  key: const ValueKey('settings'),
                  controller: widget.controller,
                ),
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: muted.withValues(alpha: .15))),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          height: 76,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined, size: 22),
              selectedIcon: Icon(Icons.wb_sunny, size: 22),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.filter_none_rounded, size: 22),
              selectedIcon: Icon(Icons.filter_rounded, size: 22),
              label: 'Visions',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, size: 22),
              selectedIcon: Icon(Icons.auto_awesome, size: 22),
              label: 'Memories',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded, size: 22),
              label: 'Settings',
            ),
          ],
        ),
      ),
    ),
  );
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.controller,
    required this.onVisions,
  });
  final StillController controller;
  final VoidCallback onVisions;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int page = 0;
  final pager = PageController();
  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, active = widget.controller.surfaced;
    final tone = c.data.preferences.tone;
    final date = c.clock();
    return ListView(
      padding: const EdgeInsets.only(top: 18, bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Row(
            children: [
              Text('still', style: editorial(38, weight: FontWeight.w600)),
              const Spacer(),
              if (c.data.preferences.demo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: muted.withValues(alpha: .25)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Eyebrow('Demo'),
                ),
              const SizedBox(width: 12),
              const Icon(Icons.spa_outlined, size: 22, color: muted),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(
                '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1]} · ${monthDate(date).split(' ').first} ${date.day}',
              ),
              const SizedBox(height: 13),
              Text(
                tone == Tone.none ? 'Your space, today.' : 'Keep this alive.',
                style: editorial(44),
              ),
              const SizedBox(height: 12),
              Text(
                switch (tone) {
                  Tone.grounded =>
                    'A little attention for what matters to you.',
                  Tone.motivational =>
                    'You’ve already started. One more small move.',
                  Tone.manifestation =>
                    'Picture it clearly. Take one step toward it.',
                  Tone.none => 'Your visions and next moves.',
                },
                style: const TextStyle(fontSize: 12, color: muted, height: 1.6),
              ),
            ],
          ),
        ),
        if (c.data.preferences.visionDraft.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: OutlinedButton.icon(
              onPressed: () => newVision(context, c),
              icon: const Icon(Icons.edit_note),
              label: const Text('Continue your saved vision'),
            ),
          ),
        if (active.isEmpty)
          EmptyMoment(
            title: 'A little space for possibility.',
            body: 'What would you like to keep close right now?',
            action: FilledButton(
              onPressed: () => newVision(context, c),
              child: const Text('Create a vision'),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: TodayAction(
              key: ValueKey(active[page.clamp(0, active.length - 1)].id),
              controller: c,
              id: active[page.clamp(0, active.length - 1)].id,
              onOpen: () => openVision(
                context,
                c,
                active[page.clamp(0, active.length - 1)].id,
              ),
            ),
          ),
          SizedBox(
            height: 358,
            child: PageView.builder(
              controller: pager,
              itemCount: active.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (context, index) {
                final v = active[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GestureDetector(
                    onTap: () => openVision(context, c, v.id),
                    child: Semantics(
                      button: true,
                      label: 'Open ${v.title}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Photo(v.imagePath, radius: 0),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [.35, 1],
                                  colors: [
                                    Colors.transparent,
                                    Color(0xBB17251D),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 18,
                              left: 18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cream.withValues(alpha: .92),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 5,
                                      color: pine,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      rhythmName(v.rhythm),
                                      style: const TextStyle(
                                        color: pine,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              top: 10,
                              child: IconButton(
                                onPressed: () => VisionDetail(
                                  controller: c,
                                  id: v.id,
                                ).more(context, v),
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                ),
                                tooltip: 'More options',
                              ),
                            ),
                            Positioned(
                              bottom: 24,
                              left: 22,
                              right: 22,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Eyebrow(
                                    v.area,
                                    color: const Color(0xFFE0E5D8),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    v.title,
                                    style: editorial(35, color: Colors.white),
                                  ),
                                  if (v.why.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '“${v.why}”',
                                      style: const TextStyle(
                                        color: Color(0xFFE7E9DE),
                                        fontSize: 12,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              active.length,
              (i) => GestureDetector(
                onTap: () => pager.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: Semantics(
                  button: true,
                  label: 'Vision ${i + 1}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 7,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == page.clamp(0, active.length - 1) ? 22 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == page.clamp(0, active.length - 1)
                            ? pine
                            : muted.withValues(alpha: .25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: focus(active[page.clamp(0, active.length - 1)]),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Eyebrow('Right now')),
                  Flexible(
                    child: TextButton(
                      onPressed: widget.onVisions,
                      child: Text(
                        '${active.length} of 3 active visions  ↗',
                        style: const TextStyle(fontSize: 11, color: muted),
                      ),
                    ),
                  ),
                ],
              ),
              if (!c.data.preferences.profile.saved && !c.data.preferences.demo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune),
                    title: const Text('Make this more personal'),
                    subtitle: const Text(
                      'Four optional questions, one at a time.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileScreen(controller: c),
                      ),
                    ),
                  ),
                ),
              if (c.reviewDue) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(controller: c),
                    ),
                  ),
                  child: Paper(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.spa_outlined, size: 26, color: muted),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Still yours?', style: editorial(26)),
                              const SizedBox(height: 5),
                              const Text(
                                'A quiet moment for your weekly check-in.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18, color: muted),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 25),
              const Text(
                'Weekly direction. Daily visibility. No daily pressure.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 9, letterSpacing: .1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget focus(Vision v) {
    final c = widget.controller;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Column(
        key: ValueKey('${v.id}-${c.isResting(v.id)}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VisionProgress(controller: c, vision: v),
          const SizedBox(height: 18),
          if (v.obstacle.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text(
                'Your direction',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                barriers[v.obstacle] ?? 'A plan that fits your life',
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    barrierHelp(v.obstacle),
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ],
            ),
          ],
          if (c.proofs(v.id).isNotEmpty) ...[
            const SizedBox(height: 12),
            Paper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Your latest moment'),
                  const SizedBox(height: 10),
                  Text(
                    c.proofs(v.id).first.note.isEmpty
                        ? 'A photo you kept.'
                        : c.proofs(v.id).first.note,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    shortDate(c.proofs(v.id).first.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => openVision(context, c, v.id),
                    child: const Text('See your story'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => showProof(context, c, v.id),
                icon: const Icon(Icons.add_circle_outline, size: 15),
                label: const Text('Add Proof', style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => openVision(context, c, v.id),
                child: Text(
                  '${c.proofs(v.id).length} moments kept  ↗',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VisionsScreen extends StatelessWidget {
  const VisionsScreen({super.key, required this.controller});
  final StillController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(26, 30, 26, 40),
    children: [
      Row(
        children: [
          const Eyebrow('Room for what matters'),
          const Spacer(),
          IconButton(
            onPressed: () => newVision(context, controller),
            icon: const Icon(Icons.add),
            tooltip: 'Create a vision',
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text('Your visions.', style: editorial(44)),
      const SizedBox(height: 12),
      const Text(
        'Some close. Some waiting. All part of your story.',
        style: TextStyle(color: muted, fontSize: 12, height: 1.7),
      ),
      const SizedBox(height: 28),
      for (final status in VisionStatus.values) ...[
        Row(
          children: [
            Eyebrow(switch (status) {
              VisionStatus.active => 'Right Now',
              VisionStatus.later => 'Later',
              VisionStatus.completed => 'It Happened',
              VisionStatus.letGo => 'Let Go',
            }),
            const Spacer(),
            Text(
              '${controller.data.visions.where((v) => v.status == status).length}${status == VisionStatus.active ? ' / 3' : ''}',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!controller.data.visions.any((v) => v.status == status))
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(switch (status) {
              VisionStatus.active => 'What would you like to keep close?',
              VisionStatus.later => 'A place for “not right now.”',
              VisionStatus.completed => 'One day, a vision becomes a memory.',
              VisionStatus.letGo => 'Room for the things you’ve outgrown.',
            }, style: const TextStyle(fontSize: 12, color: muted, height: 1.7)),
          ),
        ...controller.data.visions
            .where((v) => v.status == status)
            .map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => openVision(context, controller, v.id),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      Photo(v.imagePath, width: 92, height: 110, radius: 14),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.title, style: editorial(26)),
                            const SizedBox(height: 7),
                            Text(
                              v.progressPercent == null
                                  ? 'Milestones not set'
                                  : v.measure == ProgressMeasure.milestones
                                  ? '${v.progressPercent}% · ${v.milestonesDone}/${v.milestones.length} milestones'
                                  : '${v.progressPercent}% · ${valueText(v.valueTotal)} / ${valueText(v.valueTarget)} ${v.valueUnit}',
                              style: const TextStyle(fontSize: 12, height: 1.5),
                            ),
                            Text(
                              v.targetDate == null
                                  ? 'Started ${shortDate(v.createdAt)}'
                                  : 'Target ${shortDate(v.targetDate!)}',
                              style: const TextStyle(fontSize: 12, height: 1.5),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              rhythmName(v.rhythm),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                              ),
                            ),
                            if (controller.move(v) != null) ...[
                              const SizedBox(height: 9),
                              Text(
                                controller.move(v)!.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 18, color: muted),
                    ],
                  ),
                ),
              ),
            ),
        const Divider(),
      ],
      OutlinedButton.icon(
        onPressed: () => newVision(context, controller),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Make space for a vision'),
      ),
    ],
  );
}

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key, required this.controller});
  final StillController controller;
  @override
  Widget build(BuildContext context) {
    final completed = controller.data.visions
        .where((v) => v.status == VisionStatus.completed)
        .toList();
    final proofs = [...controller.data.proofs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(26, 36, 26, 36),
      children: [
        const Eyebrow('Evidence of a life unfolding'),
        const SizedBox(height: 16),
        Text('It became real.', style: editorial(44)),
        const SizedBox(height: 14),
        const Text(
          'The moments you kept. The things that happened.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.7),
        ),
        const SizedBox(height: 30),
        if (completed.isEmpty)
          const Paper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_outlined, color: muted),
                SizedBox(height: 14),
                Text(
                  'Your story is still unfolding.',
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 10),
                Text(
                  'When a vision happens, its before and after will live here. Until then, the little things count.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.8),
                ),
              ],
            ),
          ),
        for (final v in completed)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: InkWell(
              onTap: () => openVision(context, controller, v.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Photo(
                    controller
                            .proofs(v.id)
                            .where((p) => p.imagePath != null)
                            .firstOrNull
                            ?.imagePath ??
                        v.imagePath,
                    height: 230,
                  ),
                  const SizedBox(height: 16),
                  const Eyebrow('It happened'),
                  const SizedBox(height: 8),
                  Text(v.title, style: editorial(30)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 30),
        Text('Your moments.', style: editorial(32)),
        const SizedBox(height: 20),
        if (proofs.isEmpty)
          const EmptyMoment(
            title: 'Nothing to prove.\nJust things to keep.',
            body:
                'Add a note or photo to any vision.\nYour memories will find their way here.',
            icon: Icons.photo_album_outlined,
          )
        else
          ProofTimeline(proofs: proofs, controller: controller),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final StillController controller;
  Future<void> attempt(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(26, 36, 26, 36),
    children: [
      const Eyebrow('Make yourself at home'),
      const SizedBox(height: 16),
      Text('Your kind of quiet.', style: editorial(42)),
      const SizedBox(height: 20),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.person_outline),
        title: const Text('A little about you'),
        subtitle: const Text(
          'Life roles, priorities, obstacles, and time for a small step. Optional and editable.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(controller: controller),
          ),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.menu_book_outlined),
        title: const Text('Why these questions'),
        subtitle: const Text(
          'Research, how your answers are used, and the limits of the evidence.',
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ResearchScreen()),
        ),
      ),
      const SizedBox(height: 30),
      const Eyebrow('How Still speaks'),
      const SizedBox(height: 10),
      const Text(
        'Choose the wording that feels useful. Tone changes the language, not your goals or how progress is measured.',
        style: TextStyle(color: muted, height: 1.6),
      ),
      const SizedBox(height: 14),
      ...Tone.values.map(
        (t) => RadioListTile<Tone>(
          contentPadding: EdgeInsets.zero,
          title: Text(toneName(t), style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            '${toneDescription(t)}\n\nToday preview: “${toneExample(t)}”',
            style: const TextStyle(fontSize: 12, height: 1.6),
          ),
          value: t,
          groupValue: controller.data.preferences.tone,
          onChanged: (t) =>
              attempt(context, () => controller.preferences(tone: t)),
        ),
      ),
      const Divider(),
      const Eyebrow('Appearance'),
      const SizedBox(height: 14),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'light', label: Text('Light')),
          ButtonSegment(value: 'dark', label: Text('Dark')),
          ButtonSegment(value: 'system', label: Text('System')),
        ],
        selected: {controller.data.preferences.theme},
        onSelectionChanged: (s) =>
            attempt(context, () => controller.preferences(theme: s.first)),
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.notifications_none),
        title: const Text('Gentle reminders', style: TextStyle(fontSize: 14)),
        subtitle: const Text(
          'Coming later. No notifications are sent.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'A little nudge.\nWhen you want one.',
              style: editorial(30),
            ),
            content: const Text(
              'Reminders aren’t available in this MVP. Your weekly check-in will be waiting inside the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Sounds good'),
              ),
            ],
          ),
        ),
      ),
      const Divider(),
      const Eyebrow('A little about Still'),
      const SizedBox(height: 16),
      const Text(
        'This keeps the things that matter from disappearing when life gets busy.',
        style: TextStyle(fontSize: 15, height: 1.8),
      ),
      const SizedBox(height: 14),
      const Text(
        'Version 1.2 · Your space stays on this device.\nOptional personal guidance. No account. No streaks.',
        style: TextStyle(color: muted, fontSize: 11, height: 1.9),
      ),
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.spa_outlined),
        title: const Text(
          'Take a weekly pause',
          style: TextStyle(fontSize: 13),
        ),
        onTap: controller.active.isEmpty
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(controller: controller),
                ),
              ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history),
        title: const Text(
          'Preview a gentle return',
          style: TextStyle(fontSize: 13),
        ),
        subtitle: const Text(
          'Simulate coming back after 15 days',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        onTap: controller.active.isEmpty
            ? null
            : () => attempt(context, controller.simulateReturn),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.refresh),
        title: const Text('Start fresh', style: TextStyle(fontSize: 13)),
        subtitle: const Text(
          'Clear the visions and photos on this device',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        onTap: () async {
          final reset = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Make a fresh start?', style: editorial(30)),
              content: const Text(
                'This permanently removes all visions, proof, photos, and preferences from this device. It cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep my space'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear everything'),
                ),
              ],
            ),
          );
          if (reset == true && context.mounted) {
            await attempt(context, controller.reset);
          }
        },
      ),
      const SizedBox(height: 20),
      const Center(
        child: Text(
          'Made for the life you’re actually living.',
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ),
    ],
  );
}
