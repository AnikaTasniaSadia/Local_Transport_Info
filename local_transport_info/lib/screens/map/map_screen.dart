import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../data/models/stop.dart';
import '../../services/app_config.dart';
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

  List<LatLng> _routePoints = const [];
  bool _loadingRoute = false;
  String? _routeError;

  LatLng? _lastCameraTarget;
  DateTime? _lastCameraUpdate;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromStopId != widget.fromStopId ||
        oldWidget.toStopId != widget.toStopId) {
      _fetchRoute();
    }
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
            _followUser();
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

  Future<void> _fetchRoute() async {
    final from = StopCoordinates.ofStop(widget.fromStopId);
    final to = StopCoordinates.ofStop(widget.toStopId);

    if (from == null || to == null) {
      setState(() {
        _routePoints = const [];
        _routeError = null;
        _loadingRoute = false;
      });
      return;
    }

    if (AppConfig.googleMapsApiKey.isEmpty) {
      setState(() {
        _routePoints = const [];
        _routeError = 'Missing GOOGLE_MAPS_API_KEY';
        _loadingRoute = false;
      });
      return;
    }

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
            'origin': '${from.latitude},${from.longitude}',
            'destination': '${to.latitude},${to.longitude}',
            'mode': 'driving',
            'key': AppConfig.googleMapsApiKey,
          });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Directions API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        final message = data['error_message'] as String?;
        throw Exception(
          'Directions API: $status${message == null ? '' : ' - $message'}',
        );
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) throw Exception('No route found');

      final polyline = routes.first['overview_polyline']['points'] as String;
      final points = _decodePolyline(polyline);

      if (!mounted) return;
      setState(() {
        _routePoints = points;
        _loadingRoute = false;
      });

      _fitToPoints([...points, if (_currentLatLng != null) _currentLatLng!]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.toString();
        _routePoints = const [];
        _loadingRoute = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  void _fitToPoints(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      minLat = (minLat == null)
          ? p.latitude
          : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null)
          ? p.latitude
          : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null)
          ? p.longitude
          : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null)
          ? p.longitude
          : (p.longitude > maxLng ? p.longitude : maxLng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  void _followUser() {
    if (_mapController == null || _currentLatLng == null) return;

    final now = DateTime.now();
    if (_lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!).inMilliseconds < 900) {
      return;
    }

    if (_lastCameraTarget != null) {
      final meters = Geolocator.distanceBetween(
        _lastCameraTarget!.latitude,
        _lastCameraTarget!.longitude,
        _currentLatLng!.latitude,
        _currentLatLng!.longitude,
      );
      if (meters < 8) return;
    }

    _lastCameraUpdate = now;
    _lastCameraTarget = _currentLatLng;
    _mapController!.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
  }

  double? _routeDistanceKm() {
    if (_routePoints.length < 2) return null;
    double meters = 0;
    for (var i = 1; i < _routePoints.length; i++) {
      final prev = _routePoints[i - 1];
      final curr = _routePoints[i];
      meters += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }
    return meters / 1000;
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

    if (_routePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          width: 8,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      );
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route-highlight'),
          points: _routePoints,
          width: 4,
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
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
        ),
      );
    }

    final initial = _currentLatLng ?? from ?? to ?? StopCoordinates.dhakaCenter;

    final routeDistanceKm = _routeDistanceKm();
    final fromLabel = _stopName(widget.fromStopId);
    final toLabel = _stopName(widget.toStopId);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 12),
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
          if (_loadingRoute)
            const Positioned(
              top: 12,
              right: 12,
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: DecoratedBox(
                key: ValueKey('${fromLabel.isNotEmpty}-${toLabel.isNotEmpty}'),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (fromLabel.isEmpty || toLabel.isEmpty)
                                  ? 'Select From/To stops'
                                  : '$fromLabel → $toLabel',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loadingRoute
                                  ? 'Fetching fastest route…'
                                  : _routeError != null
                                  ? 'Route unavailable'
                                  : routeDistanceKm == null
                                  ? 'No route loaded'
                                  : 'Approx. ${routeDistanceKm.toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (routeDistanceKm != null && _routeError == null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${routeDistanceKm.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      else if (_routeError != null)
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                    ],
                  ),
                ),
              ),
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
