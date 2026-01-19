import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/stop.dart';
import 'stop_coordinates.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
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
  Widget build(BuildContext context) {
    final from = StopCoordinates.ofStop(fromStopId);
    final to = StopCoordinates.ofStop(toStopId);

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    if (from != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: from,
          infoWindow: InfoWindow(title: _stopName(fromStopId)),
        ),
      );
    }

    if (to != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: to,
          infoWindow: InfoWindow(title: _stopName(toStopId)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initial, zoom: 12),
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  String _stopName(String? stopId) {
    if (stopId == null) return '';
    final stop = stops.where((s) => s.stopId == stopId).firstOrNull;
    return stop?.displayName(isEnglish: isEnglish) ?? stopId;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
