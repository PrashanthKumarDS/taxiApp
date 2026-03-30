import 'package:flutter/foundation.dart';
import 'package:taxi_app/models/vehicle_type.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleType _selected = VehicleType.mini;

  VehicleType get selected => _selected;

  void select(VehicleType type) {
    if (_selected == type) return;
    _selected = type;
    notifyListeners();
  }

  /// Uses route distance/duration from [MapProvider].
  double estimatePrice({
    required int distanceMeters,
    required int durationSeconds,
  }) {
    final km = distanceMeters > 0 ? distanceMeters / 1000.0 : 2.0;
    final min = durationSeconds > 0 ? durationSeconds / 60.0 : 8.0;
    final v = _selected;
    final raw = v.baseFare + km * v.perKm + min * v.perMinute;
    return (raw * v.multiplier).clamp(25.0, 99999.0);
  }
}
