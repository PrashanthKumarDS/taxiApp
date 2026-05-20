import 'dart:async';

import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/core/services/places_service.dart';
import 'package:taxi_app/core/theme/app_theme.dart';
import 'package:taxi_app/models/geo_lat_lng.dart';
import 'package:taxi_app/models/lat_lng_address.dart';
import 'package:taxi_app/providers/map_provider.dart';

/// Full-screen place search with Google Places Autocomplete.
class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({
    super.key,
    required this.title,
    this.biasLocation,
  });

  final String title;
  final GeoLatLng? biasLocation;

  /// Opens the search screen and returns the selected [LatLngAddress] or null.
  static Future<LatLngAddress?> open(
    BuildContext context, {
    required String title,
    GeoLatLng? biasLocation,
  }) {
    return Navigator.of(context).push<LatLngAddress>(
      MaterialPageRoute(
        builder: (_) => LocationSearchScreen(
          title: title,
          biasLocation: biasLocation,
        ),
      ),
    );
  }

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlacePrediction> _predictions = [];
  bool _loading = false;
  bool _detailsLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.length < 2) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(text);
    });
  }

  Future<void> _search(String input) async {
    setState(() => _loading = true);
    try {
      final places = context.read<PlacesService>();
      final results = await places.autocomplete(
        input,
        location: widget.biasLocation,
      );
      if (!mounted) return;
      setState(() => _predictions = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() => _detailsLoading = true);
    try {
      final places = context.read<PlacesService>();
      final result = await places.getPlaceDetails(prediction.placeId);
      if (!mounted) return;
      if (result != null) {
        Navigator.of(context).pop(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get place details')),
        );
      }
    } finally {
      if (mounted) setState(() => _detailsLoading = false);
    }
  }

  void _useCurrentLocation() {
    final map = context.read<MapProvider>();
    final ll = map.currentLatLng;
    if (ll == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available yet')),
      );
      return;
    }
    Navigator.of(context).pop(
      LatLngAddress(
        latitude: ll.latitude,
        longitude: ll.longitude,
        address: 'Current location',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _predictions = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_loading || _detailsLoading)
            SizedBox(
              height: 60,
              child: DotLottieLoader.fromAsset(
                'assets/animations/car_loading.lottie',
                frameBuilder: (ctx, dotlottie) {
                  if (dotlottie != null) {
                    return Lottie.memory(
                      dotlottie.animations.values.single,
                      fit: BoxFit.contain,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          // Current location option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
              child: const Icon(Icons.my_location, color: AppTheme.accent),
            ),
            title: const Text('Use current location'),
            onTap: _detailsLoading ? null : _useCurrentLocation,
          ),
          const Divider(height: 1),
          // Search results
          Expanded(
            child: _predictions.isEmpty
                ? Center(
                    child: _controller.text.length >= 2
                        ? Text(
                            _loading ? '' : 'No results found',
                            style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5)),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 160,
                                width: 160,
                                child: DotLottieLoader.fromAsset(
                                  'assets/animations/car_loading.lottie',
                                  frameBuilder: (ctx, dotlottie) {
                                    if (dotlottie != null) {
                                      return Lottie.memory(
                                        dotlottie.animations.values.single,
                                        fit: BoxFit.contain,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Search for a place to get started',
                                style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                  )
                : ListView.separated(
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _predictions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(
                          p.mainText ?? p.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: p.secondaryText != null
                            ? Text(
                                p.secondaryText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5)),
                              )
                            : null,
                        enabled: !_detailsLoading,
                        onTap: () => _selectPrediction(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
