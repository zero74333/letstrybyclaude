import 'package:flutter/material.dart';

/// Field types from the v4 structure. `calc` = calculated by the app (read only).
enum T { text, long, number, scale, yesNo, time, date, duration, single, multi, link, calc }

class F {
  const F(
    this.k,
    this.label,
    this.type, {
    this.opts = const <String>[],
    this.unit,
    this.worst = false,
    this.hint,
    this.list,
    this.def,
    this.signed = false,
  });

  final String k;
  final String label;
  final T type;
  final List<String> opts;
  final String? unit;

  /// Scales where 10 = worst / strongest.
  final bool worst;
  final String? hint;

  /// For link fields: master list id(s) joined by "+", or "@meals", "@tasks", "@ideas".
  final String? list;

  /// For time fields: key in Targets used as the default.
  final String? def;
  final bool signed;
}

F txt(String k, String l, {String? hint}) => F(k, l, T.text, hint: hint);
F long(String k, String l, {String? hint}) => F(k, l, T.long, hint: hint);
F nbr(String k, String l, {String? unit, bool signed = false}) =>
    F(k, l, T.number, unit: unit, signed: signed);
F scale(String k, String l, {bool worst = false}) => F(k, l, T.scale, worst: worst);
F yn(String k, String l) => F(k, l, T.yesNo);
F tm(String k, String l, {String? def}) => F(k, l, T.time, def: def);
F dt(String k, String l) => F(k, l, T.date);
F dur(String k, String l, {bool signed = false}) => F(k, l, T.duration, signed: signed);
F one(String k, String l, List<String> o) => F(k, l, T.single, opts: o);
F many(String k, String l, List<String> o) => F(k, l, T.multi, opts: o);
F lnk(String k, String l, String list) => F(k, l, T.link, list: list);
F calc(String k, String l) => F(k, l, T.calc);

/// Copies one row into another page's repeat group (for example Idea -> Task).
class RowAction {
  const RowAction(this.label, this.icon, this.toPage, this.toGroup, this.map,
      {this.extra = const <String, dynamic>{}});

  final String label;
  final IconData icon;
  final String toPage;
  final String toGroup;

  /// "fromField" or "a|b" (first non-empty) -> "toField".
  final Map<String, String> map;
  final Map<String, dynamic> extra;
}

/// A card on a page. Flat group = fields stored once per day.
/// Repeat group = list of rows. `block` = custom widget instead of fields.
class G {
  G(
    this.id,
    this.title,
    this.fields, {
    this.repeat = false,
    this.max,
    this.block,
    this.module,
    this.rowAction,
    this.item,
    this.note,
  });

  final String id;
  final String title;
  final List<F> fields;
  final bool repeat;
  final int? max;
  final String? block;

  /// Optional module key ("cycle", "intake"). Hidden until enabled in Settings.
  final String? module;
  final RowAction? rowAction;
  final String? item;
  final String? note;
}

class PageDef {
  PageDef(this.id, this.title, this.icon, this.groups);

  final String id;
  final String title;
  final IconData icon;
  final List<G> groups;
}

class Sect {
  Sect(this.id, this.title, this.icon, this.color, this.blurb, this.pages);

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String blurb;
  final List<PageDef> pages;
}

// Shared option sets.
const severity = ['none', 'mild', 'moderate', 'strong'];
const partOfDay = ['morning', 'afternoon', 'evening', 'night'];
const lifeArea = [
  'health', 'mind', 'work', 'learning', 'money', 'relationships', 'family',
  'spiritual', 'home', 'fun', 'other',
];
const emotions = [
  'calm', 'happy', 'grateful', 'hopeful', 'motivated', 'content', 'excited',
  'proud', 'loved', 'tired', 'bored', 'restless', 'anxious', 'worried', 'sad',
  'lonely', 'irritable', 'angry', 'frustrated', 'overwhelmed', 'guilty',
  'ashamed', 'numb',
];
const stressCauses = [
  'workload', 'deadlines', 'money', 'health', 'relationships', 'family',
  'uncertainty about the future', 'lack of sleep', 'conflict',
  'noise or environment', 'too many decisions', 'social pressure',
  'self-expectations', 'news or social media', 'other',
];
const taskStatus = ['todo', 'doing', 'done', 'moved to later', 'waiting', 'dropped'];
const notDoneWhy = [
  'ran out of time', 'low energy', 'blocked', 'unclear', 'distracted',
  'deprioritized', 'unexpected event', 'avoided',
];
