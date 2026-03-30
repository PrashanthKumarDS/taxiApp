import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/core/constants/app_constants.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.encodedPolyline,
  });

  final List<GeoLatLng> points;
  final int distanceMeters;
  final int durationSeconds;
  final String? encodedPolyline;
}

class DirectionsService {
  static int haversineMeters(GeoLatLng a, GeoLatLng b) {
    const earthM = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final lat1 = rad(a.latitude);
    final lat2 = rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.asin(math.min(1.0, math.sqrt(h)));
    return (earthM * c).round();
  }

  Future<RouteResult?> fetchRoute({
    required GeoLatLng origin,
    required GeoLatLng destination,
  }) async {
    final key = AppConstants.googleMapsApiKey;
    if (key.isEmpty) {
      debugPrint('DirectionsService: missing GOOGLE_MAPS_API_KEY');
      return _fallbackStraightLine(origin, destination);
    }
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'key': key,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['status'] != 'OK') return null;
    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;
    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>?;
    if (legs == null || legs.isEmpty) return null;
    int distance = 0;
    int duration = 0;
    for (final leg in legs) {
      final m = leg as Map<String, dynamic>;
      distance += (m['distance']?['value'] as num?)?.toInt() ?? 0;
      duration += (m['duration']?['value'] as num?)?.toInt() ?? 0;
    }
    final overview = route['overview_polyline']?['points'] as String?;
    List<GeoLatLng> points = [];
    if (overview != null && overview.isNotEmpty) {
      final decoded = PolylinePoints().decodePolyline(overview);
      points = decoded
          .map((p) => GeoLatLng(p.latitude, p.longitude))
          .toList(growable: false);
    }
    if (points.isEmpty) {
      return _fallbackStraightLine(origin, destination);
    }
    return RouteResult(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      encodedPolyline: overview,
    );
  }

  RouteResult _fallbackStraightLine(GeoLatLng a, GeoLatLng b) {
    final m = haversineMeters(a, b);
    const avgKmh = 30.0;
    final sec = m <= 0 ? 0 : ((m / 1000) / avgKmh * 3600).round();
    return RouteResult(
      points: [a, b],
      distanceMeters: m,
      durationSeconds: sec.clamp(60, 86400),
      encodedPolyline: null,
    );
  }
}
