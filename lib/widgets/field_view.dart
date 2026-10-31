import 'package:flutter/material.dart';

import '../app_state.dart';
import '../auto.dart' show minsOf;
import '../schema/all.dart';

typedef OnVal = void Function(dynamic v, bool quiet);

String _two(int n) => n.toString().padLeft(2, '0');

String _hhmm(num minutes) {
  final t = minutes.abs().round();
  return '${minutes < 0 ? '-' : ''}${t ~/ 60} h ${_two(t % 60)} min';
}

/// Renders one field of any type. Used by day pages, repeat rows,
/// master data items and targets.
class FieldView extends StatelessWidget {
  const FieldView({
    super.key,
    required this.f,
    required this.scope,
    required this.value,
    required this.onChanged,
    required this.optPath,
    required this.accent,
    this.autoText,
    this.dayData,
  });

  final F f;

  /// Unique id of the surrounding object (keeps text controllers stable).
  final String scope;
  final dynamic value;
  final OnVal onChanged;

  /// Path used to store custom chip options for this field.
  final String optPath;
  final Color accent;
  final String? autoText;
  final Map<String, dynamic>? dayData;

  @override
  Widget build(BuildContext context) {
    switch (f.type) {
      case T.text:
      case T.long:
      case T.number:
      case T.duration:
      case T.link:
        return _TextBox(
          key: ValueKey('$scope|${f.k}'),
          f: f,
          value: value,
          onChanged: onChanged,
          options: f.type == T.link
              ? appState.linkOptions(f.list ?? '', dayData ?? store.data)
              : const <String>[],
        );
      case T.scale:
        return _ScaleField(f: f, value: value, onChanged: onChanged, accent: accent);
      case T.yesNo:
        return _YesNoField(f: f, value: value, onChanged: onChanged, accent: accent);
      case T.time:
        return _TimeField(f: f, value: value, onChanged: onChanged);
      case T.date:
        return _DateField(f: f, value: value, onChanged: onChanged);
      case T.single:
      case T.multi:
        return _ChipsField(
            f: f, value: value, onChanged: onChanged, optPath: optPath, accent: accent);
      case T.calc:
        return _CalcField(f: f, text: autoText);
    }
  }
}

