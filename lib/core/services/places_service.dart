import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/core/constants/app_constants.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/lat_lng_address.dart';

/// A single autocomplete suggestion from Google Places.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
}

/// Calls Google Places Autocomplete + Place Details APIs.
class PlacesService {
  static const _baseUrl = 'maps.googleapis.com';

  /// Returns a list of place predictions for [input].
  /// Optionally biases results toward [location].
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    GeoLatLng? location,
  }) async {
    final key = AppConstants.googleMapsApiKey;
    if (key.isEmpty || input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input.trim(),
      'key': key,
      'components': 'country:in',
    };
    if (location != null) {
      params['location'] = '${location.latitude},${location.longitude}';
      params['radius'] = '50000'; // 50 km bias
    }

    final uri = Uri.https(_baseUrl, '/maps/api/place/autocomplete/json', params);

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final status = json['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('PlacesService autocomplete: $status');
        return [];
      }
      final predictions = json['predictions'] as List<dynamic>? ?? [];
      return predictions.map((p) {
        final m = p as Map<String, dynamic>;
        final structured =
            m['structured_formatting'] as Map<String, dynamic>? ?? {};
        return PlacePrediction(
          placeId: m['place_id'] as String? ?? '',
          description: m['description'] as String? ?? '',
          mainText: structured['main_text'] as String?,
          secondaryText: structured['secondary_text'] as String?,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('PlacesService autocomplete error: $e\n$st');
      return [];
    }
  }

  /// Resolves a [placeId] to coordinates + address.
  Future<LatLngAddress?> getPlaceDetails(String placeId) async {
    final key = AppConstants.googleMapsApiKey;
    if (key.isEmpty || placeId.isEmpty) return null;

    final uri = Uri.https(_baseUrl, '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry,formatted_address,name',
      'key': key,
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['status'] != 'OK') {
        debugPrint('PlacesService details: ${json['status']}');
        return null;
      }
      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final loc =
          result['geometry']?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final name = result['name'] as String?;
      final formatted = result['formatted_address'] as String?;
      final address = name != null && formatted != null
          ? '$name, $formatted'
          : formatted ?? name ?? '';
      return LatLngAddress(latitude: lat, longitude: lng, address: address);
    } catch (e, st) {
      debugPrint('PlacesService details error: $e\n$st');
      return null;
    }
  }
}
