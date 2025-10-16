import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/widgets/dynamic_map.dart';

class ServiceMapFullPage extends StatefulWidget {
  const ServiceMapFullPage({super.key});

  @override
  State<ServiceMapFullPage> createState() => _ServiceMapFullPageState();
}

class _ServiceMapFullPageState extends State<ServiceMapFullPage> {
  GoogleMapController? _controller;

  Future<void> _recenter() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission || _controller == null) return;
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final target = LatLng(position.latitude, position.longitude);
    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DynamicMap(
              initialPosition: const LatLng(-6.914744, 107.609810),
              initialZoom: 13,
              onMapCreated: (c) => _controller = c,
              zoomControlsEnabled: false,
            ),
          ),
          Positioned(
            top: topInset + 12,
            left: 12,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'service-recenter',
              mini: true,
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 24,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'service-zoom-in',
                  mini: true,
                  onPressed: () async {
                    final c = _controller;
                    if (c == null) return;
                    await c.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'service-zoom-out',
                  mini: true,
                  onPressed: () async {
                    final c = _controller;
                    if (c == null) return;
                    await c.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


