import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart';
import '../database.dart';
import '../schema/all.dart';

/// All logged days, newest first, with search across everything you wrote.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, Map<String, dynamic>> _all = {};
  bool _loading = true;
  String _q = '';

  @override
  void initState() {
    super.initState();
    shellTab.addListener(_onTab);
    _load();
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (shellTab.value == 1) _load();
  }

  Future<void> _load() async {
    await store.flush();
    final all = await TrackerDb.loadAll();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  String _summary(Map<String, dynamic> d) {
    final parts = <String>[];
    final r = numOf(d['daily.rating']);
    if (r != null) parts.add('Day ${fmtNum(r)}/10');
    final sh = sleepHours(d);
    if (sh != null) parts.add('Sleep ${fmtNum(sh)} h');
    final m = moodOf(d);
    if (m != null) parts.add('Mood ${fmtNum(m)}');
    if (rowsIn(d, 'cashflow.expenses').isNotEmpty) parts.add('Spent ${fmtNum(totalSpent(d))}');
    final pages = allPages.where((p) => DayStore.countPage(p, d) > 0).length;
    parts.add('$pages pages');
    return parts.join('  ·  ');
  }

  String? _snippet(Map<String, dynamic> d, String q) {
    String? scan(dynamic v) {
      if (v is String) {
        final i = v.toLowerCase().indexOf(q);
        if (i >= 0) {
          final start = i > 30 ? i - 30 : 0;
          final end = i + q.length + 50 > v.length ? v.length : i + q.length + 50;
          return v.substring(start, end);
        }
      } else if (v is List) {
        for (final e in v) {
          final s = scan(e);
          if (s != null) return s;
        }
      } else if (v is Map) {
        for (final e in v.values) {
          final s = scan(e);
          if (s != null) return s;
        }
      }
      return null;
    }

    return scan(d);
  }

  Future<void> _openDay(String date) async {
    await store.open(date);
    shellTab.value = 0;
  }

  Future<void> _addDay() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) await _openDay(dateKey(d));
  }

  Future<void> _delete(String date) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${fmtLong(date)}?'),
        content: const Text('Everything logged on this day will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await TrackerDb.deleteDay(date);
    if (store.date == date) await store.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _q.trim().toLowerCase();
    final dates = _all.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = q.isEmpty
        ? dates
        : [for (final d in dates) if (jsonEncode(_all[d]).toLowerCase().contains(q)) d];
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDay,
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('Add or edit a day'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search everything you wrote',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            q.isEmpty
                                ? 'No days logged yet. Open Today and fill in any section.'
                                : 'Nothing matches "$_q".',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: shown.length,
                        itemBuilder: (context, i) {
                          final d = shown[i];
                          final data = _all[d]!;
                          final snip = q.isEmpty ? null : _snippet(data, q);
                          final day = parseKey(d);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: cs.secondaryContainer,
                              child: Text('${day.day}',
                                  style: TextStyle(color: cs.onSecondaryContainer)),
                            ),
                            title: Text('${weekdayOf(d)}, ${fmtLong(d)}'),
                            subtitle: Text(snip == null ? _summary(data) : '...$snip...',
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openDay(d),
                            onLongPress: () => _delete(d),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
