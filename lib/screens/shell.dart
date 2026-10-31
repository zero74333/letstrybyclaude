import 'package:flutter/material.dart';

import '../app_state.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'insights_screen.dart';

/// Bottom navigation: Today (dashboard), History, Insights.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, i, _) {
        const pages = <Widget>[DashboardScreen(), HistoryScreen(), InsightsScreen()];
        return Scaffold(
          body: IndexedStack(index: i, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => shellTab.value = v,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Today'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'),
            ],
          ),
        );
      },
    );
  }
}
