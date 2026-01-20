class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.fromStopId,
    required this.toStopId,
    required this.searchedAt,
    this.id,
    this.fare,
    this.routeNo,
  });

  final int? id;
  final String fromStopId;
  final String toStopId;
  final double? fare;
  final String? routeNo;
  final DateTime searchedAt;

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    final fareValue = map['fare'];
    final double? fare = fareValue == null
        ? null
        : (fareValue is num
              ? fareValue.toDouble()
              : double.tryParse(fareValue.toString()));

    final searchedAtRaw = map['searched_at'];
    final DateTime searchedAt = searchedAtRaw is String
        ? DateTime.parse(searchedAtRaw)
        : (searchedAtRaw is DateTime ? searchedAtRaw : DateTime.now());

    return SearchHistoryEntry(
      id: map['id'] is int ? map['id'] as int : null,
      fromStopId: map['from_stop']?.toString() ?? '',
      toStopId: map['to_stop']?.toString() ?? '',
      fare: fare,
      routeNo: map['route_no']?.toString(),
      searchedAt: searchedAt,
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'from_stop': fromStopId,
      'to_stop': toStopId,
      'fare': fare,
      'route_no': routeNo,
      'searched_at': searchedAt.toIso8601String(),
    };
  }
}
