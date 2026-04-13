import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TaxiGoogleMap extends StatelessWidget {
  const TaxiGoogleMap({
    super.key,
    required this.initialTarget,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final LatLng initialTarget;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final void Function(GoogleMapController c) onMapCreated;
  final void Function(LatLng)? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      markers: markers,
      polylines: polylines,
      padding: padding,
      onMapCreated: onMapCreated,
      onTap: onTap,
      style: _darkMapStyle,
    );
  }
}

/// Simplified dark styling (subset) for readability.
const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
]
''';
