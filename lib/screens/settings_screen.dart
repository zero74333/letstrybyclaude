import 'package:flutter/material.dart';

import '../app_state.dart';
import '../schema/all.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<String?> _askPin(BuildContext context, {required bool confirm}) async {
    final a = TextEditingController();
    final b = TextEditingController();
    String? error;
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Choose a PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: a,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN (4 to 8 digits)'),
              ),
              if (confirm)
                TextField(
                  controller: b,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Repeat PIN'),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final p = a.text.trim();
                if (p.length < 4 || p.length > 8 || int.tryParse(p) == null) {
                  setState(() => error = 'Use 4 to 8 digits.');
                } else if (confirm && p != b.text.trim()) {
                  setState(() => error = 'The two PINs do not match.');
                } else {
                  Navigator.pop(ctx, p);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    a.dispose();
    b.dispose();
    return pin;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'system', label: Text('System')),
                  ButtonSegment(value: 'light', label: Text('Light')),
                  ButtonSegment(value: 'dark', label: Text('Dark')),
                ],
                selected: {appState.themeMode},
                onSelectionChanged: (s) => appState.setTheme(s.first),
              ),
              const SizedBox(height: 24),
              Text('App lock', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Your log holds health, money and private thoughts. A PIN locks the app '
                'when you come back after a minute away.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              if (appState.pinHash == null)
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Set a PIN'),
                  onPressed: () async {
                    final p = await _askPin(context, confirm: true);
                    if (p != null) await appState.setPin(p);
                  },
                )
              else
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Change PIN'),
                      onPressed: () async {
                        final p = await _askPin(context, confirm: true);
                        if (p != null) await appState.setPin(p);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Remove PIN'),
                      onPressed: () => appState.setPin(null),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text('Sections on the dashboard', style: Theme.of(context).textTheme.titleMedium),
              for (final s in sections)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(s.icon, color: s.color),
                  title: Text(s.title),
                  value: !appState.hiddenSections.contains(s.id),
                  onChanged: (v) => appState.setHidden(s.id, !v),
                ),
              const SizedBox(height: 16),
              Text('Optional modules', style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cycle tracking'),
                subtitle: const Text('Adds a card to Health & Body > Medicines & follow-ups'),
                value: appState.modules['cycle'] == true,
                onChanged: (v) => appState.setModule('cycle', v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tobacco, alcohol or other'),
                subtitle: const Text('Adds a card to Health & Body > Drinks & supplements'),
                value: appState.modules['intake'] == true,
                onChanged: (v) => appState.setModule('intake', v),
              ),
              const SizedBox(height: 24),
              Text('Good to know', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Hidden sections keep their data. Turning one back on shows it again.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}
