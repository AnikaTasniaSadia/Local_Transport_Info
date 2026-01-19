import 'package:flutter/material.dart';

import '../../data/models/stop.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.isEnglish,
    required this.isLoadingStops,
    required this.stops,
    required this.stopsLoadError,
    required this.fromStopId,
    required this.toStopId,
    required this.onReloadStops,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSearch,
    required this.onApplyPopularRoute,
  });

  final bool isEnglish;
  final bool isLoadingStops;
  final List<Stop> stops;
  final String? stopsLoadError;

  final String? fromStopId;
  final String? toStopId;

  final VoidCallback onReloadStops;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final VoidCallback onSearch;
  final void Function({required String fromEn, required String toEn})
  onApplyPopularRoute;

  bool get _canSearch =>
      fromStopId != null && toStopId != null && fromStopId != toStopId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Find Your Bus Fare',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Reload stops',
                              onPressed: isLoadingStops ? null : onReloadStops,
                              icon: isLoadingStops
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Government approved bus fare & routes',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLoadingStops
                              ? 'Loading stops…'
                              : 'Stops loaded: ${stops.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (!isLoadingStops &&
                            stopsLoadError == null &&
                            stops.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'If you see 0 stops, enable a SELECT policy for anon in Supabase (RLS).',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        if (stopsLoadError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            stopsLoadError!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 20),
                        DropdownMenu<String>(
                          expandedInsets: EdgeInsets.zero,
                          label: const Text('From Stop'),
                          enabled: !(isLoadingStops || stops.isEmpty),
                          initialSelection: fromStopId,
                          onSelected: onFromChanged,
                          dropdownMenuEntries: stops
                              .map(
                                (stop) => DropdownMenuEntry<String>(
                                  value: stop.stopId,
                                  label: stop.displayName(isEnglish: isEnglish),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 12),
                        DropdownMenu<String>(
                          expandedInsets: EdgeInsets.zero,
                          label: const Text('To Stop'),
                          enabled: !(isLoadingStops || stops.isEmpty),
                          initialSelection: toStopId,
                          onSelected: onToChanged,
                          dropdownMenuEntries: stops
                              .map(
                                (stop) => DropdownMenuEntry<String>(
                                  value: stop.stopId,
                                  label: stop.displayName(isEnglish: isEnglish),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _canSearch ? onSearch : null,
                          child: const Text('Search Route'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Popular Routes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionChip(
                      label: const Text('Mirpur → Farmgate'),
                      onPressed: (isLoadingStops || stops.isEmpty)
                          ? null
                          : () => onApplyPopularRoute(
                              fromEn: 'Mirpur',
                              toEn: 'Farmgate',
                            ),
                    ),
                    ActionChip(
                      label: const Text('Gulistan → Jatrabari'),
                      onPressed: (isLoadingStops || stops.isEmpty)
                          ? null
                          : () => onApplyPopularRoute(
                              fromEn: 'Gulistan',
                              toEn: 'Jatrabari',
                            ),
                    ),
                    ActionChip(
                      label: const Text('Uttara → Motijheel'),
                      onPressed: (isLoadingStops || stops.isEmpty)
                          ? null
                          : () => onApplyPopularRoute(
                              fromEn: 'Uttara',
                              toEn: 'Motijheel',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
