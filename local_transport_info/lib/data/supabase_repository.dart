import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/stop.dart';
import 'models/fare_quote.dart';

class SupabaseRepository {
  SupabaseRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  Future<List<Stop>> fetchStops() async {
    try {
      final response = await _client
          .from('stops')
          .select('stop_id, name_bn, name_en')
          .order('name_en');

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(Stop.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load stops: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load stops: $e');
    }
  }

  /// Returns a government fare for a stop-to-stop query if it exists.
  ///
  /// If no row exists in `fare`, returns null.
  Future<FareQuote?> fetchFareQuote({
    required String fromStopId,
    required String toStopId,
  }) async {
    try {
      // Step 1: fetch the fare row.
      Future<Map<String, dynamic>?> fetchRow({
        required String from,
        required String to,
      }) async {
        final response = await _client
            .from('fare')
            .select('fare, route_id')
            .eq('from_stop', from)
            .eq('to_stop', to)
            .limit(1);

        final rows = (response as List).cast<Map<String, dynamic>>();
        if (rows.isEmpty) return null;
        return rows.first;
      }

      // Try exact direction first; then fallback to swapped direction.
      final fareRow =
          await fetchRow(from: fromStopId, to: toStopId) ??
          await fetchRow(from: toStopId, to: fromStopId);
      if (fareRow == null) return null;

      final fareValue = fareRow['fare'];
      final double fare = fareValue is num
          ? fareValue.toDouble()
          : double.parse(fareValue.toString());

      // Step 2: route number (optional).
      String? routeNo;
      final routeId = fareRow['route_id'];
      if (routeId != null) {
        final routesResponse = await _client
            .from('routes')
            .select('route_no')
            .eq('route_id', routeId)
            .limit(1);

        final routeRows = (routesResponse as List).cast<Map<String, dynamic>>();
        if (routeRows.isNotEmpty) {
          routeNo = routeRows.first['route_no']?.toString();
        }
      }

      return FareQuote(fare: fare, routeNo: routeNo);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load fare: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load fare: $e');
    }
  }
}
