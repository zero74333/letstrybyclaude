import 'app_state.dart';
import 'database.dart';
import 'schema/all.dart';

/// Everything the app calculates (fields marked "auto" in the v4 structure).

class Ctx {
  Ctx(this.date, this.data, this.recent);

  final String date;
  final Map<String, dynamic> data;
  final Map<String, Map<String, dynamic>> recent;

  List<String> get recentDatesDesc {
    final l = recent.keys.toList()..sort((a, b) => b.compareTo(a));
    return l;
  }
}

Ctx currentCtx() => Ctx(store.date, store.data, store.recent);

List<Map<String, dynamic>> rowsIn(Map<String, dynamic> d, String key) {
  final v = d[key];
  if (v is! List) return const <Map<String, dynamic>>[];
  return [
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}

int? minsOf(dynamic v) {
  if (v is! String) return null;
  final p = v.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

int spanMins(int start, int end) {
  var d = end - start;
  if (d < 0) d += 1440;
  return d;
}

double _n(dynamic v) => numOf(v)?.toDouble() ?? 0;

double sumRows(Map<String, dynamic> d, String key, String field) {
  var t = 0.0;
  for (final r in rowsIn(d, key)) {
    t += _n(r[field]);
  }
  return t;
}

String hoursText(double h) {
  final total = (h * 60).round();
  return '${total ~/ 60} h ${(total % 60).toString().padLeft(2, '0')} min';
}

// Derived numbers (also used by Insights) ------------------------------------

double? sleepHours(Map<String, dynamic> d) {
  final bed = minsOf(d['sleep.bed']);
  final wake = minsOf(d['sleep.wake']);
  if (bed == null || wake == null) return null;
  var m = spanMins(bed, wake).toDouble();
  m -= _n(d['sleep.fall']);
  m -= sumRows(d, 'sleep.wakeups', 'dur');
  if (m < 0) m = 0;
  return m / 60;
}

bool? sleptOnTarget(Map<String, dynamic> d) {
  final bed = minsOf(d['sleep.bed']);
  final t = minsOf(d['sleep.target_bed'] ?? appState.targets['bedtime']);
  if (bed == null || t == null) return null;
  var diff = bed - t;
  while (diff > 720) {
    diff -= 1440;
  }
  while (diff < -720) {
    diff += 1440;
  }
  return diff <= 0;
}

bool? wokeOnTarget(Map<String, dynamic> d) {
  final w = minsOf(d['sleep.wake']);
  final t = minsOf(d['sleep.target_wake'] ?? appState.targets['wake']);
  if (w == null || t == null) return null;
  var diff = w - t;
  while (diff > 720) {
    diff -= 1440;
  }
  while (diff < -720) {
    diff += 1440;
  }
  return diff <= 15;
}

double totalSpent(Map<String, dynamic> d) => sumRows(d, 'cashflow.expenses', 'amount');
double totalIncome(Map<String, dynamic> d) => sumRows(d, 'cashflow.income', 'amount');

double impulseSpent(Map<String, dynamic> d) {
  var t = 0.0;
  for (final r in rowsIn(d, 'cashflow.expenses')) {
    if (r['planned'] == 'impulse') t += _n(r['amount']);
  }
  return t;
}

int bowelCount(Map<String, dynamic> d) => rowsIn(d, 'gut.bowel').length;

double caffeineCups(Map<String, dynamic> d) {
  var t = 0.0;
  for (final r in rowsIn(d, 'hydration.drinks')) {
    final type = r['type'];
    if (type == 'tea' || type == 'coffee' || type == 'energy drink') {
      t += numOf(r['count'])?.toDouble() ?? 1;
    }
  }
  return t;
}

double exerciseMinutes(Map<String, dynamic> d) => sumRows(d, 'move.sessions', 'dur');

int? _rowMinutes(Map<String, dynamic> r, String startK, String endK, String durK) {
  final dm = numOf(r[durK]);
  if (dm != null) return dm.round();
  final s = minsOf(r[startK]);
  final e = minsOf(r[endK]);
  if (s == null || e == null) return null;
  return spanMins(s, e);
}

double focusHours(Map<String, dynamic> d, {List<String>? types}) {
  var m = 0.0;
  for (final r in rowsIn(d, 'focus.sessions')) {
    if (types != null && !types.contains(r['type'])) continue;
    m += _rowMinutes(r, 'start', 'end', '_none') ?? 0;
  }
  return m / 60;
}

int tasksWithStatus(Map<String, dynamic> d, String status) =>
    rowsIn(d, 'tasks.tasks').where((r) => r['status'] == status).length;

int tasksPlanned(Map<String, dynamic> d) => rowsIn(d, 'tasks.tasks').length;

double? taskRate(Map<String, dynamic> d) {
  final n = tasksPlanned(d);
  if (n == 0) return null;
  return tasksWithStatus(d, 'done') / n * 100;
}

double? moodOf(Map<String, dynamic> d) {
  final m = numOf(d['mind.mood']);
  if (m != null) return m.toDouble();
  final rows = rowsIn(d, 'checkins.checkins');
  final vals = [for (final r in rows) if (numOf(r['mood']) != null) numOf(r['mood'])!.toDouble()];
  if (vals.isEmpty) return null;
  return vals.reduce((a, b) => a + b) / vals.length;
}

double timeWithPeopleHours(Map<String, dynamic> d) =>
    sumRows(d, 'people.interactions', 'dur') / 60;

double gapMinutes(Map<String, dynamic> d) {
  var t = 0.0;
  for (final r in rowsIn(d, 'gaps.items')) {
    t += _rowMinutes(r, 'start', 'end', 'dur') ?? 0;
  }
  return t;
}

// Calculated display text ----------------------------------------------------

String? autoText(String pageId, String key, Ctx c) {
  final d = c.data;
  switch ('$pageId.$key') {
    case 'daily.day':
      return weekdayOf(c.date);
    case 'tomorrow.logcomp':
      var touched = 0;
      for (final p in allPages) {
        if (DayStore.countPage(p, d) > 0) touched++;
      }
      return '$touched of ${allPages.length} pages filled today';
    case 'sleep.on_target':
      final v = sleptOnTarget(d);
      return v == null ? null : (v ? 'Yes' : 'No');
    case 'sleep.total':
      final h = sleepHours(d);
      return h == null ? null : hoursText(h);
    case 'sleep.debt':
      final h = sleepHours(d);
      final t = numOf(appState.targets['sleep_hours']);
      if (h == null || t == null) return null;
      final debt = t.toDouble() - h;
      return debt <= 0 ? 'None (+${hoursText(-debt)} extra)' : hoursText(debt);
    case 'meals.healthy_n':
      final rows = rowsIn(d, 'meals.meals');
      if (rows.isEmpty) return null;
      final n = rows
          .where((r) =>
              r['healthy'] == 'yes' &&
              (r['type'] == 'breakfast' || r['type'] == 'lunch' || r['type'] == 'dinner'))
          .length;
      return '$n of 3';
    case 'meals.gap':
      final times = [
        for (final r in rowsIn(d, 'meals.meals'))
          if (minsOf(r['time']) != null && r['type'] != 'drink only') minsOf(r['time'])!,
      ]..sort();
      if (times.length < 2) return null;
      var best = 0;
      for (var i = 1; i < times.length; i++) {
        if (times[i] - times[i - 1] > best) best = times[i] - times[i - 1];
      }
      return hoursText(best / 60);
    case 'hydration.water_met':
      final w = numOf(d['hydration.water']);
      final t = numOf(appState.targets['water']);
      if (w == null || t == null) return null;
      return w >= t ? 'Yes (${fmtNum(w)} of ${fmtNum(t)} L)' : 'Not yet (${fmtNum(w)} of ${fmtNum(t)} L)';
    case 'hydration.caffeine':
      final cups = caffeineCups(d);
      return cups == 0 ? null : '${fmtNum(cups)} cups';
    case 'gut.count':
      return '${bowelCount(d)}';
    case 'gut.days_since':
      if (bowelCount(d) > 0) return '0 (today)';
      for (final k in c.recentDatesDesc) {
        if (bowelCount(c.recent[k]!) > 0) {
          final diff = parseKey(c.date).difference(parseKey(k)).inDays;
          return '$diff';
        }
      }
      return null;
    case 'move.steps_met':
      final s = numOf(d['move.steps']);
      final t = numOf(appState.targets['steps']);
      if (s == null || t == null) return null;
      return s >= t ? 'Yes' : 'Not yet (${fmtNum(s)} of ${fmtNum(t)})';
    case 'move.active':
      final m = exerciseMinutes(d);
      return m == 0 ? null : '${fmtNum(m)} min';
    case 'verse.today':
      final parts = <String>[];
      void add(String label, String k) {
        final n = rowsIn(d, k).length;
        if (n > 0) parts.add('$n $label');
      }
      add('ideas', 'ideas.ideas');
      add('thoughts', 'thoughts.items');
      add('stuck', 'stuck.items');
      add('learnings', 'learned.items');
      add('questions', 'questions.items');
      add('quotes', 'quotes.items');
      add('dumps', 'dump.items');
      return parts.isEmpty ? 'Nothing yet' : parts.join(', ');
    case 'verse.old':
      final n = oldNewIdeas(c).length;
      return n == 0 ? 'None' : '$n to review';
    case 'verse.stuck':
      final n = activeStuck(c);
      return '$n';
    case 'verse.revisit':
      final l = revisitsDue(c);
      return l.isEmpty ? 'None' : l.join('\n');
    case 'tasks.totals':
      final n = tasksPlanned(d);
      if (n == 0) return null;
      final done = tasksWithStatus(d, 'done');
      return 'Planned $n, done $done, moved ${tasksWithStatus(d, 'moved to later')}, '
          'dropped ${tasksWithStatus(d, 'dropped')}, completion ${fmtNum(done / n * 100)}%';
    case 'focus.totals':
      if (rowsIn(d, 'focus.sessions').isEmpty) return null;
      final best = _bestFocusPart(d);
      return 'Deep ${hoursText(focusHours(d, types: ['deep work']))}, '
          'shallow ${hoursText(focusHours(d, types: ['shallow or admin']))}, '
          'meetings ${hoursText(focusHours(d, types: ['meeting']))}'
          '${best == null ? '' : '\nMost productive: $best'}';
    case 'cashflow.income':
      return fmtNum(totalIncome(d));
    case 'cashflow.spent':
      return fmtNum(totalSpent(d));
    case 'cashflow.net':
      return fmtNum(totalIncome(d) - totalSpent(d));
    case 'cashflow.budget':
      final b = numOf(appState.targets['budget']);
      return b == null ? 'Not set (Master data > Targets)' : fmtNum(b);
    case 'cashflow.remaining':
      final b = numOf(appState.targets['budget']);
      return b == null ? null : fmtNum(b - totalSpent(d));
    case 'cashflow.impulse':
      return fmtNum(impulseSpent(d));
    case 'cashflow.bycat':
      final m = <String, double>{};
      for (final r in rowsIn(d, 'cashflow.expenses')) {
        final cat = asStr(r['cat']) ?? 'uncategorised';
        m[cat] = (m[cat] ?? 0) + _n(r['amount']);
      }
      if (m.isEmpty) return null;
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return e.map((x) => '${x.key}: ${fmtNum(x.value)}').join('\n');
    case 'cashflow.nospend':
      if (d['cashflow.nospend_override'] is bool) {
        return (d['cashflow.nospend_override'] as bool) ? 'Yes (set by you)' : 'No (set by you)';
      }
      return rowsIn(d, 'cashflow.expenses').isEmpty ? 'Yes (nothing logged)' : 'No';
    case 'daysocial.with_people':
      final h = timeWithPeopleHours(d);
      return h == 0 ? null : hoursText(h);
    case 'upkeep.birthdays':
      final l = upcomingBirthdays(c.date);
      return l.isEmpty ? 'None in the next 14 days' : l.join('\n');
    case 'hab_daily.walk':
      final m = exerciseMinutes(d);
      return m == 0 ? null : '${fmtNum(m)} min';
    case 'hab_daily.water':
      return autoText('hydration', 'water_met', c);
    case 'hab_daily.screen':
      return autoText('screen', 'under', c);
    case 'hab_daily.skill':
      final m = sumRows(d, 'study.items', 'time') + sumRows(d, 'training.items', 'time');
      return m == 0 ? null : '${fmtNum(m)} min';
    case 'hab_daily.slept':
      return autoText('sleep', 'on_target', c);
    case 'hab_daily.woke':
      final v = wokeOnTarget(d);
      return v == null ? null : (v ? 'Yes' : 'No');
    case 'screen.limit':
      final l = numOf(appState.targets['screen']);
      return l == null ? 'Not set' : '${fmtNum(l)} h';
    case 'screen.under':
      final t = numOf(d['screen.total']);
      final l = numOf(appState.targets['screen']);
      if (t == null || l == null) return null;
      return t <= l ? 'Yes' : 'No (${fmtNum(t - l)} h over)';
    case 'gaps.common':
      final m = <String, int>{};
      for (final r in rowsIn(d, 'gaps.items')) {
        final w = asStr(r['what']) ?? asStr(r['cat']);
        if (w != null) m[w.toLowerCase()] = (m[w.toLowerCase()] ?? 0) + 1;
      }
      if (m.isEmpty) return null;
      final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return e.first.key;
    case 'gaps.total':
      final g = gapMinutes(d);
      return g == 0 ? null : '${fmtNum(g)} min';
    case 'timealloc.sleep':
      final h = sleepHours(d);
      return h == null ? null : fmtNum(h);
    case 'timealloc.work':
      final h = focusHours(d, types: ['deep work', 'shallow or admin', 'meeting', 'creative']);
      return h == 0 ? null : fmtNum(h);
    case 'timealloc.study':
      final h = (sumRows(d, 'study.items', 'time') / 60) +
          focusHours(d, types: ['study', 'learning']);
      return h == 0 ? null : fmtNum(h);
    case 'timealloc.exercise':
      final h = exerciseMinutes(d) / 60;
      return h == 0 ? null : fmtNum(h);
    case 'timealloc.family':
      final h = timeWithPeopleHours(d);
      return h == 0 ? null : fmtNum(h);
    case 'timealloc.screen':
      final h = numOf(d['screen.total']);
      return h == null ? null : fmtNum(h);
    case 'timealloc.total':
      final t = timeAllocTotal(d);
      if (t == 0) return null;
      final warn = (t < 20 || t > 28) ? '  (far from 24, check entries)' : '';
      return '${fmtNum(t)} h$warn';
  }
  return null;
}

double timeAllocTotal(Map<String, dynamic> d) {
  var t = 0.0;
  t += sleepHours(d) ?? 0;
  t += focusHours(d, types: ['deep work', 'shallow or admin', 'meeting', 'creative']);
  t += (sumRows(d, 'study.items', 'time') / 60) + focusHours(d, types: ['study', 'learning']);
  t += exerciseMinutes(d) / 60;
  t += timeWithPeopleHours(d);
  t += _n(d['screen.total']);
  for (final k in ['meals', 'rest', 'chores', 'travel', 'prayer', 'other']) {
    t += _n(d['timealloc.$k']);
  }
  return t;
}

String? _bestFocusPart(Map<String, dynamic> d) {
  final sums = <String, List<double>>{};
  for (final r in rowsIn(d, 'focus.sessions')) {
    final s = minsOf(r['start']);
    final q = numOf(r['quality']);
    if (s == null || q == null) continue;
    final h = s ~/ 60;
    final part = h < 12 ? 'morning' : h < 17 ? 'afternoon' : h < 21 ? 'evening' : 'night';
    sums.putIfAbsent(part, () => <double>[]).add(q.toDouble());
  }
  if (sums.isEmpty) return null;
  String? best;
  var bestAvg = -1.0;
  sums.forEach((k, v) {
    final avg = v.reduce((a, b) => a + b) / v.length;
    if (avg > bestAvg) {
      bestAvg = avg;
      best = k;
    }
  });
  return best;
}

// Cross-day helpers ----------------------------------------------------------

class IdeaRef {
  IdeaRef(this.date, this.id, this.title, this.status);
  final String date;
  final String id;
  final String title;
  final String status;
}

/// Ideas still "new" 7+ days after capture (from the recent window).
List<IdeaRef> oldNewIdeas(Ctx c) {
  final out = <IdeaRef>[];
  final today = parseKey(c.date);
  c.recent.forEach((date, data) {
    if (today.difference(parseKey(date)).inDays < 7) return;
    for (final r in rowsIn(data, 'ideas.ideas')) {
      if ((r['status'] ?? 'new') == 'new' && asStr(r['title']) != null) {
        out.add(IdeaRef(date, r['_id'].toString(), r['title'].toString(), 'new'));
      }
    }
  });
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

int activeStuck(Ctx c) {
  final seen = <String>{};
  void scan(Map<String, dynamic> d) {
    for (final r in rowsIn(d, 'stuck.items')) {
      final st = r['status'];
      final t = asStr(r['thought']);
      if (t != null && (st == null || st == 'active')) seen.add(t.trim().toLowerCase());
    }
  }

  scan(c.data);
  for (final k in c.recentDatesDesc.take(30)) {
    scan(c.recent[k]!);
  }
  return seen.length;
}

List<String> revisitsDue(Ctx c) {
  const offsets = {'tomorrow': 1, 'in 3 days': 3, 'in a week': 7, 'in a month': 30};
  final today = parseKey(c.date);
  final out = <String>[];
  c.recent.forEach((date, data) {
    final age = today.difference(parseKey(date)).inDays;
    for (final r in rowsIn(data, 'learned.items')) {
      final off = offsets[r['revisit']];
      if (off != null && off == age) {
        out.add(asStr(r['line']) ?? asStr(r['what']) ?? 'Learning from ${fmtShort(date)}');
      }
    }
  });
  return out;
}

List<String> upcomingBirthdays(String dateStr, {int days = 14}) {
  final today = parseKey(dateStr);
  final out = <String>[];
  for (final p in appState.items('people')) {
    final b = asStr(p['birthday']);
    if (b == null) continue;
    DateTime? bd;
    try {
      bd = parseKey(b);
    } catch (_) {
      bd = null;
    }
    if (bd == null) continue;
    var next = DateTime(today.year, bd.month, bd.day);
    if (next.isBefore(today)) next = DateTime(today.year + 1, bd.month, bd.day);
    final diff = next.difference(today).inDays;
    if (diff <= days) {
      out.add('${p['name']}: ${diff == 0 ? 'today' : 'in $diff days'} (${fmtShort(dateKey(next))})');
    }
  }
  return out;
}

/// Current and best streak for a boolean test over days (today first, then recent).
({int current, int best}) streakOf(Ctx c, bool Function(Map<String, dynamic>) test) {
  final days = <Map<String, dynamic>>[
    c.data,
    for (final k in c.recentDatesDesc) c.recent[k]!,
  ];
  var current = 0;
  var counting = true;
  var best = 0;
  var run = 0;
  for (var i = 0; i < days.length; i++) {
    final ok = test(days[i]);
    if (ok) {
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
    if (counting) {
      if (ok) {
        current++;
      } else if (i > 0) {
        counting = false;
      }
      // Today not logged yet: do not break the streak.
    }
  }
  return (current: current, best: best);
}

/// Days since a slip for a "breaking" habit.
int? daysClean(Ctx c, String habit) {
  final h = habit.trim().toLowerCase();
  bool slipped(Map<String, dynamic> d) {
    for (final r in rowsIn(d, 'breaking.items')) {
      if ((asStr(r['habit']) ?? '').trim().toLowerCase() == h && (numOf(r['slips']) ?? 0) > 0) {
        return true;
      }
    }
    return false;
  }

  if (slipped(c.data)) return 0;
  var count = 0;
  final today = parseKey(c.date);
  for (final k in c.recentDatesDesc) {
    if (slipped(c.recent[k]!)) return today.difference(parseKey(k)).inDays;
    count = today.difference(parseKey(k)).inDays;
  }
  return c.recent.isEmpty ? null : count;
}

// Bills ---------------------------------------------------------------------

class BillDue {
  BillDue(this.item, this.due, this.key);
  final Map<String, dynamic> item;
  final DateTime due;
  final String key;
}

List<BillDue> billsDue(String dateStr) {
  final today = parseKey(dateStr);
  final out = <BillDue>[];
  for (final b in appState.items('bills')) {
    final day = numOf(b['day'])?.toInt();
    if (day == null) continue;
    final yearly = b['freq'] == 'yearly';
    final month = numOf(b['month'])?.toInt();
    for (var off = -7; off <= 6; off++) {
      final d = today.add(Duration(days: off));
      final lastDay = DateTime(d.year, d.month + 1, 0).day;
      final target = day > lastDay ? lastDay : day;
      if (d.day != target) continue;
      if (yearly && month != d.month) continue;
      out.add(BillDue(b, d, '${b['_id']}|${dateKey(d)}'));
    }
  }
  out.sort((a, b) => a.due.compareTo(b.due));
  return out;
}

bool billPaid(Ctx c, String key) {
  bool has(Map<String, dynamic> d) {
    final v = d['bills.paid'];
    return v is Map && v.containsKey(key);
  }

  if (has(c.data)) return true;
  for (final d in c.recent.values) {
    if (has(d)) return true;
  }
  return false;
}

// Advisories ------------------------------------------------------------------

/// Gentle prompts from the app notes in v4.
List<String> advisories(String pageId, Map<String, dynamic> d) {
  final out = <String>[];
  if (pageId == 'gut') {
    var flag = false;
    for (final r in rowsIn(d, 'gut.bowel')) {
      final blood = r['blood'];
      if (blood == 'blood' || blood == 'both' || r['colour'] == 'black') flag = true;
    }
    var vomiting = 0;
    for (final r in rowsIn(d, 'gut.symptoms')) {
      if (r['symptom'] == 'vomiting') vomiting++;
      if (r['sev'] == 'strong' && r['symptom'] == 'stomach pain or cramps') flag = true;
    }
    if (vomiting >= 2) flag = true;
    if (flag) {
      out.add('Blood or black stool, severe pain or repeated vomiting is worth '
          'mentioning to a doctor. Consider getting medical advice soon.');
    }
  }
  if (pageId == 'body') {
    for (final r in rowsIn(d, 'body.symptoms')) {
      final s = r['symptom'];
      final sev = numOf(r['sev']) ?? 0;
      if (s == 'chest discomfort' || s == 'shortness of breath' || s == 'fainting' ||
          (s == 'headache' && sev >= 9)) {
        out.add('Chest discomfort, shortness of breath, fainting or a severe sudden '
            'headache can be serious. Please seek urgent medical care.');
        break;
      }
    }
  }
  return out;
}

/// True when mood <= 3 or anxiety >= 8 for 3 days in a row (today + 2 before).
bool mindStreakFlag(Ctx c) {
  bool low(Map<String, dynamic> d) {
    final mood = moodOf(d);
    final anx = numOf(d['anxiety.level']);
    return (mood != null && mood <= 3) || (anx != null && anx >= 8);
  }

  final today = parseKey(c.date);
  if (!low(c.data)) return false;
  for (var i = 1; i <= 2; i++) {
    final k = dateKey(today.subtract(Duration(days: i)));
    final d = c.recent[k];
    if (d == null || !low(d)) return false;
  }
  return true;
}
