import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart';
import '../database.dart';
import '../schema/all.dart';
import '../widgets/tiles.dart';
import 'export_screen.dart';
import 'master_screen.dart';
import 'quick_add.dart';
import 'section_screen.dart';
import 'settings_screen.dart';

/// Home: date bar, today's snapshot, quick add, and the icon grid of sections.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: parseKey(store.date),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) await store.open(dateKey(d));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, appState]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final visible = [for (final s in sections) if (!appState.hiddenSections.contains(s.id)) s];
        final filledPages = allPages.where((p) => store.pageCount(p) > 0).length;
        final stats = _snapshot();
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => store.shift(-1),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _pickDate(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              children: [
                                Text(weekdayOf(store.date),
                                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                                Text(fmtLong(store.date),
                                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => store.shift(1),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      if (!store.isToday)
                        ActionChip(
                          avatar: const Icon(Icons.today, size: 18),
                          label: const Text('Back to today'),
                          onPressed: () => store.open(dateKey(DateTime.now())),
                        ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('$filledPages of ${allPages.length} pages filled'),
                      ),
                    ],
                  ),
                ),
              ),
              if (stats.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [for (final s in stats) _StatBox(label: s.$1, value: s.$2)],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    children: [
                      _quick(context, Icons.water_drop_outlined, 'Water', showQuickWater),
                      _quick(context, Icons.mood, 'Mood', showQuickMood),
                      _quick(context, Icons.payments_outlined, 'Expense', showQuickExpense),
                      _quick(context, Icons.lightbulb_outline, 'Idea', showQuickIdea),
                      _quick(context, Icons.healing_outlined, 'Symptom', showQuickSymptom),
                    ],
                  ),
                ),
              ),
              if (store.loading)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                sliver: SliverGrid.count(
                  crossAxisCount: gridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    for (final s in visible)
                      AppTile(
                        icon: s.icon,
                        title: s.title,
                        subtitle: s.blurb,
                        color: s.color,
                        count: store.sectionCount(s),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SectionScreen(sect: s)),
                        ),
                      ),
                    AppTile(
                      icon: Icons.storage_outlined,
                      title: 'Master data',
                      subtitle: 'Goals, people, bills, targets',
                      color: kNeutral,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const MasterScreen())),
                    ),
                    AppTile(
                      icon: Icons.ios_share,
                      title: 'Export & backup',
                      subtitle: 'Markdown, CSV, JSON',
                      color: const Color(0xFF8A7A5A),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ExportScreen())),
                    ),
                    AppTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Theme, lock, sections',
                      color: const Color(0xFF6B7A8F),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quick(BuildContext context, IconData icon, String label,
      Future<void> Function(BuildContext) fn) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => fn(context),
      ),
    );
  }

  List<(String, String)> _snapshot() {
    final d = store.data;
    final out = <(String, String)>[];
    final sh = sleepHours(d);
    if (sh != null) out.add(('Sleep', '${fmtNum(sh)} h'));
    final m = moodOf(d);
    if (m != null) out.add(('Mood', fmtNum(m)));
    final w = numOf(d['hydration.water']);
    if (w != null) out.add(('Water', '${fmtNum(w)} L'));
    if (rowsIn(d, 'cashflow.expenses').isNotEmpty) out.add(('Spent', fmtNum(totalSpent(d))));
    final steps = numOf(d['move.steps']);
    if (steps != null) out.add(('Steps', fmtNum(steps)));
    final n = tasksPlanned(d);
    if (n > 0) out.add(('Tasks', '${tasksWithStatus(d, 'done')}/$n'));
    final r = numOf(d['daily.rating']);
    if (r != null) out.add(('Day', '${fmtNum(r)}/10'));
    return out;
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(110),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
