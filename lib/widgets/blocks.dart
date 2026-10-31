import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart';
import '../database.dart';
import '../schema/all.dart';

/// Custom (non-field) cards used by some pages. Chosen by G.block.
Widget buildBlock(String name, Color accent) {
  switch (name) {
    case 'carryover':
      return const CarryOverBlock();
    case 'bills':
      return BillsBlock(accent: accent);
    case 'custom_habits':
      return const CustomHabitsBlock();
    case 'streaks':
      return const DefaultStreaksBlock();
    case 'build_streaks':
      return const BuildStreaksBlock();
    case 'clean':
      return const CleanBlock();
    case 'ideareview':
      return const IdeaReviewBlock();
  }
  return const SizedBox.shrink();
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

// Tasks: carry over from yesterday --------------------------------------------

class CarryOverBlock extends StatelessWidget {
  const CarryOverBlock({super.key});

  List<String> _candidates() {
    final y = dateKey(parseKey(store.date).subtract(const Duration(days: 1)));
    final yd = store.recent[y];
    if (yd == null) return const <String>[];
    final texts = <String>[];
    for (final r in rowsIn(yd, 'closeout.pending')) {
      final t = asStr(r['t']);
      if (t != null) texts.add(t);
    }
    for (final r in rowsIn(yd, 'tasks.tasks')) {
      final t = asStr(r['task']);
      final st = r['status'];
      if (t != null && (st == null || st == 'todo' || st == 'doing' || st == 'moved to later')) {
        texts.add(t);
      }
    }
    final today = {
      for (final r in rowsIn(store.data, 'tasks.tasks'))
        if (asStr(r['task']) != null) asStr(r['task'])!.trim().toLowerCase(),
    };
    final seen = <String>{};
    final out = <String>[];
    for (final t in texts) {
      final k = t.trim().toLowerCase();
      if (today.contains(k) || !seen.add(k)) continue;
      out.add(t);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = _candidates();
    if (c.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From yesterday', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final t in c.take(6)) Text('• $t'),
            if (c.length > 6) Text('and ${c.length - 6} more'),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.move_down),
              label: Text('Bring ${c.length} into today'),
              onPressed: () {
                for (final t in c) {
                  store.addRow(groupKey('tasks', 'tasks'),
                      {'task': t, 'status': 'todo', 'group': 'should do'});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Money: bills due ---------------------------------------------------------------

class BillsBlock extends StatelessWidget {
  const BillsBlock({super.key, required this.accent});
  final Color accent;

  String? _paidOn(Ctx c, String key) {
    String? find(Map<String, dynamic> d) {
      final v = d['bills.paid'];
      if (v is Map && v.containsKey(key)) return v[key].toString();
      return null;
    }

    return find(c.data) ?? c.recentDatesDesc.map((k) => find(c.recent[k]!)).whereType<String>().firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = currentCtx();
    if (appState.items('bills').isEmpty) {
      return const _Hint('Add your bills and subscriptions in Master data. '
          'Bills due in the next 7 days will show up here.');
    }
    final due = billsDue(store.date);
    if (due.isEmpty) return const _Hint('No bills due in the next 7 days.');
    final today = parseKey(store.date);
    return Column(
      children: [
        for (final b in due)
          Builder(builder: (context) {
            final paidOn = _paidOn(ctx, b.key);
            final overdue = paidOn == null && b.due.isBefore(today);
            final amount = numOf(b.item['amount']);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: paidOn != null,
              title: Text(b.item['name']?.toString() ?? 'Bill'),
              subtitle: Text([
                'due ${fmtShort(dateKey(b.due))}',
                if (amount != null) fmtNum(amount),
                if (b.item['auto'] == true) 'auto-pay',
                if (paidOn != null) 'paid ${fmtShort(paidOn)}',
                if (overdue) 'OVERDUE',
              ].join('  ·  ')),
              onChanged: (v) {
                final m = store.data['bills.paid'] is Map
                    ? Map<String, dynamic>.from(store.data['bills.paid'] as Map)
                    : <String, dynamic>{};
                if (v == true) {
                  m[b.key] = store.date;
                } else {
                  m.remove(b.key);
                }
                store.set('bills.paid', m.isEmpty ? null : m);
              },
            );
          }),
      ],
    );
  }
}

// Habits: master-data habits ------------------------------------------------------

class CustomHabitsBlock extends StatelessWidget {
  const CustomHabitsBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final items = appState.items('habits');
    if (items.isEmpty) {
      return const _Hint('Add your own habits in Master data > Habits and tick them off here.');
    }
    final done = store.data['hab_daily.custom'] is Map
        ? Map<String, dynamic>.from(store.data['hab_daily.custom'] as Map)
        : <String, dynamic>{};
    return Column(
      children: [
        for (final h in items)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: done['${h['_id']}'] == true,
            title: Text(h['name']?.toString() ?? 'Habit'),
            subtitle: Text(h['kind'] == 'break' ? 'Avoided today' : 'Done today'),
            onChanged: (v) {
              final m = Map<String, dynamic>.from(done);
              if (v == true) {
                m['${h['_id']}'] = true;
              } else {
                m.remove('${h['_id']}');
              }
              store.set('hab_daily.custom', m.isEmpty ? null : m);
            },
          ),
      ],
    );
  }
}

// Habits: streaks ---------------------------------------------------------------

class _StreakTile extends StatelessWidget {
  const _StreakTile(this.name, this.s);
  final String name;
  final ({int current, int best}) s;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(name),
        trailing: Text('${s.current} now  ·  best ${s.best}'),
      );
}

class DefaultStreaksBlock extends StatelessWidget {
  const DefaultStreaksBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = currentCtx();
    double n(Map<String, dynamic> d, String k) => numOf(d[k])?.toDouble() ?? 0;
    final tests = <String, bool Function(Map<String, dynamic>)>{
      'Prayer': (d) => n(d, 'hab_daily.prayer') > 0,
      'Reading': (d) => n(d, 'hab_daily.reading') > 0,
      'Walking or exercise': (d) => exerciseMinutes(d) > 0,
      'Water target met': (d) {
        final t = numOf(appState.targets['water']);
        return t != null && n(d, 'hydration.water') >= t;
      },
      'Screen time under limit': (d) {
        final l = numOf(appState.targets['screen']);
        return l != null && d['screen.total'] != null && n(d, 'screen.total') <= l;
      },
      'Skill practice': (d) => sumRows(d, 'study.items', 'time') + sumRows(d, 'training.items', 'time') > 0,
      'Journal or gratitude': (d) => d['hab_daily.journal'] == true,
      'Slept on time': (d) => sleptOnTarget(d) == true,
      'Woke on time': (d) => wokeOnTarget(d) == true,
      'Stretching': (d) => n(d, 'hab_daily.stretch') > 0,
      'Meditation or breathing': (d) => n(d, 'hab_daily.meditate') > 0,
      'Sunlight': (d) => n(d, 'hab_daily.sunlight') > 0,
      'No phone in first hour': (d) => d['hab_daily.nophone'] == true,
      'Planned tomorrow': (d) => d['hab_daily.planned'] == true,
      'Tidied up': (d) => d['hab_daily.tidied'] == true,
    };
    final tiles = <Widget>[];
    tests.forEach((name, test) {
      final s = streakOf(c, test);
      if (s.best > 0) tiles.add(_StreakTile(name, s));
    });
    if (tiles.isEmpty) {
      return const _Hint('Streaks appear here once you log a habit on consecutive days '
          '(looks back 90 days).');
    }
    return Column(children: tiles);
  }
}

class BuildStreaksBlock extends StatelessWidget {
  const BuildStreaksBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = currentCtx();
    final names = <String>{};
    for (final d in [c.data, ...c.recent.values]) {
      for (final r in rowsIn(d, 'building.items')) {
        final h = asStr(r['habit']);
        if (h != null) names.add(h.trim());
      }
    }
    if (names.isEmpty) return const _Hint('Log a habit above to see its streak.');
    return Column(
      children: [
        for (final h in names)
          _StreakTile(
            h,
            streakOf(c, (d) => rowsIn(d, 'building.items').any((r) =>
                (asStr(r['habit']) ?? '').trim().toLowerCase() == h.toLowerCase() &&
                r['tiny'] == true)),
          ),
      ],
    );
  }
}

