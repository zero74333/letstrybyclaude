import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'schema/all.dart';

// ---------------------------------------------------------------------------
// Small helpers shared across the app.
// ---------------------------------------------------------------------------

bool isFilled(dynamic v) {
  if (v == null) return false;
  if (v is String) return v.trim().isNotEmpty;
  if (v is List) return v.isNotEmpty;
  if (v is Map) return v.isNotEmpty;
  return true;
}

num? numOf(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

String fmtNum(num n) {
  final d = n.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toStringAsFixed(1);
}

List<String> asList(dynamic v) {
  if (v is List) return [for (final e in v) e.toString()];
  if (v is String && v.isNotEmpty) return [v];
  return <String>[];
}

String? asStr(dynamic v) {
  if (v == null) return null;
  if (v is List) return v.isEmpty ? null : v.first.toString();
  final s = v.toString();
  return s.isEmpty ? null : s;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];
const weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];

String fmtShort(String key) {
  final d = parseKey(key);
  return '${d.day} ${_months[d.month - 1]}';
}

String fmtLong(String key) {
  final d = parseKey(key);
  return '${d.day} ${_monthsLong[d.month - 1]} ${d.year}';
}

String weekdayOf(String key) => weekdaysLong[parseKey(key).weekday - 1];

int _seq = 0;
String newRowId() => '${DateTime.now().microsecondsSinceEpoch}${_seq++}';

String hashPin(String pin) => sha256.convert(utf8.encode('zdls-v1:$pin')).toString();

// ---------------------------------------------------------------------------
// AppState: master data, targets and settings.
// ---------------------------------------------------------------------------

class AppState extends ChangeNotifier {
  bool ready = false;
  Map<String, dynamic> targets = {};
  Map<String, List<String>> customOptions = {};
  List<String> tags = [];
  Set<String> hiddenSections = {};
  Map<String, bool> modules = {'cycle': false, 'intake': false};
  String themeMode = 'system';
  String? pinHash;
  bool locked = false;

  /// listId -> items. Each item has '_id' (int).
  Map<String, List<Map<String, dynamic>>> master = {};

