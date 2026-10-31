import 'package:flutter/material.dart';

import '../app_state.dart';
import '../schema/all.dart';
import '../widgets/field_view.dart';

/// Master data: lists set up once and reused in dropdowns, plus targets.
class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Master data')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Set these up once. They fill the pick-lists across the app '
                '(goals, people, foods, bills...).',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _tile(context, Icons.tune, 'Targets and limits',
                  'Bedtime, sleep hours, water, steps, screen, budget',
                  () => const TargetsScreen()),
              for (final m in masterLists)
                _tile(context, m.icon, m.title, '${appState.items(m.id).length} saved',
                    () => MasterListScreen(list: m)),
              _tile(context, Icons.label_outline, 'Custom options and tags',
                  'Chips you added to any field', () => const CustomOptionsScreen()),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub,
      Widget Function() page) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page())),
      ),
    );
  }
}

class MasterListScreen extends StatelessWidget {
  const MasterListScreen({super.key, required this.list});

  final MasterList list;

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${appState.itemName(list.id, item)}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await appState.deleteMaster(list.id, item);
  }

  String _sub(Map<String, dynamic> item) {
    final parts = <String>[];
    for (final f in list.fields) {
      if (f.k == list.primary) continue;
      final v = item[f.k];
      if (!isFilled(v)) continue;
      parts.add(v is List ? v.join(', ') : (v is bool ? (v ? 'Yes' : 'No') : v.toString()));
      if (parts.length == 2) break;
    }
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final items = appState.items(list.id);
        return Scaffold(
          appBar: AppBar(title: Text(list.title)),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MasterItemScreen(list: list)),
            ),
          ),
          body: items.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nothing here yet. Tap Add to create the first one.',
                      textAlign: TextAlign.center)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final it = items[i];
                    final name = appState.itemName(list.id, it);
                    return ListTile(
                      title: Text(name.isEmpty ? '(unnamed)' : name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: _sub(it).isEmpty ? null : Text(_sub(it), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, it),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MasterItemScreen(list: list, item: it)),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class MasterItemScreen extends StatefulWidget {
  const MasterItemScreen({super.key, required this.list, this.item});

  final MasterList list;
  final Map<String, dynamic>? item;

  @override
  State<MasterItemScreen> createState() => _MasterItemScreenState();
}

class _MasterItemScreenState extends State<MasterItemScreen> {
  late final Map<String, dynamic> _item;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item ?? <String, dynamic>{});
  }

  bool get _hasContent =>
      widget.list.fields.any((f) => isFilled(_item[f.k]));

  Future<void> _save() async {
    if (!_hasContent) return;
    _dirty = false;
    await appState.upsertMaster(widget.list.id, _item);
  }

  @override
  void dispose() {
    if (_dirty && _hasContent) {
      appState.upsertMaster(widget.list.id, _item);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _item['_id'];
    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? 'New ${widget.list.title}' : widget.list.title),
        actions: [
          TextButton(
            onPressed: () async {
              await _save();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in widget.list.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FieldView(
                f: f,
                scope: 'master|${widget.list.id}|${id ?? 'new'}',
                value: _item[f.k],
                optPath: 'master.${widget.list.id}.${f.k}',
                accent: Theme.of(context).colorScheme.primary,
                onChanged: (v, quiet) {
                  if (isFilled(v) || v is bool || v is num) {
                    _item[f.k] = v;
                  } else {
                    _item.remove(f.k);
                  }
                  _dirty = true;
                  if (!quiet) setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }
}

class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Targets and limits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Used to calculate sleep debt, water goal, steps goal, screen limit and daily budget.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          for (final f in targetFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FieldView(
                f: f,
                scope: 'targets',
                value: appState.targets[f.k],
                optPath: 'targets.${f.k}',
                accent: Theme.of(context).colorScheme.primary,
                onChanged: (v, quiet) async {
                  await appState.setTarget(f.k, v);
                  if (!quiet && mounted) setState(() {});
                },
              ),
            ),
        ],
      ),
    );
  }
}

class CustomOptionsScreen extends StatelessWidget {
  const CustomOptionsScreen({super.key});

  String _label(String path) {
    if (path == 'tags.global') return 'Tags (all pages)';
    final parts = path.split('.');
    if (parts.length >= 2) {
      final page = pageById(parts.first);
      if (page != null) {
        final fieldKey = parts.last;
        for (final g in page.groups) {
          for (final f in g.fields) {
            if (f.k == fieldKey) return '${page.title}: ${f.label}';
          }
        }
        return '${page.title}: $fieldKey';
      }
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final entries = appState.customOptions.entries.toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Custom options and tags')),
          body: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nothing added yet. On any single or multi choice field, tap the "Add" chip '
                      'to create your own option. Long-press one of your options to remove it.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_label(e.key), style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                for (final o in List<String>.from(e.value))
                                  InputChip(
                                    label: Text(o),
                                    onDeleted: () => appState.removeCustomOption(e.key, o),
                                  ),
                              ],
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
}
