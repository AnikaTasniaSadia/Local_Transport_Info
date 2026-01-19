class FareQuote {
  const FareQuote({required this.fare, this.routeNo});

  /// Government-approved fare in BDT.
  final double fare;

  /// Route number if available.
  final String? routeNo;
}
