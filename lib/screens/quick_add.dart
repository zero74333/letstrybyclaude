import 'package:flutter/material.dart';

import '../app_state.dart';
import '../schema/all.dart';

/// Quick-add sheets for the dashboard: water, mood, expense, idea, symptom.
/// They write into the day currently open.

Future<void> _sheet(BuildContext context, String title, Widget Function(BuildContext) body) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            body(ctx),
          ],
        ),
      ),
    ),
  );
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

// Water ---------------------------------------------------------------------------

Future<void> showQuickWater(BuildContext context) {
  return _sheet(context, 'Add water', (ctx) {
    return StatefulBuilder(builder: (ctx, setState) {
      final cur = numOf(store.data['hydration.water'])?.toDouble() ?? 0;
      final target = numOf(appState.targets['water']);
      void add(double l) {
        final v = ((cur + l) * 100).round() / 100;
        store.set('hydration.water', v);
        setState(() {});
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today: ${fmtNum(cur)} L${target == null ? '' : ' of ${fmtNum(target)} L'}',
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final ml in [250, 500, 750, 1000])
                ActionChip(label: Text('+$ml ml'), onPressed: () => add(ml / 1000)),
              ActionChip(
                label: const Text('Undo 250 ml'),
                onPressed: () {
                  if (cur > 0) add(-0.25);
                },
              ),
            ],
          ),
        ],
      );
    });
  });
}

// Mood ----------------------------------------------------------------------------

Future<void> showQuickMood(BuildContext context) {
  final key = groupKey('checkins', 'checkins');
  if (store.rows(key).length >= 4) {
    _toast(context, 'Four check-ins already logged today. Edit them in Mind & Mood.');
    return Future<void>.value();
  }
  return _sheet(context, 'Mood check-in', (ctx) => _MoodSheet(parent: context));
}

class _MoodSheet extends StatefulWidget {
  const _MoodSheet({required this.parent});
  final BuildContext parent;

  @override
  State<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<_MoodSheet> {
  int? mood;
  final Set<String> picked = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => mood = i),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mood == i ? sMind.color : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$i',
                          style: TextStyle(
                              color: mood == i ? Colors.white : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          children: [
            for (final e in emotions.take(12))
              FilterChip(
                label: Text(e),
                selected: picked.contains(e),
                visualDensity: VisualDensity.compact,
                onSelected: (s) => setState(() {
                  if (s) {
                    picked.add(e);
                  } else {
                    picked.remove(e);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: mood == null
              ? null
              : () {
                  final h = DateTime.now().hour;
                  final part = h < 12 ? 'morning' : h < 17 ? 'afternoon' : h < 21 ? 'evening' : 'night';
                  store.addRow(groupKey('checkins', 'checkins'), {
                    'part': part,
                    'mood': mood,
                    if (picked.isNotEmpty) 'emotions': picked.toList(),
                  });
                  Navigator.pop(context);
                  _toast(widget.parent, 'Mood $mood logged');
                },
          child: const Text('Save check-in'),
        ),
      ],
    );
  }
}

// Expense -------------------------------------------------------------------------

Future<void> showQuickExpense(BuildContext context) {
  return _sheet(context, 'Add expense', (ctx) => _ExpenseSheet(parent: context));
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.parent});
  final BuildContext parent;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final item = TextEditingController();
  final amount = TextEditingController();
  String? cat;

  @override
  void dispose() {
    item.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = <String>[
      ...appState.names('expcats'),
      if (appState.names('expcats').isEmpty) ...['food', 'groceries', 'transport', 'bills and utilities', 'shopping', 'other'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: item,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What for', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: [
            for (final c in cats)
              ChoiceChip(
                label: Text(c),
                selected: cat == c,
                visualDensity: VisualDensity.compact,
                onSelected: (s) => setState(() => cat = s ? c : null),
              ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            final a = num.tryParse(amount.text.trim());
            if (a == null) return;
            store.addRow(groupKey('cashflow', 'expenses'), {
              if (item.text.trim().isNotEmpty) 'item': item.text.trim(),
              'amount': a,
              if (cat != null) 'cat': cat,
            });
            Navigator.pop(context);
            _toast(widget.parent, 'Expense saved');
          },
          child: const Text('Save expense'),
        ),
      ],
    );
  }
}

// Idea ----------------------------------------------------------------------------

Future<void> showQuickIdea(BuildContext context) {
  return _sheet(context, 'Capture an idea', (ctx) => _IdeaSheet(parent: context));
}

class _IdeaSheet extends StatefulWidget {
  const _IdeaSheet({required this.parent});
  final BuildContext parent;

  @override
  State<_IdeaSheet> createState() => _IdeaSheetState();
}

class _IdeaSheetState extends State<_IdeaSheet> {
  final title = TextEditingController();
  final details = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: title,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Idea', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: details,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Details (optional)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 4),
        Text('Sort and score it later in Ideaverse > Idea inbox.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            if (title.text.trim().isEmpty) return;
            store.addRow(groupKey('ideas', 'ideas'), {
              'title': title.text.trim(),
              if (details.text.trim().isNotEmpty) 'details': details.text.trim(),
              'status': 'new',
            });
            Navigator.pop(context);
            _toast(widget.parent, 'Idea captured');
          },
          child: const Text('Save idea'),
        ),
      ],
    );
  }
}

// Symptom -------------------------------------------------------------------------

Future<void> showQuickSymptom(BuildContext context) {
  return _sheet(context, 'Log a symptom', (ctx) => _SymptomSheet(parent: context));
}

class _SymptomSheet extends StatefulWidget {
  const _SymptomSheet({required this.parent});
  final BuildContext parent;

  @override
  State<_SymptomSheet> createState() => _SymptomSheetState();
}

class _SymptomSheetState extends State<_SymptomSheet> {
  String? symptom;
  int? sev;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final symptoms = [
      'headache', 'body pain', 'back or neck pain', 'eye strain', 'cough',
      'cold or runny nose', 'fever', 'dizziness', 'fatigue', 'skin issue',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final s in symptoms)
              ChoiceChip(
                label: Text(s),
                selected: symptom == s,
                visualDensity: VisualDensity.compact,
                onSelected: (v) => setState(() => symptom = v ? s : null),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Severity (10 = worst)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => sev = i),
                    child: Container(
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sev == i ? sHealth.color : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$i',
                          style: TextStyle(
                              color: sev == i ? Colors.white : cs.onSurfaceVariant)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: symptom == null
              ? null
              : () {
                  final now = TimeOfDay.now();
                  store.addRow(groupKey('body', 'symptoms'), {
                    'symptom': symptom,
                    if (sev != null) 'sev': sev,
                    'start':
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  });
                  Navigator.pop(context);
                  _toast(widget.parent, 'Symptom logged');
                },
          child: const Text('Save symptom'),
        ),
      ],
    );
  }
}
