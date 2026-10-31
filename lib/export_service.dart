import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_state.dart';
import 'auto.dart';
import 'database.dart';
import 'metrics.dart';
import 'schema/all.dart';

class ExportService {
  static String _val(dynamic v) {
    if (v is List) return v.join(', ');
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is num) return fmtNum(v);
    return v.toString().replaceAll('\n', ' ');
  }

  static String buildMarkdown(Map<String, Map<String, dynamic>> all) {
    final b = StringBuffer('# Zeeshan Daily Life Style: Export\n\n');
    final dates = all.keys.toList()..sort();
    for (final date in dates) {
      final d = all[date]!;
      final day = StringBuffer();
      for (final s in sections) {
        final sect = StringBuffer();
        for (final p in s.pages) {
          final lines = <String>[];
          for (final g in p.groups) {
            if (g.block != null) continue;
            if (g.repeat) {
              final rows = rowsIn(d, groupKey(p.id, g.id));
              for (var i = 0; i < rows.length; i++) {
                final parts = [
                  for (final f in g.fields)
                    if (f.type != T.calc && isFilled(rows[i][f.k]))
                      '${f.label}: ${_val(rows[i][f.k])}',
                ];
                if (parts.isNotEmpty) {
                  lines.add('- ${g.item ?? g.title} ${i + 1}: ${parts.join('; ')}');
                }
              }
            } else {
              for (final f in g.fields) {
                if (f.type == T.calc) continue;
                final v = d[flatKey(p.id, f.k)];
                if (isFilled(v)) lines.add('- ${f.label}: ${_val(v)}');
              }
            }
          }
          final notes = d['${p.id}._notes'];
          if (isFilled(notes)) lines.add('- Notes: ${_val(notes)}');
          final tags = d['${p.id}._tags'];
          if (isFilled(tags)) lines.add('- Tags: ${_val(tags)}');
          if (lines.isEmpty) continue;
          sect.writeln('#### ${p.title}');
          for (final l in lines) {
            sect.writeln(l);
          }
          sect.writeln();
        }
        if (sect.isNotEmpty) {
          day.writeln('### ${s.title}');
          day.writeln();
          day.write(sect);
        }
      }
      if (day.isNotEmpty) {
        b.writeln('## $date (${weekdayOf(date)})');
        b.writeln();
        b.write(day);
      }
    }
    return b.toString();
  }

  static String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String buildCsv(Map<String, Map<String, dynamic>> all) {
    final fields = <(String, F)>[];
    for (final p in allPages) {
      for (final g in p.groups) {
        if (g.repeat || g.block != null) continue;
        for (final f in g.fields) {
          if (f.type != T.calc) fields.add((flatKey(p.id, f.k), f));
        }
      }
    }
    final derived = buildMetrics().where((m) => m.id.startsWith('d.')).toList();
    final header = <String>[
      'date',
      for (final f in fields) f.$1,
      for (final m in derived) 'calc: ${m.label}',
    ];
    final out = StringBuffer('${header.map(_csv).join(',')}\n');
    final dates = all.keys.toList()..sort();
    for (final date in dates) {
      final d = all[date]!;
      final row = <String>[
        date,
        for (final f in fields) isFilled(d[f.$1]) ? _val(d[f.$1]) : '',
        for (final m in derived) (m.fn(d) == null ? '' : fmtNum(m.fn(d)!)),
      ];
      out.writeln(row.map(_csv).join(','));
    }
    return out.toString();
  }

  static Future<void> _shareText(String name, String text, String subject) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(text);
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  static Future<void> shareMarkdown() async {
    await store.flush();
    final all = await TrackerDb.loadAll();
    await _shareText('life-tracker-export.md', buildMarkdown(all), 'Life tracker export');
  }

  static Future<void> shareCsv() async {
    await store.flush();
    final all = await TrackerDb.loadAll();
    await _shareText('life-tracker-days.csv', buildCsv(all), 'Life tracker CSV');
  }

  static Future<void> shareBackup() async {
    await store.flush();
    final days = await TrackerDb.loadAll();
    final masterOut = <String, dynamic>{};
    appState.master.forEach((list, items) {
      masterOut[list] = [
        for (final i in items)
          Map<String, dynamic>.from(i)
            ..remove('_id')
            ..remove('_list'),
      ];
    });
    final backup = <String, dynamic>{
      'format': 'zeeshan-life-tracker',
      'version': 2,
      'exported': DateTime.now().toIso8601String(),
      'days': days,
      'master': masterOut,
      'settings': {
        'targets': appState.targets,
        'custom_options': appState.customOptions,
        'hidden_sections': appState.hiddenSections.toList(),
        'modules': appState.modules,
        'theme': appState.themeMode,
      },
    };
    await _shareText('life-tracker-backup.json', jsonEncode(backup), 'Life tracker backup');
  }

  /// Picks a backup file and restores it.
  /// [backupWins] true: backup values replace what is on the phone.
  /// false: only fills gaps, keeping what is already on the phone.
  /// Returns number of days read (0 if nothing picked).
  static Future<int> restoreBackup({required bool backupWins}) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = picked?.files.single.path;
    if (path == null) return 0;
    final raw = jsonDecode(await File(path).readAsString());
    if (raw is! Map) throw const FormatException('This is not a backup file.');

    final Map daysRaw;
    if (raw['format'] == 'zeeshan-life-tracker' && raw['days'] is Map) {
      daysRaw = raw['days'] as Map;
    } else {
      daysRaw = raw; // version 1: plain date -> data map
    }
    await store.flush();
    final out = <String, Map<String, dynamic>>{};
    for (final e in daysRaw.entries) {
      final date = e.key.toString();
      if (e.value is! Map) continue;
      final incoming = Map<String, dynamic>.from(e.value as Map);
      final existing = await TrackerDb.load(date);
      out[date] = _mergeDay(existing, incoming, backupWins);
    }
    await TrackerDb.importDays(out);

    if (raw['master'] is Map) {
      for (final e in (raw['master'] as Map).entries) {
        final list = e.key.toString();
        if (e.value is! List) continue;
        for (final it in e.value as List) {
          if (it is! Map) continue;
          final item = Map<String, dynamic>.from(it);
          final name = appState.itemName(list, item).trim().toLowerCase();
          Map<String, dynamic>? match;
          for (final x in appState.items(list)) {
            if (name.isNotEmpty && appState.itemName(list, x).trim().toLowerCase() == name) {
              match = x;
              break;
            }
          }
          if (match == null) {
            await TrackerDb.masterUpsert(list, item);
          } else if (backupWins) {
            await TrackerDb.masterUpsert(list, {...match, ...item});
          }
        }
      }
    }
    if (raw['settings'] is Map) {
      final s = raw['settings'] as Map;
      for (final key in ['targets', 'custom_options', 'hidden_sections', 'modules', 'theme']) {
        if (!s.containsKey(key)) continue;
        if (backupWins) {
          await TrackerDb.setSetting(key, s[key]);
        } else {
          final cur = await TrackerDb.settingsAll();
          if (cur[key] == null) await TrackerDb.setSetting(key, s[key]);
        }
      }
    }
    await appState.reloadAll();
    await store.refresh();
    return out.length;
  }

  static Map<String, dynamic> _mergeDay(
      Map<String, dynamic> existing, Map<String, dynamic> incoming, bool backupWins) {
    final out = Map<String, dynamic>.from(existing);
    incoming.forEach((k, v) {
      final cur = out[k];
      if (!isFilled(cur)) {
        out[k] = v;
      } else if (backupWins) {
        if (cur is List && v is List) {
          // keep rows that only exist locally
          final ids = {for (final r in v) if (r is Map) r['_id']};
          final merged = <dynamic>[...v];
          for (final r in cur) {
            if (r is Map && !ids.contains(r['_id'])) merged.add(r);
          }
          out[k] = merged;
        } else {
          out[k] = v;
        }
      } else if (cur is List && v is List) {
        final ids = {for (final r in cur) if (r is Map) r['_id']};
        final merged = <dynamic>[...cur];
        for (final r in v) {
          if (r is Map && !ids.contains(r['_id'])) merged.add(r);
        }
        out[k] = merged;
      }
    });
    return out;
  }
}
