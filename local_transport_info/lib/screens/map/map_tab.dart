import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/stop.dart';
import 'stop_coordinates.dart';

class MapTab extends StatefulWidget {
  const MapTab({
    super.key,
    required this.stops,
    required this.isEnglish,
    required this.fromStopId,
    required this.toStopId,
  });

  final List<Stop> stops;
  final bool isEnglish;
  final String? fromStopId;
  final String? toStopId;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = StopCoordinates.ofStop(widget.fromStopId);
    final to = StopCoordinates.ofStop(widget.toStopId);

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    if (from != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: from,
          infoWindow: InfoWindow(title: _stopName(widget.fromStopId)),
        ),
      );
    }

    if (to != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: to,
          infoWindow: InfoWindow(title: _stopName(widget.toStopId)),
        ),
      );
    }

    if (from != null && to != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [from, to],
          width: 5,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    final initial = from ?? to ?? StopCoordinates.dhakaCenter;

    return SafeArea(
      child: Column(
        children: [
          if (from == null || to == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select From and To stops on Home to show them on the map.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: initial, zoom: 12),
              onMapCreated: (c) => _controller = c,
              markers: markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ],
      ),
    );
  }

  String _stopName(String? stopId) {
    if (stopId == null) return '';
    final stop = widget.stops.where((s) => s.stopId == stopId).firstOrNull;
    return stop?.displayName(isEnglish: widget.isEnglish) ?? stopId;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
