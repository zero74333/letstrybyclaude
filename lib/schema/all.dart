import 'package:flutter/material.dart';

import 'sections_a.dart';
import 'sections_b.dart';
import 'sections_c.dart';
import 'types.dart';

export 'master_schema.dart';
export 'sections_a.dart';
export 'sections_b.dart';
export 'sections_c.dart';
export 'types.dart';

final List<Sect> sections = [
  sDaily, sHealth, sMind, sIdeaverse, sWork, sMoney, sSocial, sHabits, sActivities,
];

final List<PageDef> allPages = [for (final s in sections) ...s.pages];

PageDef? pageById(String id) {
  for (final p in allPages) {
    if (p.id == id) return p;
  }
  return null;
}

Sect? sectOfPage(String pageId) {
  for (final s in sections) {
    for (final p in s.pages) {
      if (p.id == pageId) return s;
    }
  }
  return null;
}

/// Storage key for a flat field: "page.field". Repeat groups: "page.group".
String flatKey(String pageId, String field) => '$pageId.$field';
String groupKey(String pageId, String groupId) => '$pageId.$groupId';

const Color kNeutral = Color(0xFF7A7F87);
