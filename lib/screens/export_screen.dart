import 'package:flutter/material.dart';

import '../export_service.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _restore(BuildContext context, bool backupWins) async {
    await _run(context, () async {
      final n = await ExportService.restoreBackup(backupWins: backupWins);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n == 0 ? 'No file picked' : 'Restored $n day(s)')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Export & backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Share', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => _run(context, ExportService.shareMarkdown),
            icon: const Icon(Icons.description),
            label: const Text('Export as Markdown (.md)'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => _run(context, ExportService.shareCsv),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export days as CSV (spreadsheet)'),
          ),
          const SizedBox(height: 24),
          Text('Backup', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'The backup holds every day, your master data, targets and custom options. '
            'It does not include your PIN.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => _run(context, ExportService.shareBackup),
            icon: const Icon(Icons.backup),
            label: const Text('Save backup (.json)'),
          ),
          const SizedBox(height: 24),
          Text('Restore', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Merge keeps what is on this phone and only adds what is missing. '
            'Restore lets the backup win when the same item exists in both.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _restore(context, false),
            icon: const Icon(Icons.merge_type),
            label: const Text('Merge from backup (keep my current data)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _restore(context, true),
            icon: const Icon(Icons.restore),
            label: const Text('Restore from backup (backup wins)'),
          ),
        ],
      ),
    );
  }
}
