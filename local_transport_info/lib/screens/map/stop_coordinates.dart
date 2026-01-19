import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Static coordinates for stops.
///
/// Update these with real coordinates later (or store them in Supabase).
class StopCoordinates {
  static const LatLng dhakaCenter = LatLng(23.8103, 90.4125);

  static const Map<String, LatLng> byStopId = {
    'kalshi': LatLng(23.8239, 90.4039),
    'mirpur12': LatLng(23.8247, 90.3654),
    'mirpur10': LatLng(23.8079, 90.3686),
    'kazipara': LatLng(23.7987, 90.3735),
    'shewrapara': LatLng(23.7909, 90.3758),
    'farmgate': LatLng(23.7589, 90.3894),
    'shahbag': LatLng(23.7385, 90.3953),
    'paltan': LatLng(23.7333, 90.4140),
    'gulistan': LatLng(23.7286, 90.4104),
    'tiktuli': LatLng(23.7188, 90.4250),
    'saydabad': LatLng(23.7099, 90.4306),
    'jatrabari': LatLng(23.7101, 90.4493),
    'signboard': LatLng(23.7009, 90.4738),
    'kanchpur': LatLng(23.7035, 90.5020),
  };

  static LatLng? ofStop(String? stopId) {
    if (stopId == null) return null;
    return byStopId[stopId];
  }
}
