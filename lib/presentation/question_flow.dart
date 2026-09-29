import 'package:flutter/material.dart';
import 'design.dart';

/// A focused question with persistent navigation, real progress, and no auto-advance.
class QuestionFlow extends StatelessWidget {
  const QuestionFlow({
    super.key,
    required this.section,
    required this.step,
    required this.total,
    required this.title,
    required this.hint,
    required this.child,
    required this.onBack,
    required this.onClose,
    required this.onContinue,
    this.button = 'Continue',
    this.busy = false,
    this.optional = false,
    this.onSkip,
    this.error,
  });
  final String section, title, hint, button;
  final int step, total;
  final Widget child;
  final VoidCallback? onBack, onClose, onContinue, onSkip;
  final bool busy, optional;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: busy ? null : onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(section, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Save and close',
            onPressed: busy ? null : onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${step + 1} of $total${step == total - 1
                          ? ' · Review'
                          : optional
                          ? ' · Optional'
                          : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: step / total,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(10),
                      semanticsLabel:
                          '$section progress. $step of $total steps completed',
                      semanticsValue: '${(100 * step / total).round()}',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('$section-$step'),
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          title,
                          style: editorial(
                            MediaQuery.sizeOf(context).width < 360 ? 30 : 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 26),
                      child,
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: colors.error,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: busy ? null : onContinue,
                        child: Text(busy ? 'Saving…' : button),
                      ),
                      if (onSkip != null)
                        TextButton(
                          onPressed: busy ? null : onSkip,
                          child: const Text('Skip this question'),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Progress saved on this device when you continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnswerCard extends StatelessWidget {
  const AnswerCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.multiple = false,
  });
  final String label;
  final String? description;
  final bool selected, multiple;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Material(
          color: selected ? c.primaryContainer : c.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? c.primary : c.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? c.onPrimaryContainer
                                    : c.onSurface,
                              ),
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: 7),
                            Text(
                              description!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: selected
                                    ? c.onPrimaryContainer
                                    : c.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(
                      multiple
                          ? (selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank)
                          : (selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off),
                      color: c.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewAnswer extends StatelessWidget {
  const ReviewAnswer(this.label, this.value, this.onEdit, {super.key});
  final String label, value;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: Semantics(
                label: 'Change $label',
                child: const Text('Change'),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const Divider(height: 18),
      ],
    ),
  );
}
