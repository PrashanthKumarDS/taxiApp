/// Map-agnostic latitude/longitude (no Google Maps SDK dependency).
class GeoLatLng {
  const GeoLatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
