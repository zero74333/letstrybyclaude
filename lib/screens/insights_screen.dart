import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart';
import '../database.dart';
import '../metrics.dart';

/// Trends for any numeric field, a week-at-a-glance card, and correlations.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final List<Metric> _metrics = buildMetrics();
  Map<String, Map<String, dynamic>> _data = {};
  bool _loading = true;
  int _range = 30;
  String _trendId = 'd.sleep_hours';
  String _xId = 'd.sleep_hours';
  String _yId = 'd.mood';

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
    if (shellTab.value == 2) _load();
  }

  Future<void> _load() async {
    await store.flush();
    final end = DateTime.now().add(const Duration(days: 1));
    final start = end.subtract(const Duration(days: 200));
    final d = await TrackerDb.range(dateKey(start), dateKey(end));
    if (!mounted) return;
    setState(() {
      _data = d;
      _loading = false;
    });
  }

  List<String> _lastDays(int n) {
    final today = DateTime.now();
    return [
      for (var i = n - 1; i >= 0; i--) dateKey(today.subtract(Duration(days: i))),
    ];
  }

  List<double?> _series(Metric m, List<String> days) => [
        for (final k in days) _data[k] == null ? null : m.fn(_data[k]!),
      ];

  Future<void> _pick(String current, void Function(String) set) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _MetricPicker(metrics: _metrics),
    );
    if (id != null) setState(() => set(id));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final trend = metricById(_metrics, _trendId) ?? _metrics.first;
    final days = _lastDays(_range);
    final series = _series(trend, days);
    final vals = [for (final v in series) if (v != null) v];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _weekCard(context),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trend', style: tt.titleMedium),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.show_chart),
                          label: Text(trend.label, overflow: TextOverflow.ellipsis),
                          onPressed: () => _pick(_trendId, (v) => _trendId = v),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final r in [7, 30, 90])
                              ChoiceChip(
                                label: Text('$r days'),
                                selected: _range == r,
                                onSelected: (_) => setState(() => _range = r),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (vals.length < 2)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Not enough data yet. Log this at least twice in the last $_range days.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        else ...[
                          SizedBox(
                            height: 180,
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: LinePainter(series, cs.primary, cs.outlineVariant, cs.onSurfaceVariant),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(fmtShort(days.first), style: tt.labelSmall),
                              Text(fmtShort(days.last), style: tt.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Average ${fmtNum(vals.reduce((a, b) => a + b) / vals.length)}'
                            '   Low ${fmtNum(vals.reduce((a, b) => a < b ? a : b))}'
                            '   High ${fmtNum(vals.reduce((a, b) => a > b ? a : b))}'
                            '   (${vals.length} days)',
                            style: tt.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _compareCard(context),
              ],
            ),
    );
  }

  Widget _weekCard(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final thisWeek = _lastDays(7);
    final prev = _lastDays(14).take(7).toList();

    double? agg(String id, List<String> days, bool sum) {
      final m = metricById(_metrics, id);
      if (m == null) return null;
      final v = [for (final x in _series(m, days)) if (x != null) x];
      if (v.isEmpty) return null;
      final t = v.reduce((a, b) => a + b);
      return sum ? t : t / v.length;
    }

    Widget row(String label, String id, {bool sum = false, String unit = ''}) {
      final a = agg(id, thisWeek, sum);
      final b = agg(id, prev, sum);
      String arrow = '';
      if (a != null && b != null && a != b) arrow = a > b ? '  ▲' : '  ▼';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(a == null ? '-' : '${fmtNum(a)}$unit$arrow',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 days', style: tt.titleMedium),
            Text('Arrows compare with the 7 days before.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            row('Sleep (avg)', 'd.sleep_hours', unit: ' h'),
            row('Mood (avg)', 'd.mood'),
            row('Day rating (avg)', 'f.daily.rating'),
            row('Water (avg)', 'f.hydration.water', unit: ' L'),
            row('Spent (total)', 'd.spent', sum: true),
            row('Tasks done (total)', 'd.tasks_done', sum: true),
            row('Deep work (total)', 'd.deep', sum: true, unit: ' h'),
            row('Exercise (total)', 'd.exercise', sum: true, unit: ' min'),
          ],
        ),
      ),
    );
  }

  Widget _compareCard(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mx = metricById(_metrics, _xId) ?? _metrics.first;
    final my = metricById(_metrics, _yId) ?? _metrics.first;
    final days = _data.keys.toList()..sort();
    final xs = <double>[];
    final ys = <double>[];
    for (final k in days) {
      final x = mx.fn(_data[k]!);
      final y = my.fn(_data[k]!);
      if (x != null && y != null) {
        xs.add(x);
        ys.add(y);
      }
    }
    final p = pearson(xs, ys);

    void preset(String x, String y) => setState(() {
          _xId = x;
          _yId = y;
        });

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compare two things', style: tt.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('Sleep and mood'), onPressed: () => preset('d.sleep_hours', 'd.mood')),
                ActionChip(label: const Text('Caffeine and sleep quality'), onPressed: () => preset('d.caffeine', 'f.sleep.quality')),
                ActionChip(label: const Text('Exercise and mood'), onPressed: () => preset('d.exercise', 'd.mood')),
                ActionChip(label: const Text('Screen time and sleep'), onPressed: () => preset('f.screen.total', 'd.sleep_hours')),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: Text('A: ${mx.label}', overflow: TextOverflow.ellipsis),
              onPressed: () => _pick(_xId, (v) => _xId = v),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.swap_vert),
              label: Text('B: ${my.label}', overflow: TextOverflow.ellipsis),
              onPressed: () => _pick(_yId, (v) => _yId = v),
            ),
            const SizedBox(height: 12),
            if (p == null)
              Text(
                'Needs at least 5 days where both are logged (found ${xs.length}).',
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else ...[
              SizedBox(
                height: 170,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: ScatterPainter(xs, ys, cs.primary, cs.outlineVariant, cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              Text('Correlation ${p.r.toStringAsFixed(2)} over ${p.n} days', style: tt.titleSmall),
              Text(describeR(p.r)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricPicker extends StatefulWidget {
  const _MetricPicker({required this.metrics});
  final List<Metric> metrics;

  @override
  State<_MetricPicker> createState() => _MetricPickerState();
}

class _MetricPickerState extends State<_MetricPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final list = [
      for (final m in widget.metrics)
        if (q.isEmpty || m.label.toLowerCase().contains(q)) m,
    ];
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + MediaQuery.of(context).viewInsets.bottom * 0),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search fields',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => ListTile(
                dense: true,
                title: Text(list[i].label),
                onTap: () => Navigator.pop(context, list[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painters -------------------------------------------------------------------------

void _text(Canvas c, String s, Offset o, Color color, {bool right = false}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: 10, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, right ? Offset(o.dx - tp.width, o.dy) : o);
}

class LinePainter extends CustomPainter {
  LinePainter(this.values, this.color, this.grid, this.label);

  final List<double?> values;
  final Color color;
  final Color grid;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    final present = [for (final v in values) if (v != null) v];
    if (present.length < 2) return;
    var lo = present.reduce((a, b) => a < b ? a : b);
    var hi = present.reduce((a, b) => a > b ? a : b);
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    const left = 38.0, top = 8.0, bottom = 6.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = top + h * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      _text(canvas, fmtNum(hi - (hi - lo) * i / 2), Offset(left - 4, y - 6), label, right: true);
    }
    final n = values.length;
    Offset pt(int i, double v) =>
        Offset(left + (n == 1 ? 0 : w * i / (n - 1)), top + h * (1 - (v - lo) / (hi - lo)));
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    Offset? prev;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v == null) continue;
      final p = pt(i, v);
      if (prev != null) canvas.drawLine(prev, p, line);
      prev = p;
    }
    final dot = Paint()..color = color;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v != null) canvas.drawCircle(pt(i, v), n > 40 ? 1.5 : 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter old) =>
      old.values != values || old.color != color;
}

class ScatterPainter extends CustomPainter {
  ScatterPainter(this.xs, this.ys, this.color, this.grid, this.label);

  final List<double> xs;
  final List<double> ys;
  final Color color;
  final Color grid;
  final Color label;

  @override
  void paint(Canvas canvas, Size size) {
    if (xs.isEmpty) return;
    var x0 = xs.reduce((a, b) => a < b ? a : b), x1 = xs.reduce((a, b) => a > b ? a : b);
    var y0 = ys.reduce((a, b) => a < b ? a : b), y1 = ys.reduce((a, b) => a > b ? a : b);
    if (x0 == x1) {
      x0 -= 1;
      x1 += 1;
    }
    if (y0 == y1) {
      y0 -= 1;
      y1 += 1;
    }
    const left = 38.0, top = 8.0, bottom = 18.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final axis = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, top), Offset(left, top + h), axis);
    canvas.drawLine(Offset(left, top + h), Offset(left + w, top + h), axis);
    _text(canvas, fmtNum(y1), Offset(left - 4, top - 4), label, right: true);
    _text(canvas, fmtNum(y0), Offset(left - 4, top + h - 8), label, right: true);
    _text(canvas, fmtNum(x0), Offset(left, top + h + 3), label);
    _text(canvas, fmtNum(x1), Offset(left + w - 14, top + h + 3), label);
    final dot = Paint()..color = color.withAlpha(170);
    for (var i = 0; i < xs.length; i++) {
      final p = Offset(left + w * (xs[i] - x0) / (x1 - x0), top + h * (1 - (ys[i] - y0) / (y1 - y0)));
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant ScatterPainter old) => old.xs != xs || old.ys != ys;
}
