import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Date key used for storage, for example "2026-10-31".
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseKey(String k) {
  final p = k.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Local SQLite storage.
///  days     one row per day, values as JSON (keys "page.field" / "page.group")
///  master   master-data items (goals, people, bills...)
///  settings key/value JSON (targets, custom options, PIN hash, ...)
class TrackerDb {
  static Database? _db;

  static Future<Database> get _database async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'tracker.db'),
      version: 2,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE days(date TEXT PRIMARY KEY, data TEXT NOT NULL)');
        await _createV2(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) await _createV2(db);
      },
    );
    return _db!;
  }

  static Future<void> _createV2(Database db) async {
    await db.execute(
        'CREATE TABLE IF NOT EXISTS master(id INTEGER PRIMARY KEY AUTOINCREMENT, list TEXT NOT NULL, data TEXT NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS settings(k TEXT PRIMARY KEY, v TEXT NOT NULL)');
  }

  // Days ---------------------------------------------------------------------

  static Future<Map<String, dynamic>> load(String date) async {
    final db = await _database;
    final rows = await db.query('days', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(rows.first['data'] as String) as Map);
  }

  static Future<void> save(String date, Map<String, dynamic> data) async {
    final db = await _database;
    if (data.isEmpty) {
      await db.delete('days', where: 'date = ?', whereArgs: [date]);
      return;
    }
    await db.insert(
      'days',
      {'date': date, 'data': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteDay(String date) async {
    final db = await _database;
    await db.delete('days', where: 'date = ?', whereArgs: [date]);
  }

  static Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final db = await _database;
    final rows = await db.query('days', orderBy: 'date ASC');
    return {
      for (final r in rows)
        r['date'] as String:
            Map<String, dynamic>.from(jsonDecode(r['data'] as String) as Map),
    };
  }

  /// Days with from <= date < toExclusive (string compare works for yyyy-MM-dd).
  static Future<Map<String, Map<String, dynamic>>> range(String from, String toExclusive) async {
    final db = await _database;
    final rows = await db.query(
      'days',
      where: 'date >= ? AND date < ?',
      whereArgs: [from, toExclusive],
      orderBy: 'date ASC',
    );
    return {
      for (final r in rows)
        r['date'] as String:
            Map<String, dynamic>.from(jsonDecode(r['data'] as String) as Map),
    };
  }

  static Future<void> importDays(Map<String, Map<String, dynamic>> all) async {
    final db = await _database;
    final batch = db.batch();
    all.forEach((date, data) {
      batch.insert(
        'days',
        {'date': date, 'data': jsonEncode(data)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  // Master data --------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> masterAll() async {
    final db = await _database;
    final rows = await db.query('master', orderBy: 'id ASC');
    return [
      for (final r in rows)
        {
          ...Map<String, dynamic>.from(jsonDecode(r['data'] as String) as Map),
          '_id': r['id'],
          '_list': r['list'],
        },
    ];
  }

  /// Inserts or updates one item. Returns its id.
  static Future<int> masterUpsert(String list, Map<String, dynamic> item) async {
    final db = await _database;
    final clean = Map<String, dynamic>.from(item)
      ..remove('_id')
      ..remove('_list');
    final id = item['_id'];
    if (id is int) {
      await db.update('master', {'list': list, 'data': jsonEncode(clean)},
          where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert('master', {'list': list, 'data': jsonEncode(clean)});
  }

  static Future<void> masterDelete(int id) async {
    final db = await _database;
    await db.delete('master', where: 'id = ?', whereArgs: [id]);
  }

  // Settings -----------------------------------------------------------------

  static Future<Map<String, dynamic>> settingsAll() async {
    final db = await _database;
    final rows = await db.query('settings');
    return {for (final r in rows) r['k'] as String: jsonDecode(r['v'] as String)};
  }

  static Future<void> setSetting(String k, dynamic v) async {
    final db = await _database;
    if (v == null) {
      await db.delete('settings', where: 'k = ?', whereArgs: [k]);
      return;
    }
    await db.insert('settings', {'k': k, 'v': jsonEncode(v)},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
