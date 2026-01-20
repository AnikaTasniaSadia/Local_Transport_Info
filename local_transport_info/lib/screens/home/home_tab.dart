import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/fare_quote.dart';
import '../../data/models/stop.dart';
import '../../services/app_config.dart';
import '../map/stop_coordinates.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.isEnglish,
    required this.isLoadingStops,
    required this.stops,
    required this.stopsLoadError,
    required this.fromStopId,
    required this.toStopId,
    required this.fareQuote,
    required this.fareError,
    required this.isLoadingFare,
    required this.hasSearched,
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

  final FareQuote? fareQuote;
  final String? fareError;
  final bool isLoadingFare;
  final bool hasSearched;

  final VoidCallback onReloadStops;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final Future<void> Function() onSearch;
  final void Function({required String fromId, required String toId})
  onApplyPopularRoute;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _distanceController = TextEditingController();

  double? get _distanceKm {
    final text = _distanceController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return value;
  }

  double? get _estimatedFare {
    final km = _distanceKm;
    if (km == null) return null;
    return km * AppConfig.fallbackRatePerKm;
  }

  double _payableFare(double fare) {
    final rounded = (fare / 5).ceil() * 5;
    return rounded < 10 ? 10 : rounded.toDouble();
  }

  double? _estimateDistanceKm(String fromId, String toId) {
    final from = StopCoordinates.ofStop(fromId);
    final to = StopCoordinates.ofStop(toId);
    if (from == null || to == null) return null;
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return meters / 1000;
  }

  bool get _canSearch =>
      widget.fromStopId != null &&
      widget.toStopId != null &&
      widget.fromStopId != widget.toStopId;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  Widget _buildMiniMap(BuildContext context) {
    final from = StopCoordinates.ofStop(widget.fromStopId);
    final to = StopCoordinates.ofStop(widget.toStopId);

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
        infoWindow: InfoWindow(title: _stopName(widget.fromStopId)),
      ),
      Marker(
        markerId: const MarkerId('to'),
        position: to,
        infoWindow: InfoWindow(title: _stopName(widget.toStopId)),
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
    final stop = widget.stops.where((s) => s.stopId == stopId).firstOrNull;
    return stop?.displayName(isEnglish: widget.isEnglish) ?? stopId;
  }

  String _stopLabel(String stopId) {
    final stop = widget.stops.where((s) => s.stopId == stopId).firstOrNull;
    return stop?.displayName(isEnglish: widget.isEnglish) ?? stopId;
  }

  Iterable<Stop> _filterStops(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return widget.stops;
    return widget.stops.where((stop) {
      final name = stop.displayName(isEnglish: widget.isEnglish).toLowerCase();
      return name.contains(q) || stop.stopId.toLowerCase().contains(q);
    });
  }

  Widget _buildStopAutocomplete({
    required String label,
    required String? selectedId,
    required ValueChanged<String?> onSelected,
  }) {
    return Autocomplete<Stop>(
      key: ValueKey('${selectedId ?? label}-${widget.isEnglish}'),
      initialValue: TextEditingValue(text: _stopLabel(selectedId ?? '')),
      displayStringForOption: (stop) =>
          stop.displayName(isEnglish: widget.isEnglish),
      optionsBuilder: (value) => _filterStops(value.text),
      onSelected: (stop) => onSelected(stop.stopId),
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 520),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final stop = options.elementAt(index);
                  return ListTile(
                    title: Text(stop.displayName(isEnglish: widget.isEnglish)),
                    subtitle: Text(stop.stopId),
                    onTap: () => onSelected(stop),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFareCard(BuildContext context) {
    if (!widget.hasSearched) return const SizedBox.shrink();
    final fromId = widget.fromStopId;
    final toId = widget.toStopId;
    if (fromId == null || toId == null) return const SizedBox.shrink();

    final fromLabel = _stopLabel(fromId);
    final toLabel = _stopLabel(toId);
    final estimatedFare = _estimatedFare;
    final autoDistanceKm = _estimateDistanceKm(fromId, toId);
    final autoFare = autoDistanceKm == null
        ? null
        : autoDistanceKm * AppConfig.fallbackRatePerKm;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fromLabel → $toLabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.isLoadingFare) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (widget.fareError != null) ...[
              Text(
                widget.fareError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ] else if (widget.fareQuote != null) ...[
              Text(
                'Government fare: ৳${widget.fareQuote!.fare.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Payable fare: ৳${_payableFare(widget.fareQuote!.fare).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.fareQuote!.routeNo != null &&
                  widget.fareQuote!.routeNo!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Route: ${widget.fareQuote!.routeNo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ] else ...[
              Text(
                'Government fare not found.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              if (autoFare != null) ...[
                Text(
                  'Estimated fare (approx): ৳${autoFare.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Payable fare: ৳${_payableFare(autoFare).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance: ${autoDistanceKm!.toStringAsFixed(2)} km · Rate ৳${AppConfig.fallbackRatePerKm}/km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                Text(
                  'Enter distance to estimate fare:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    hintText: 'e.g. 10.5',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                if (estimatedFare != null) ...[
                  Text(
                    'Estimated fare: ৳${estimatedFare.toStringAsFixed(0)}  (rate ৳${AppConfig.fallbackRatePerKm}/km)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payable fare: ৳${_payableFare(estimatedFare).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ] else
                  Text(
                    'Rate: ৳${AppConfig.fallbackRatePerKm} per km',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final isLoadingStops = widget.isLoadingStops;
    final stopsLoadError = widget.stopsLoadError;
    final error = stopsLoadError;

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
                              onPressed: isLoadingStops
                                  ? null
                                  : widget.onReloadStops,
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
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 20),
                        _buildStopAutocomplete(
                          label: 'From Stop',
                          selectedId: widget.fromStopId,
                          onSelected: widget.onFromChanged,
                        ),
                        const SizedBox(height: 12),
                        _buildStopAutocomplete(
                          label: 'To Stop',
                          selectedId: widget.toStopId,
                          onSelected: widget.onToChanged,
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _canSearch
                              ? () => widget.onSearch()
                              : null,
                          child: const Text('Search Route'),
                        ),
                        const SizedBox(height: 16),
                        _buildMiniMap(context),
                        const SizedBox(height: 16),
                        _buildFareCard(context),
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
                    _popularButton('mirpur10', 'farmgate'),
                    _popularButton('gulistan', 'jatrabari'),
                    _popularButton('mirpur12', 'paltan'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _popularButton(String fromId, String toId) {
    final enabled = !(widget.isLoadingStops || widget.stops.isEmpty);
    final label = '${_stopLabel(fromId)} → ${_stopLabel(toId)}';
    return FilledButton.tonal(
      onPressed: enabled
          ? () => widget.onApplyPopularRoute(fromId: fromId, toId: toId)
          : null,
      child: Text(label),
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
