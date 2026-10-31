import 'package:flutter/material.dart';

import 'app_state.dart';
import 'database.dart';
import 'screens/lock_screen.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.init();
  await store.open(dateKey(DateTime.now()));
  runApp(const ZeeshanLifeStyleApp());
}

const _seed = Color(0xFFC9A65A);

class ZeeshanLifeStyleApp extends StatefulWidget {
  const ZeeshanLifeStyleApp({super.key});

  @override
  State<ZeeshanLifeStyleApp> createState() => _ZeeshanLifeStyleAppState();
}

class _ZeeshanLifeStyleAppState extends State<ZeeshanLifeStyleApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  String _openedToday = dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      store.flush();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away > const Duration(seconds: 60)) appState.lock();
      // If the app stayed open past midnight, move Today to the new day.
      final today = dateKey(DateTime.now());
      if (today != _openedToday) {
        if (store.date == _openedToday) store.open(today);
        _openedToday = today;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Zeeshan Daily Life Style',
          debugShowCheckedModeBanner: false,
          themeMode: appState.theme,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: _seed,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: _seed,
            brightness: Brightness.dark,
          ),
          home: appState.locked ? const LockScreen() : const Shell(),
        );
      },
    );
  }
}
