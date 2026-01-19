import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/stop.dart';
import '../map/stop_coordinates.dart';

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

  Widget _buildMiniMap(BuildContext context) {
    final from = StopCoordinates.ofStop(fromStopId);
    final to = StopCoordinates.ofStop(toStopId);

    if (from == null || to == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.map_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Select From and To stops to preview the route on the map.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('from'),
        position: from,
        infoWindow: InfoWindow(title: _stopName(fromStopId)),
      ),
      Marker(
        markerId: const MarkerId('to'),
        position: to,
        infoWindow: InfoWindow(title: _stopName(toStopId)),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: [from, to],
        width: 4,
        color: Theme.of(context).colorScheme.primary,
      ),
    };

    final center = LatLng(
      (from.latitude + to.latitude) / 2,
      (from.longitude + to.longitude) / 2,
    );

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 12),
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: false,
            scrollGesturesEnabled: false,
          ),
        ),
      ),
    );
  }

  String _stopName(String? stopId) {
    if (stopId == null) return '';
    final stop = stops.where((s) => s.stopId == stopId).firstOrNull;
    return stop?.displayName(isEnglish: isEnglish) ?? stopId;
  }

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
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isLoadingStops
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh,
                                        key: ValueKey('idle'),
                                      ),
                              ),
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isLoadingStops
                                ? 'Loading stops…'
                                : 'Stops loaded: ${stops.length}',
                            key: ValueKey(
                              isLoadingStops
                                  ? 'loading-stops'
                                  : 'stops-${stops.length}',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
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
                        const SizedBox(height: 16),
                        _buildMiniMap(context),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
