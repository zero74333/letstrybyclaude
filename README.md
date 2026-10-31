# Zeeshan Daily Life Style (v2)

Offline personal life tracker for Android. Everything is stored on the phone in SQLite.
The home screen is an icon grid. Each section opens as its own screen of pages, so there is
no long scrolling list.

## Sections (from life-tracker-v4)

Daily Log, Health & Body, Mind & Mood, Ideaverse, Work & Learning, Money, Relationships,
Habits & Routines, Activities. Plus Master data, Export & backup and Settings tiles.

Also included: quick add (water, mood, expense, idea, symptom), History with search,
Insights (trends, last-7-days card, correlations), PIN lock, custom chips on any choice
field, tags and notes on every page, calculated fields, streaks, bills due, carry-over of
unfinished tasks, and gentle health prompts.

## Project layout

```
.github/workflows/build-apk.yml
assets/icon.png            <- keep your existing icon here
pubspec.yaml
lib/
  main.dart
  app_state.dart           settings, master data, the open day, autosave
  database.dart            SQLite (days, master, settings)
  auto.dart                calculated fields, streaks, advisories
  metrics.dart             numbers used by Insights
  export_service.dart      Markdown, CSV, JSON backup and restore
  schema/                  the v4 structure as data (edit here to add fields)
  screens/
  widgets/
```

## Upgrading from the first version

1. Replace your repo files with this folder, keeping `assets/icon.png`.
2. Delete the old files that are no longer used:
   `lib/fields.dart`, `lib/screens/day_editor.dart`, `lib/screens/home_screen.dart`,
   `lib/screens/today_screen.dart`.
3. Push to `main`. Your existing days stay in the database. Day rating and overall mood carry
   over; other old fields are kept in the data but are not shown in the new layout.

## Build the APK on GitHub

1. Push everything, including the `.github` folder, to the `main` branch.
2. Open the **Actions** tab. "Build Android APK" runs on every push.
3. Download the artifact `zeeshan-daily-life-style-apk`, unzip, install `app-release.apk`.

To rebuild without a change, open Actions, pick the workflow and press **Run workflow**.

## Adding or changing fields

Open `lib/schema/sections_a.dart`, `sections_b.dart` or `sections_c.dart`. Each page is a list
of groups, each group a list of fields such as `txt`, `scale`, `one` (single choice), `many`
(multi choice), `tm` (time). Add a line and the field appears in the app and in every export.