class CleanBlock extends StatelessWidget {
  const CleanBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = currentCtx();
    final names = <String>{};
    for (final d in [c.data, ...c.recent.values]) {
      for (final r in rowsIn(d, 'breaking.items')) {
        final h = asStr(r['habit']);
        if (h != null) names.add(h.trim());
      }
    }
    if (names.isEmpty) return const _Hint('Log a habit you are breaking to track days clean.');
    return Column(
      children: [
        for (final h in names)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(h),
            trailing: Text(() {
              final n = daysClean(c, h);
              return n == null ? '-' : '$n days';
            }()),
          ),
      ],
    );
  }
}

// Ideaverse: review old ideas ------------------------------------------------------

class IdeaReviewBlock extends StatelessWidget {
  const IdeaReviewBlock({super.key});

  Future<void> _set(IdeaRef i, String status) async {
    final d = await TrackerDb.load(i.date);
    final rows = d['ideas.ideas'];
    if (rows is List) {
      for (final r in rows) {
        if (r is Map && r['_id'].toString() == i.id) r['status'] = status;
      }
      await TrackerDb.save(i.date, d);
      store.recent[i.date] = d;
      store.bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = oldNewIdeas(currentCtx());
    if (list.isEmpty) return const _Hint('No ideas waiting for review. Nice.');
    return Column(
      children: [
        for (final i in list.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title, style: Theme.of(context).textTheme.titleSmall),
                Text('captured ${fmtShort(i.date)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(label: const Text('Act on it'), onPressed: () => _set(i, 'planned')),
                    ActionChip(label: const Text('Park'), onPressed: () => _set(i, 'parked')),
                    ActionChip(label: const Text('Drop'), onPressed: () => _set(i, 'dropped')),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
