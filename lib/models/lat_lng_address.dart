import 'package:taxi_app/models/geo_lat_lng.dart';

class LatLngAddress {
  const LatLngAddress({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;

  GeoLatLng get position => GeoLatLng(latitude, longitude);

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
      };

  static LatLngAddress? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final lat = (m['latitude'] as num?)?.toDouble();
    final lng = (m['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLngAddress(
      latitude: lat,
      longitude: lng,
      address: m['address'] as String?,
    );
  }

  static LatLngAddress? fromFirestore(dynamic v) {
    if (v is Map<String, dynamic>) return fromMap(v);
    if (v is Map) {
      return fromMap(Map<String, dynamic>.from(v));
    }
    return null;
  }
}
