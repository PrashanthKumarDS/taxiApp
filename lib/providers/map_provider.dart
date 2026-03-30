import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/services/directions_service.dart';
import 'package:taxi_app/core/services/location_service.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/lat_lng_address.dart';

class MapProvider extends ChangeNotifier {
  MapProvider(this._location, this._directions);

  final LocationService _location;
  final DirectionsService _directions;

  GeoLatLng? _current;
  LatLngAddress? _pickup;
  LatLngAddress? _drop;
  List<GeoLatLng> _routePoints = [];
  int _distanceMeters = 0;
  int _durationSeconds = 0;
  bool _routeLoading = false;
  String? _encodedPolyline;

  GeoLatLng? get currentLatLng => _current;
  LatLngAddress? get pickup => _pickup;
  LatLngAddress? get drop => _drop;
  List<GeoLatLng> get routePoints => List.unmodifiable(_routePoints);
  int get distanceMeters => _distanceMeters;
  int get durationSeconds => _durationSeconds;
  bool get routeLoading => _routeLoading;
  String? get encodedPolyline => _encodedPolyline;

  Future<void> refreshMyLocation() async {
    final ll = await _location.getCurrentLatLng();
    _current = ll;
    notifyListeners();
  }

  void setPickup(LatLngAddress? v) {
    _pickup = v;
    notifyListeners();
  }

  void setDrop(LatLngAddress? v) {
    _drop = v;
    notifyListeners();
  }

  Future<void> fetchRoute() async {
    final a = _pickup?.position;
    final b = _drop?.position;
    if (a == null || b == null) {
      _routePoints = [];
      _distanceMeters = 0;
      _durationSeconds = 0;
      _encodedPolyline = null;
      notifyListeners();
      return;
    }
    _routeLoading = true;
    notifyListeners();
    try {
      final r = await _directions.fetchRoute(origin: a, destination: b);
      if (r != null) {
        _routePoints = r.points;
        _distanceMeters = r.distanceMeters;
        _durationSeconds = r.durationSeconds;
        _encodedPolyline = r.encodedPolyline;
      } else {
        _routePoints = [a, b];
        _distanceMeters = DirectionsService.haversineMeters(a, b);
        _durationSeconds = 0;
      }
    } finally {
      _routeLoading = false;
      notifyListeners();
    }
  }

  void clearTripSelection() {
    _pickup = null;
    _drop = null;
    _routePoints = [];
    _distanceMeters = 0;
    _durationSeconds = 0;
    _encodedPolyline = null;
    notifyListeners();
  }
}
