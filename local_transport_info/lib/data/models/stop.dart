class Stop {
  const Stop({
    required this.stopId,
    required this.nameBn,
    required this.nameEn,
  });

  final String stopId;
  final String nameBn;
  final String nameEn;

  factory Stop.fromMap(Map<String, dynamic> map) {
    final rawId = map['stop_id'];
    final String stopId = rawId?.toString() ?? '';

    return Stop(
      stopId: stopId,
      nameBn: (map['name_bn'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
    );
  }

  String displayName({required bool isEnglish}) {
    if (isEnglish) {
      return nameEn.isNotEmpty ? nameEn : nameBn;
    }

    return nameBn.isNotEmpty ? nameBn : nameEn;
  }
}
