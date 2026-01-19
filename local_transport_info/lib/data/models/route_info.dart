class RouteInfo {
  const RouteInfo({
    required this.routeId,
    required this.routeNo,
    required this.nameBn,
    required this.nameEn,
    this.totalKm,
    this.ratePerKm,
  });

  final String routeId;
  final String routeNo;
  final String nameBn;
  final String nameEn;
  final double? totalKm;
  final double? ratePerKm;

  factory RouteInfo.fromMap(Map<String, dynamic> map) {
    final dynamic totalKmRaw = map['total_km'];
    final dynamic rateRaw = map['rate_per_km'];

    double? parseNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return RouteInfo(
      routeId: map['route_id']?.toString() ?? '',
      routeNo: map['route_no']?.toString() ?? '',
      nameBn: (map['name_bn'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      totalKm: parseNum(totalKmRaw),
      ratePerKm: parseNum(rateRaw),
    );
  }

  String displayName({required bool isEnglish}) {
    if (isEnglish) {
      if (routeNo.trim().isNotEmpty && nameEn.trim().isNotEmpty) {
        return '$routeNo · $nameEn';
      }
      return routeNo.trim().isNotEmpty ? routeNo : nameEn;
    }

    if (routeNo.trim().isNotEmpty && nameBn.trim().isNotEmpty) {
      return '$routeNo · $nameBn';
    }
    return routeNo.trim().isNotEmpty ? routeNo : nameBn;
  }
}