  ThemeMode get theme {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> init() async {
    final s = await TrackerDb.settingsAll();
    targets = s['targets'] is Map
        ? Map<String, dynamic>.from(s['targets'] as Map)
        : Map<String, dynamic>.from(defaultTargets);
    if (s['targets'] == null) await TrackerDb.setSetting('targets', targets);
    if (s['custom_options'] is Map) {
      customOptions = {
        for (final e in (s['custom_options'] as Map).entries)
          e.key.toString(): asList(e.value),
      };
    }
    tags = asList(s['tags']);
    hiddenSections = asList(s['hidden_sections']).toSet();
    if (s['modules'] is Map) {
      for (final e in (s['modules'] as Map).entries) {
        modules[e.key.toString()] = e.value == true;
      }
    }
    themeMode = asStr(s['theme']) ?? 'system';
    pinHash = asStr(s['pin']);
    locked = pinHash != null;
    await _loadMaster();
    ready = true;
    notifyListeners();
  }

  Future<void> _loadMaster() async {
    final all = await TrackerDb.masterAll();
    final m = <String, List<Map<String, dynamic>>>{};
    for (final item in all) {
      final list = item['_list'].toString();
      m.putIfAbsent(list, () => <Map<String, dynamic>>[]).add(item);
    }
    master = m;
  }

  // Master data -------------------------------------------------------------

  List<Map<String, dynamic>> items(String list) => master[list] ?? const <Map<String, dynamic>>[];

  String itemName(String list, Map<String, dynamic> item) {
    final def = masterById(list);
    final v = item[def?.primary ?? 'name'];
    return v?.toString() ?? '';
  }

  List<String> names(String list) => [
        for (final i in items(list))
          if (itemName(list, i).trim().isNotEmpty) itemName(list, i),
      ];

  Future<void> upsertMaster(String list, Map<String, dynamic> item) async {
    final id = await TrackerDb.masterUpsert(list, item);
    item['_id'] = id;
    item['_list'] = list;
    final l = master.putIfAbsent(list, () => <Map<String, dynamic>>[]);
    final idx = l.indexWhere((e) => e['_id'] == id);
    if (idx >= 0) {
      l[idx] = item;
    } else {
      l.add(item);
    }
    notifyListeners();
  }

  Future<void> deleteMaster(String list, Map<String, dynamic> item) async {
    final id = item['_id'];
    if (id is int) await TrackerDb.masterDelete(id);
    master[list]?.removeWhere((e) => e['_id'] == id);
    notifyListeners();
  }

  Future<void> addPrinciple(String text, String date) async {
    await upsertMaster('principles', {'text': text, 'added': date});
  }

  // Targets -----------------------------------------------------------------

  Future<void> setTarget(String key, dynamic v) async {
    if (v == null || v == '') {
      targets.remove(key);
    } else {
      targets[key] = v;
    }
    await TrackerDb.setSetting('targets', targets);
    notifyListeners();
  }

  // Custom options / tags ---------------------------------------------------

  Future<void> addCustomOption(String path, String value) async {
    final v = value.trim();
    if (v.isEmpty) return;
    final l = customOptions.putIfAbsent(path, () => <String>[]);
    if (!l.contains(v)) l.add(v);
    await TrackerDb.setSetting('custom_options', customOptions);
    notifyListeners();
  }

  Future<void> removeCustomOption(String path, String value) async {
    customOptions[path]?.remove(value);
    if (customOptions[path]?.isEmpty ?? false) customOptions.remove(path);
    await TrackerDb.setSetting('custom_options', customOptions);
    notifyListeners();
  }

  Future<void> addTag(String value) async {
    final v = value.trim();
    if (v.isEmpty || tags.contains(v)) return;
    tags.add(v);
    await TrackerDb.setSetting('tags', tags);
    notifyListeners();
  }

  Future<void> removeTag(String value) async {
    tags.remove(value);
    await TrackerDb.setSetting('tags', tags);
    notifyListeners();
  }

  // Settings ----------------------------------------------------------------

  Future<void> setHidden(String sectionId, bool hidden) async {
    if (hidden) {
      hiddenSections.add(sectionId);
    } else {
      hiddenSections.remove(sectionId);
    }
    await TrackerDb.setSetting('hidden_sections', hiddenSections.toList());
    notifyListeners();
  }

  Future<void> setModule(String key, bool on) async {
    modules[key] = on;
    await TrackerDb.setSetting('modules', modules);
    notifyListeners();
  }

  Future<void> setTheme(String mode) async {
    themeMode = mode;
    await TrackerDb.setSetting('theme', mode);
    notifyListeners();
  }

  Future<void> setPin(String? pin) async {
    pinHash = pin == null ? null : hashPin(pin);
    await TrackerDb.setSetting('pin', pinHash);
    locked = false;
    notifyListeners();
  }

  bool checkPin(String pin) => pinHash == hashPin(pin);

  void lock() {
    if (pinHash != null && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    locked = false;
    notifyListeners();
  }

  /// Used after a restore.
  Future<void> reloadAll() async {
    ready = false;
    await init();
  }

  /// Link-field options for a list spec such as "goals+projects" or "@meals".
  List<String> linkOptions(String spec, Map<String, dynamic> dayData) {
    final out = <String>[];
    for (final part in spec.split('+')) {
      if (part.startsWith('@')) {
        out.addAll(_special(part, dayData));
      } else {
        out.addAll(names(part));
      }
    }
    return out.toSet().toList();
  }

  List<String> _special(String part, Map<String, dynamic> d) {
    String keyOf(String pg, String grp) => groupKey(pg, grp);
    List<dynamic> rows(String k) => d[k] is List ? d[k] as List<dynamic> : const <dynamic>[];
    final out = <String>[];
    if (part == '@meals') {
      for (final r in rows(keyOf('meals', 'meals'))) {
        if (r is! Map) continue;
        final what = asStr(r['what']) ?? asStr(r['type']);
        if (what == null) continue;
        final t = asStr(r['time']);
        out.add(t == null ? what : '$what ($t)');
      }
    } else if (part == '@tasks') {
      for (final r in rows(keyOf('tasks', 'tasks'))) {
        if (r is Map && asStr(r['task']) != null) out.add(asStr(r['task'])!);
      }
    } else if (part == '@ideas') {
      for (final r in rows(keyOf('ideas', 'ideas'))) {
        if (r is Map && asStr(r['title']) != null) out.add(asStr(r['title'])!);
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// DayStore: the day currently being viewed/edited. Auto-saves.
// ---------------------------------------------------------------------------

class DayStore extends ChangeNotifier {
  String date = dateKey(DateTime.now());
  Map<String, dynamic> data = <String, dynamic>{};

  /// Previous days (up to 90 before [date]) for streaks, reviews, advisories.
  Map<String, Map<String, dynamic>> recent = {};
  bool loading = true;
  bool saving = false;
  Timer? _timer;
  bool _dirty = false;

  bool get isToday => date == dateKey(DateTime.now());

  Future<void> open(String d) async {
    await flush();
    date = d;
    loading = true;
    notifyListeners();
    data = await TrackerDb.load(d);
    await _loadRecent();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() => open(date);

  /// Lets widgets ask listeners to rebuild after changing [recent] directly.
  void bump() => notifyListeners();

  Future<void> _loadRecent() async {
    final day = parseKey(date);
    final from = dateKey(day.subtract(const Duration(days: 90)));
    recent = await TrackerDb.range(from, date);
  }

  /// Moves to another day by [delta] days.
  Future<void> shift(int delta) =>
      open(dateKey(parseKey(date).add(Duration(days: delta))));

  dynamic get(String key) => data[key];

  List<dynamic> rows(String key) =>
      data[key] is List ? data[key] as List<dynamic> : const <dynamic>[];

  void set(String key, dynamic v, {bool quiet = false}) {
    if (!isFilled(v) && v is! bool && v is! num) {
      data.remove(key);
    } else {
      data[key] = v;
    }
    _touch(quiet);
  }

  Map<String, dynamic> addRow(String key, [Map<String, dynamic>? init]) {
    final list = data[key] is List ? data[key] as List<dynamic> : <dynamic>[];
    final row = <String, dynamic>{'_id': newRowId(), ...?init};
    list.add(row);
    data[key] = list;
    _touch(false);
    return row;
  }

  void removeRow(String key, String id) {
    final list = data[key];
    if (list is! List) return;
    list.removeWhere((r) => r is Map && r['_id'] == id);
    if (list.isEmpty) data.remove(key);
    _touch(false);
  }

  void setRow(String key, String id, String field, dynamic v, {bool quiet = false}) {
    final list = data[key];
    if (list is! List) return;
    for (final r in list) {
      if (r is Map && r['_id'] == id) {
        if (!isFilled(v) && v is! bool && v is! num) {
          r.remove(field);
        } else {
          r[field] = v;
        }
        break;
      }
    }
    _touch(quiet);
  }

  void _touch(bool quiet) {
    _dirty = true;
    saving = true;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      flush();
    });
    if (!quiet) notifyListeners();
  }

  Future<void> flush() async {
    _timer?.cancel();
    if (!_dirty) return;
    _dirty = false;
    final d = date;
    final th = data[groupKey('thoughts', 'items')];
    if (th is List) {
      for (final r in th) {
        if (r is Map && r['principle'] == true && r['_pr'] != true && isFilled(r['thought'])) {
          await appState.addPrinciple(r['thought'].toString(), d);
          r['_pr'] = true;
        }
      }
    }
    await TrackerDb.save(d, data);
    saving = false;
    notifyListeners();
  }

  // Counting ---------------------------------------------------------------

  /// Number of filled answers on a page (rows count one each).
  int pageCount(PageDef p) => countPage(p, data);

  int sectionCount(Sect s) => s.pages.fold<int>(0, (a, p) => a + pageCount(p));

  static int countPage(PageDef p, Map<String, dynamic> d) {
    var n = 0;
    for (final g in p.groups) {
      if (g.block != null) continue;
      if (g.repeat) {
        final v = d[groupKey(p.id, g.id)];
        if (v is List) n += v.length;
      } else {
        for (final f in g.fields) {
          if (f.type == T.calc) continue;
          if (isFilled(d[flatKey(p.id, f.k)])) n++;
        }
      }
    }
    if (isFilled(d['${p.id}._notes'])) n++;
    return n;
  }
}

final AppState appState = AppState();
final DayStore store = DayStore();

/// Which tab of the shell is open (0 Today, 1 History, 2 Insights).
final ValueNotifier<int> shellTab = ValueNotifier<int>(0);
