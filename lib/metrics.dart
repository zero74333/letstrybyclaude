import 'app_state.dart';
import 'auto.dart';
import 'schema/all.dart';

/// A number per day, used by Trends and Compare.
class Metric {
  Metric(this.id, this.label, this.fn);

  final String id;
  final String label;
  final double? Function(Map<String, dynamic>) fn;
}

List<Metric> buildMetrics() {
  final out = <Metric>[
    Metric('d.sleep_hours', 'Sleep: total hours', sleepHours),
    Metric('d.mood', 'Mood (overall or average of check-ins)', moodOf),
    Metric('d.spent', 'Money: total spent', (d) => rowsIn(d, 'cashflow.expenses').isEmpty ? null : totalSpent(d)),
    Metric('d.income', 'Money: total income', (d) => rowsIn(d, 'cashflow.income').isEmpty ? null : totalIncome(d)),
    Metric('d.tasks_done', 'Work: tasks done', (d) => tasksPlanned(d) == 0 ? null : tasksWithStatus(d, 'done').toDouble()),
    Metric('d.task_rate', 'Work: task completion %', taskRate),
    Metric('d.deep', 'Work: deep work hours', (d) => rowsIn(d, 'focus.sessions').isEmpty ? null : focusHours(d, types: ['deep work'])),
    Metric('d.bowel', 'Gut: bowel movements', (d) => d.keys.any((k) => k.startsWith('gut.')) ? bowelCount(d).toDouble() : null),
    Metric('d.caffeine', 'Drinks: caffeine cups', (d) => rowsIn(d, 'hydration.drinks').isEmpty ? null : caffeineCups(d)),
    Metric('d.exercise', 'Movement: exercise minutes', (d) => rowsIn(d, 'move.sessions').isEmpty ? null : exerciseMinutes(d)),
    Metric('d.people_h', 'Social: hours with people', (d) => rowsIn(d, 'people.interactions').isEmpty ? null : timeWithPeopleHours(d)),
    Metric('d.checkins', 'Mind: check-ins logged', (d) => rowsIn(d, 'checkins.checkins').isEmpty ? null : rowsIn(d, 'checkins.checkins').length.toDouble()),
  ];
  // Every numeric / scale / duration field in the schema.
  for (final p in allPages) {
    for (final g in p.groups) {
      if (g.repeat) continue;
      for (final f in g.fields) {
        if (f.type == T.number || f.type == T.scale || f.type == T.duration) {
          final key = flatKey(p.id, f.k);
          out.add(Metric('f.$key', '${p.title}: ${f.label}', (d) => numOf(d[key])?.toDouble()));
        }
      }
    }
  }
  return out;
}

Metric? metricById(List<Metric> all, String id) {
  for (final m in all) {
    if (m.id == id) return m;
  }
  return null;
}

class Pearson {
  Pearson(this.r, this.n);
  final double r;
  final int n;
}

Pearson? pearson(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 5) return null;
  final mx = xs.reduce((a, b) => a + b) / n;
  final my = ys.reduce((a, b) => a + b) / n;
  var sxy = 0.0, sxx = 0.0, syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - mx;
    final dy = ys[i] - my;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }
  if (sxx == 0 || syy == 0) return null;
  var r = sxy / _sqrt(sxx * syy);
  if (r > 1) r = 1;
  if (r < -1) r = -1;
  return Pearson(r, n);
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  var g = x / 2;
  for (var i = 0; i < 30; i++) {
    g = (g + x / g) / 2;
  }
  return g;
}

String describeR(double r) {
  final a = r.abs();
  final dir = r >= 0 ? 'rise together' : 'move in opposite directions';
  if (a < 0.2) return 'No clear link in these days.';
  final strength = a < 0.4 ? 'A weak' : a < 0.6 ? 'A moderate' : 'A strong';
  return '$strength link: the two tend to $dir. This shows a pattern, not a cause.';
}
