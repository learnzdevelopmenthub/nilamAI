/// One row from data.gov.in OGD AgMarknet daily-prices feed.
class MandiPrice {
  const MandiPrice({
    required this.commodity,
    required this.market,
    required this.district,
    required this.state,
    required this.variety,
    required this.modalPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.arrivalDate,
  });

  final String commodity;
  final String market;
  final String district;
  final String state;
  final String variety;
  final double modalPrice;
  final double minPrice;
  final double maxPrice;
  final String arrivalDate;

  factory MandiPrice.fromMap(Map<String, dynamic> m) => MandiPrice(
        commodity: (m['commodity'] as String?)?.trim() ?? '',
        market: (m['market'] as String?)?.trim() ?? '',
        district: (m['district'] as String?)?.trim() ?? '',
        state: (m['state'] as String?)?.trim() ?? '',
        variety: (m['variety'] as String?)?.trim() ?? '',
        modalPrice: _num(m['modal_price']),
        minPrice: _num(m['min_price']),
        maxPrice: _num(m['max_price']),
        arrivalDate: (m['arrival_date'] as String?)?.trim() ?? '',
      );

  static double _num(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
