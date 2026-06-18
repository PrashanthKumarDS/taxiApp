class TourPackage {
  const TourPackage({
    required this.id,
    required this.title,
    required this.startingPoint,
    required this.duration,
    required this.sedanMiniPrice,
    required this.suvPrice,
    this.places = const [],
    this.image,
    this.isActive = true,
  });

  /// Document id within the starting-point subcollection.
  final String id;

  final String title;

  /// e.g. "Murudeshwar" — also the parent document id in `tour_packages`.
  final String startingPoint;

  /// e.g. "1 Day".
  final String duration;

  /// Fixed package price for Sedan / Mini, in ₹.
  final double sedanMiniPrice;

  /// Fixed package price for SUV, in ₹.
  final double suvPrice;

  /// Places covered on the tour.
  final List<String> places;

  /// Optional cover image URL.
  final String? image;

  final bool isActive;

  static TourPackage? fromSnapshot(String id, Map<String, dynamic> data) {
    final title = data['title'] as String?;
    if (title == null || title.isEmpty) return null;
    final pricing = Map<String, dynamic>.from(
      data['pricing'] as Map? ?? const {},
    );
    return TourPackage(
      id: (data['id'] as String?)?.isNotEmpty == true
          ? data['id'] as String
          : id,
      title: title,
      startingPoint: data['startingPoint'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      sedanMiniPrice: (pricing['sedanMini'] as num?)?.toDouble() ?? 0,
      suvPrice: (pricing['suv'] as num?)?.toDouble() ?? 0,
      places: (data['places'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      image: data['image'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
