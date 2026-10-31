import 'package:flutter/material.dart';

import 'types.dart';

/// A master list (set up once, reused in dropdowns).
class MasterList {
  MasterList(this.id, this.title, this.icon, this.primary, this.fields);

  final String id;
  final String title;
  final IconData icon;

  /// Field key shown as the item name.
  final String primary;
  final List<F> fields;
}

final List<MasterList> masterLists = [
  MasterList('goals', 'Goals', Icons.flag_outlined, 'name', [
    txt('name', 'Name'),
    one('area', 'Life area', lifeArea),
    txt('why', 'Why'),
    dt('target', 'Target date'),
    long('milestones', 'Milestones'),
    one('status', 'Status', ['active', 'paused', 'done', 'dropped']),
    nbr('progress', 'Progress', unit: '%'),
  ]),
  MasterList('projects', 'Projects', Icons.folder_outlined, 'name', [
    txt('name', 'Name'),
    lnk('goal', 'Linked goal', 'goals'),
    one('status', 'Status', ['planned', 'active', 'paused', 'done']),
    txt('next', 'Next action'),
  ]),
  MasterList('skills', 'Skills', Icons.school_outlined, 'name', [
    txt('name', 'Name'),
    scale('level', 'Current level'),
    scale('target', 'Target level'),
    long('resources', 'Resources'),
  ]),
  MasterList('habits', 'Habits', Icons.repeat, 'name', [
    txt('name', 'Name'),
    one('kind', 'Build or break', ['build', 'break']),
    one('tracking', 'Tracking type', ['yes/no', 'minutes', 'count']),
    nbr('target', 'Target'),
    one('freq', 'Frequency', ['daily', 'weekdays', 'weekly']),
    txt('cue', 'Cue'),
    tm('reminder', 'Reminder'),
  ]),
  MasterList('meds', 'Medicines & supplements', Icons.medication_outlined, 'name', [
    txt('name', 'Name'),
    txt('dose', 'Dose'),
    txt('schedule', 'Schedule'),
    txt('purpose', 'Purpose'),
    txt('by', 'Prescribed by'),
    dt('refill', 'Refill date'),
  ]),
  MasterList('bills', 'Bills & subscriptions', Icons.receipt_long_outlined, 'name', [
    txt('name', 'Name'),
    nbr('amount', 'Amount'),
    nbr('day', 'Due day of month'),
    one('freq', 'Frequency', ['monthly', 'yearly']),
    nbr('month', 'Due month (yearly only)'),
    yn('auto', 'Auto-pay'),
  ]),
  MasterList('expcats', 'Expense categories', Icons.category_outlined, 'name', [
    txt('name', 'Name'),
    nbr('budget', 'Monthly budget'),
  ]),
  MasterList('people', 'People', Icons.people_outline, 'name', [
    txt('name', 'Name'),
    one('rel', 'Relationship', ['family', 'partner', 'friend', 'colleague', 'mentor', 'client', 'neighbor', 'other']),
    dt('birthday', 'Birthday'),
    nbr('freq', 'Want to be in touch every', unit: 'days'),
  ]),
  MasterList('foods', 'Foods', Icons.restaurant_menu, 'name', [
    txt('name', 'Name'),
    one('kind', 'Type', ['safe food', 'known trigger', 'neutral']),
  ]),
  MasterList('principles', 'Principles', Icons.auto_stories_outlined, 'text', [
    long('text', 'Principle'),
    dt('added', 'Date added'),
    txt('from', 'From which thought'),
  ]),
];

MasterList? masterById(String id) {
  for (final m in masterLists) {
    if (m.id == id) return m;
  }
  return null;
}

/// Targets and limits.
final List<F> targetFields = [
  tm('bedtime', 'Bedtime'),
  tm('wake', 'Wake time'),
  nbr('sleep_hours', 'Sleep hours', unit: 'h'),
  tm('caffeine_cutoff', 'Caffeine cutoff time'),
  nbr('water', 'Water', unit: 'L'),
  nbr('steps', 'Steps'),
  nbr('screen', 'Screen limit', unit: 'h'),
  nbr('budget', 'Daily budget'),
];

const Map<String, dynamic> defaultTargets = {
  'bedtime': '23:00',
  'wake': '07:00',
  'sleep_hours': 8,
  'caffeine_cutoff': '15:00',
  'water': 2.5,
  'steps': 8000,
  'screen': 3,
};
