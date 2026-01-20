import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/stop.dart';
import '../data/models/fare_quote.dart';
import '../data/models/route_info.dart';
import '../data/models/search_history.dart';

/// Single place for all Supabase database operations.
class SupabaseService {
  SupabaseService({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  // Table names. Keep compatible with existing SQL seed.
  static const String _stopsTable = 'stops';
  static const String _routesTable = 'routes';

  /// The project requirement calls it `fares`, but older code/seed used `fare`.
  ///
  /// We write to `fares` by default and fallback to `fare` for reads/writes
  /// if `fares` fails.
  static const String _faresTable = 'fares';
  static const String _fareLegacyTable = 'fare';

  static const String _adminsTable = 'admins';
  static const String _historyTable = 'search_history';

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> logSearchHistory(SearchHistoryEntry entry) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _client.from(_historyTable).insert(entry.toInsertMap(user.id));
    } on PostgrestException catch (e) {
      throw Exception('Failed to save history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save history: $e');
    }
  }

  Future<List<SearchHistoryEntry>> fetchSearchHistory() async {
    final user = currentUser;
    if (user == null) return const [];

    try {
      final response = await _client
          .from(_historyTable)
          .select('id, from_stop, to_stop, fare, route_no, searched_at')
          .eq('user_id', user.id)
          .order('searched_at', ascending: false)
          .limit(200);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(SearchHistoryEntry.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load history: $e');
    }
  }

  /// Returns true if the current user is listed in the `admins` table.
  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    final email = user.email;
    final filters = <String>['user_id.eq.${user.id}'];
    if (email != null && email.isNotEmpty) {
      filters.add('email.eq.$email');
    }

    try {
      final response = await _client
          .from(_adminsTable)
          .select('id')
          .or(filters.join(','))
          .limit(1);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Admin check failed: ${e.message}');
    } catch (e) {
      throw Exception('Admin check failed: $e');
    }
  }

  Future<List<Stop>> fetchStops() async {
    try {
      final response = await _client
          .from(_stopsTable)
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

  Future<List<RouteInfo>> fetchRoutes() async {
    try {
      final response = await _client
          .from(_routesTable)
          .select('route_id, route_no, name_bn, name_en, total_km, rate_per_km')
          .order('route_no');

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map(RouteInfo.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load routes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load routes: $e');
    }
  }

  /// Returns government fare if it exists.
  Future<FareQuote?> fetchFareQuote({
    required String fromStopId,
    required String toStopId,
  }) async {
    try {
      Future<Map<String, dynamic>?> fetchRow({
        required String table,
        required String from,
        required String to,
      }) async {
        final response = await _client
            .from(table)
            .select('fare, route_id')
            .eq('from_stop', from)
            .eq('to_stop', to)
            .limit(1);

        final rows = (response as List).cast<Map<String, dynamic>>();
        if (rows.isEmpty) return null;
        return rows.first;
      }

      Future<Map<String, dynamic>?> tryBothTables({
        required String from,
        required String to,
      }) async {
        try {
          final row = await fetchRow(table: _faresTable, from: from, to: to);
          if (row != null) return row;
        } on PostgrestException {
          // Fall back to legacy table.
        }

        return fetchRow(table: _fareLegacyTable, from: from, to: to);
      }

      // Exact direction first; then swapped.
      final fareRow =
          await tryBothTables(from: fromStopId, to: toStopId) ??
          await tryBothTables(from: toStopId, to: fromStopId);
      if (fareRow == null) return null;

      final fareValue = fareRow['fare'];
      final double fare = fareValue is num
          ? fareValue.toDouble()
          : double.parse(fareValue.toString());

      String? routeNo;
      final routeId = fareRow['route_id'];
      if (routeId != null) {
        final routesResponse = await _client
            .from(_routesTable)
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

  /// Upserts a single fare row.
  Future<void> upsertFare({
    required String routeId,
    required String fromStopId,
    required String toStopId,
    required double fare,
  }) async {
    final payload = {
      'route_id': routeId,
      'from_stop': fromStopId,
      'to_stop': toStopId,
      'fare': fare,
    };

    try {
      await _client
          .from(_faresTable)
          .upsert(payload, onConflict: 'route_id,from_stop,to_stop');
    } on PostgrestException catch (_) {
      // Fallback for projects still using `fare`.
      await _client
          .from(_fareLegacyTable)
          .upsert(payload, onConflict: 'route_id,from_stop,to_stop');
    }
  }

  /// Import data from JSON and upsert it.
  ///
  /// Supported formats:
  ///
  /// 1) Object with a top-level `fares` array:
  /// `{ "fares": [ {"route_id":"a101","from_stop":"kalshi","to_stop":"mirpur12","fare":10} ] }`
  ///
  /// 2) A raw array of fare rows:
  /// `[ {"route_id":"a101","from_stop":"kalshi","to_stop":"mirpur12","fare":10} ]`
  ///
  /// Returns count of upserted fare rows.
  Future<int> importFaresFromJsonString(String jsonString) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Invalid JSON: $e');
    }

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['fares'] is List) {
      list = (decoded['fares'] as List);
    } else {
      throw Exception(
        'JSON must be a list or an object containing a "fares" list.',
      );
    }

    final rows = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;

      final map = item.cast<String, dynamic>();
      final routeId = map['route_id']?.toString() ?? '';
      final fromStop = map['from_stop']?.toString() ?? '';
      final toStop = map['to_stop']?.toString() ?? '';
      final fareRaw = map['fare'];
      final fareValue = fareRaw is num
          ? fareRaw.toDouble()
          : double.tryParse(fareRaw?.toString() ?? '');

      if (routeId.isEmpty || fromStop.isEmpty || toStop.isEmpty) continue;
      if (fareValue == null) continue;

      rows.add({
        'route_id': routeId,
        'from_stop': fromStop,
        'to_stop': toStop,
        'fare': fareValue,
      });
    }

    if (rows.isEmpty) return 0;

    try {
      await _client
          .from(_faresTable)
          .upsert(rows, onConflict: 'route_id,from_stop,to_stop');
      return rows.length;
    } on PostgrestException catch (_) {
      await _client
          .from(_fareLegacyTable)
          .upsert(rows, onConflict: 'route_id,from_stop,to_stop');
      return rows.length;
    }
  }
}
