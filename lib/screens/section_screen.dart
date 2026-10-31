import 'package:flutter/material.dart';

import '../app_state.dart';
import '../schema/all.dart';
import '../widgets/tiles.dart';
import 'page_screen.dart';
import 'quick_add.dart';

/// A section opens as its own grid of pages (Sleep, Meals, Gut ...).
class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.sect});

  final Sect sect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([store, appState]),
      builder: (context, _) {
        final pages = [
          for (final p in sect.pages)
            if (p.groups.any((g) => g.module == null || appState.modules[g.module] == true)) p,
        ];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: sect.color.withAlpha(36),
            title: Text(sect.title),
          ),
          floatingActionButton: sect.id == 'ideaverse'
              ? FloatingActionButton.extended(
                  backgroundColor: sect.color,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Capture idea'),
                  onPressed: () => showQuickIdea(context),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: sect.color.withAlpha(42),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(sect.icon, color: sect.color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sect.blurb, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${weekdayOf(store.date)}, ${fmtLong(store.date)}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: gridColumns(context),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  for (final p in pages)
                    AppTile(
                      icon: p.icon,
                      title: p.title,
                      color: sect.color,
                      count: store.pageCount(p),
                      subtitle: store.pageCount(p) == 0 ? 'Not started' : '${store.pageCount(p)} logged',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PageScreen(sect: sect, page: p)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
