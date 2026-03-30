import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/core/constants/app_constants.dart';
import 'package:taxi_app/models/lat_lng_address.dart';

/// Resolves place names (e.g. "Udupi", "Mangaluru, Karnataka") to coordinates.
///
/// Uses [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding)
/// when `GOOGLE_MAPS_API_KEY` is set; otherwise [Nominatim](https://nominatim.org/)
/// (OpenStreetMap) with India bias — fine for dev/MVP; respect OSM usage policy for production load.
class GeocodingService {
  /// Identifies the app to Nominatim (required by their terms).
  static const _nominatimUserAgent = 'TaxiApp/1.0';

  Future<LatLngAddress?> resolvePlace(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.isEmpty) return null;

    final key = AppConstants.googleMapsApiKey;
    if (key.isNotEmpty) {
      return _googleGeocode(q, key);
    }
    return _nominatim(q);
  }

  Future<LatLngAddress?> _googleGeocode(String q, String key) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': q,
        'components': 'country:IN',
        'key': key,
      },
    );
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') {
        debugPrint('GeocodingService Google: ${json['status']}');
        return null;
      }
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final loc = first['geometry']?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final name = first['formatted_address'] as String? ?? q;
      return LatLngAddress(latitude: lat, longitude: lng, address: name);
    } catch (e, st) {
      debugPrint('GeocodingService Google error: $e\n$st');
      return null;
    }
  }

  Future<LatLngAddress?> _nominatim(String q) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': q,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'in',
      },
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': _nominatimUserAgent},
      );
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse('${first['lat']}');
      final lng = double.tryParse('${first['lon']}');
      if (lat == null || lng == null) return null;
      final name = first['display_name'] as String? ?? q;
      return LatLngAddress(latitude: lat, longitude: lng, address: name);
    } catch (e, st) {
      debugPrint('GeocodingService Nominatim error: $e\n$st');
      return null;
    }
  }
}
