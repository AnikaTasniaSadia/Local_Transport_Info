import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/stop.dart';
import 'stop_coordinates.dart';

class MapScreen extends StatefulWidget {
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
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      await _requestLocationPermission();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      _setCurrentLatLng(position);

      _positionSub?.cancel();
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            if (!mounted) return;
            _setCurrentLatLng(position);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentLatLng!),
            );
          });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }
  }

  void _setCurrentLatLng(Position position) {
    setState(() {
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final from = StopCoordinates.ofStop(widget.fromStopId);
    final to = StopCoordinates.ofStop(widget.toStopId);

    final LatLng? targetStop = to ?? from;

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

    if (_currentLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _currentLatLng!,
          infoWindow: const InfoWindow(title: 'Your location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
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

    if (_currentLatLng != null && targetStop != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('user-to-stop'),
          points: [_currentLatLng!, targetStop],
          width: 4,
          color: Theme.of(context).colorScheme.secondary,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      );
    }

    final initial = _currentLatLng ?? from ?? to ?? StopCoordinates.dhakaCenter;

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initial, zoom: 12),
        onMapCreated: (controller) => _mapController = controller,
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
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