class _TextBox extends StatefulWidget {
  const _TextBox({
    super.key,
    required this.f,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final F f;
  final dynamic value;
  final OnVal onChanged;
  final List<String> options;

  @override
  State<_TextBox> createState() => _TextBoxState();
}

class _TextBoxState extends State<_TextBox> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _c = TextEditingController(text: v == null ? '' : (v is num ? fmtNum(v) : v.toString()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickLink() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final o in widget.options)
              ListTile(title: Text(o), onTap: () => Navigator.pop(ctx, o)),
          ],
        ),
      ),
    );
    if (choice != null) {
      _c.text = choice;
      widget.onChanged(choice, true);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    final numeric = f.type == T.number || f.type == T.duration;
    String? helper;
    if (f.type == T.duration) {
      final n = num.tryParse(_c.text.trim());
      if (n != null && n.abs() >= 60) helper = _hhmm(n);
    }
    return TextField(
      controller: _c,
      keyboardType: numeric
          ? TextInputType.numberWithOptions(decimal: true, signed: f.signed)
          : (f.type == T.long ? TextInputType.multiline : TextInputType.text),
      minLines: f.type == T.long ? 3 : 1,
      maxLines: f.type == T.long ? 8 : 1,
      textCapitalization: numeric ? TextCapitalization.none : TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: f.label,
        hintText: f.hint,
        suffixText: f.type == T.duration ? 'min' : f.unit,
        helperText: helper,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: (f.type == T.link && widget.options.isNotEmpty)
            ? IconButton(
                tooltip: 'Pick from list',
                icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                onPressed: _pickLink,
              )
            : null,
      ),
      onChanged: (t) {
        final s = t.trim();
        if (numeric) {
          widget.onChanged(s.isEmpty ? null : (num.tryParse(s) ?? s), false);
          if (f.type == T.duration) setState(() {});
        } else {
          widget.onChanged(t, true);
        }
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _ScaleField extends StatelessWidget {
  const _ScaleField({
    required this.f,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final F f;
  final dynamic value;
  final OnVal onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cur = value is num ? (value as num).toInt() : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(f.worst ? '${f.label} (10 = worst)' : f.label),
        Row(
          children: [
            for (var i = 1; i <= 10; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onChanged(cur == i ? null : i, false),
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cur == i
                            ? accent
                            : (cur != null && i < cur
                                ? accent.withAlpha(40)
                                : cs.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: cur == i ? FontWeight.w700 : FontWeight.w400,
                          color: cur == i ? Colors.white : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _YesNoField extends StatelessWidget {
  const _YesNoField({
    required this.f,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  final F f;
  final dynamic value;
  final OnVal onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final v = value is bool ? value as bool : null;
    return Row(
      children: [
        Expanded(child: Text(f.label, style: Theme.of(context).textTheme.bodyLarge)),
        ChoiceChip(
          label: const Text('Yes'),
          selected: v == true,
          selectedColor: accent.withAlpha(70),
          onSelected: (s) => onChanged(s ? true : null, false),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('No'),
          selected: v == false,
          selectedColor: accent.withAlpha(70),
          onSelected: (s) => onChanged(s ? false : null, false),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.f, required this.value, required this.onChanged});

  final F f;
  final dynamic value;
  final OnVal onChanged;

  Future<void> _pick(BuildContext context) async {
    final m = minsOf(value) ?? minsOf(appState.targets[f.def ?? '']) ?? 12 * 60;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (m ~/ 60) % 24, minute: m % 60),
    );
    if (t != null) onChanged('${_two(t.hour)}:${_two(t.minute)}', false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final has = value is String && (value as String).isNotEmpty;
    final defText = f.def == null ? null : asStr(appState.targets[f.def!]);
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: f.label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: has
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(null, false),
                )
              : const Icon(Icons.access_time, size: 18),
        ),
        child: Text(
          has ? value as String : (defText == null ? ' ' : 'Target $defText'),
          style: TextStyle(color: has ? null : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.f, required this.value, required this.onChanged});

  final F f;
  final dynamic value;
  final OnVal onChanged;

  Future<void> _pick(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (value is String) {
      try {
        initial = parseKeySafe(value as String) ?? initial;
      } catch (_) {}
    }
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      onChanged('${d.year}-${_two(d.month)}-${_two(d.day)}', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = value is String && (value as String).isNotEmpty;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: f.label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: has
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onChanged(null, false),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(has ? fmtLong(value as String) : ' '),
      ),
    );
  }
}

DateTime? parseKeySafe(String s) {
  final p = s.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

class _ChipsField extends StatelessWidget {
  const _ChipsField({
    required this.f,
    required this.value,
    required this.onChanged,
    required this.optPath,
    required this.accent,
  });

  final F f;
  final dynamic value;
  final OnVal onChanged;
  final String optPath;
  final Color accent;

  Future<void> _addOption(BuildContext context) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add option to "${f.label}"'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Add')),
        ],
      ),
    );
    c.dispose();
    if (v != null && v.trim().isNotEmpty) await appState.addCustomOption(optPath, v);
  }

  Future<void> _removeOption(BuildContext context, String o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "$o" from this list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await appState.removeCustomOption(optPath, o);
  }

  @override
  Widget build(BuildContext context) {
    final multi = f.type == T.multi;
    final custom = appState.customOptions[optPath] ?? const <String>[];
    final sel = multi
        ? asList(value)
        : (asStr(value) == null ? <String>[] : <String>[asStr(value)!]);
    final opts = <String>[...f.opts, ...custom];
    for (final s in sel) {
      if (!opts.contains(s)) opts.add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(f.label),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final o in opts)
              GestureDetector(
                onLongPress: custom.contains(o) ? () => _removeOption(context, o) : null,
                child: multi
                    ? FilterChip(
                        label: Text(o),
                        selected: sel.contains(o),
                        selectedColor: accent.withAlpha(70),
                        visualDensity: VisualDensity.compact,
                        onSelected: (s) {
                          final l = List<String>.from(sel);
                          if (s) {
                            l.add(o);
                          } else {
                            l.remove(o);
                          }
                          onChanged(l.isEmpty ? null : l, false);
                        },
                      )
                    : ChoiceChip(
                        label: Text(o),
                        selected: sel.contains(o),
                        selectedColor: accent.withAlpha(70),
                        visualDensity: VisualDensity.compact,
                        onSelected: (s) => onChanged(s ? o : null, false),
                      ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              visualDensity: VisualDensity.compact,
              onPressed: () => _addOption(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalcField extends StatelessWidget {
  const _CalcField({required this.f, required this.text});

  final F f;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: f.label,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withAlpha(120),
        prefixIcon: const Icon(Icons.calculate_outlined, size: 18),
      ),
      child: Text(
        text ?? 'Calculated from your entries',
        style: TextStyle(color: text == null ? cs.onSurfaceVariant : null),
      ),
    );
  }
}
