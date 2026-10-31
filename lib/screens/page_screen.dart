import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart';
import '../schema/all.dart';
import '../widgets/blocks.dart';
import '../widgets/field_view.dart';

/// One page of a section (for example Sleep). Cards for each group,
/// repeat groups as add/remove rows, auto-saves as you type.
class PageScreen extends StatefulWidget {
  const PageScreen({super.key, required this.sect, required this.page});

  final Sect sect;
  final PageDef page;

  @override
  State<PageScreen> createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  @override
  void dispose() {
    store.flush();
    super.dispose();
  }

  PageDef get page => widget.page;
  Color get accent => widget.sect.color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, appState]),
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final ctx = currentCtx();
        final banners = <String>[...advisories(page.id, store.data)];
        const mindPages = {'checkins', 'mind', 'anxiety', 'stress', 'energy'};
        if (mindPages.contains(page.id) && mindStreakFlag(ctx)) {
          banners.add('Mood has been low or anxiety high for three days in a row. '
              'Talking to someone you trust, or a professional, can really help.');
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: accent.withAlpha(36),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.title),
                Text(
                  '${weekdayOf(store.date)}, ${fmtLong(store.date)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Text(
                    store.saving ? 'Saving...' : 'Saved',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          body: store.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 40),
                  children: [
                    for (final b in banners) _Banner(b),
                    for (final g in page.groups)
                      if (g.module == null || appState.modules[g.module] == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _groupCard(context, g, ctx),
                        ),
                    _notesCard(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _groupCard(BuildContext context, G g, Ctx ctx) {
    if (g.block == 'carryover') return buildBlock(g.block!, accent);
    if (g.block != null) {
      return _CardShell(
        title: g.title,
        accent: accent,
        child: buildBlock(g.block!, accent),
      );
    }
    if (g.repeat) return _RepeatCard(sect: widget.sect, page: page, g: g);

    return _CardShell(
      title: g.title,
      accent: accent,
      child: Column(
        children: [
          for (final f in g.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FieldView(
                f: f,
                scope: '${store.date}|${page.id}',
                value: store.data[flatKey(page.id, f.k)],
                optPath: '${page.id}.${f.k}',
                accent: accent,
                autoText: f.type == T.calc ? autoText(page.id, f.k, ctx) : null,
                onChanged: (v, quiet) => store.set(flatKey(page.id, f.k), v, quiet: quiet),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notesCard(BuildContext context) {
    return _CardShell(
      title: 'Notes & tags',
      accent: accent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FieldView(
              f: long('_notes', 'Notes', hint: 'Anything else about this page'),
              scope: '${store.date}|${page.id}',
              value: store.data['${page.id}._notes'],
              optPath: '${page.id}._notes',
              accent: accent,
              onChanged: (v, quiet) => store.set('${page.id}._notes', v, quiet: quiet),
            ),
          ),
          FieldView(
            f: many('_tags', 'Tags', const <String>[]),
            scope: '${store.date}|${page.id}',
            value: store.data['${page.id}._tags'],
            optPath: 'tags.global',
            accent: accent,
            onChanged: (v, quiet) => store.set('${page.id}._tags', v, quiet: quiet),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.title, required this.accent, required this.child});

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_outline, color: cs.onTertiaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: cs.onTertiaryContainer))),
        ],
      ),
    );
  }
}

// Repeat groups -----------------------------------------------------------------

Map<String, dynamic> _defaultsFor(PageDef page, G g) {
  if (page.id == 'checkins') {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'morning' : h < 17 ? 'afternoon' : h < 21 ? 'evening' : 'night';
    return {'part': part};
  }
  if (page.id == 'tasks' && g.id == 'tasks') return {'status': 'todo'};
  if (page.id == 'ideas') return {'status': 'new'};
  return <String, dynamic>{};
}

String _display(dynamic v) {
  if (v is List) return v.join(', ');
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is num) return fmtNum(v);
  return v.toString();
}

class _RepeatCard extends StatelessWidget {
  const _RepeatCard({required this.sect, required this.page, required this.g});

  final Sect sect;
  final PageDef page;
  final G g;

  String get _key => groupKey(page.id, g.id);

  (String, String?) _titles(Map row, int index) {
    final vals = <String>[];
    for (final f in g.fields) {
      if (f.type == T.calc) continue;
      final v = row[f.k];
      if (!isFilled(v)) continue;
      if (f.type == T.text || f.type == T.link || f.type == T.single || f.type == T.long ||
          f.type == T.multi || f.type == T.time) {
        vals.add(_display(v));
      }
      if (vals.length == 2) break;
    }
    final fallback = '${g.item ?? 'Entry'} ${index + 1}';
    if (vals.isEmpty) return (fallback, null);
    return (vals[0], vals.length > 1 ? vals[1] : null);
  }

  @override
  Widget build(BuildContext context) {
    final rows = store.rows(_key);
    final atMax = g.max != null && rows.length >= g.max!;
    final cs = Theme.of(context).colorScheme;
    return _CardShell(
      title: g.title,
      accent: sect.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Nothing logged yet.', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          for (var i = 0; i < rows.length; i++)
            if (rows[i] is Map) _rowTile(context, rows[i] as Map, i, rows.length),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: Text('Add ${(g.item ?? 'entry').toLowerCase()}'),
                  onPressed: atMax
                      ? null
                      : () => store.addRow(_key, _defaultsFor(page, g)),
                ),
                if (g.max != null) ...[
                  const SizedBox(width: 12),
                  Text('${rows.length} of ${g.max}', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(BuildContext context, Map row, int i, int total) {
    final id = row['_id'].toString();
    final cs = Theme.of(context).colorScheme;
    final t = _titles(row, i);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('${store.date}|$_key|$id'),
          initiallyExpanded: i == total - 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          title: Text(t.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: t.$2 == null ? null : Text(t.$2!, maxLines: 1, overflow: TextOverflow.ellipsis),
          children: [
            for (final f in g.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FieldView(
                  f: f,
                  scope: '${store.date}|$_key|$id',
                  value: row[f.k],
                  optPath: '${page.id}.${g.id}.${f.k}',
                  accent: sect.color,
                  onChanged: (v, quiet) => store.setRow(_key, id, f.k, v, quiet: quiet),
                ),
              ),
            Row(
              children: [
                if (g.rowAction != null)
                  TextButton.icon(
                    icon: Icon(g.rowAction!.icon),
                    label: Text(g.rowAction!.label),
                    onPressed: () => _runAction(context, row),
                  ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  onPressed: () => _confirmRemove(context, id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _runAction(BuildContext context, Map row) {
    final a = g.rowAction!;
    final values = <String, dynamic>{...a.extra};
    a.map.forEach((from, to) {
      for (final alt in from.split('|')) {
        if (isFilled(row[alt])) {
          values[to] = row[alt];
          break;
        }
      }
    });
    store.addRow(groupKey(a.toPage, a.toGroup), values);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added to ${pageById(a.toPage)?.title ?? 'tasks'}')));
  }

  Future<void> _confirmRemove(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) store.removeRow(_key, id);
  }
}
