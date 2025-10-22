import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _setFullScreen();
  }

  @override
  void dispose() {
    _restoreSystemUI();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Full screen map
            Positioned.fill(
              child: DynamicMap(
                initialPosition: const LatLng(-6.914744, 107.609810),
                initialZoom: 13,
                onMapCreated: (c) => _controller = c,
                zoomControlsEnabled: false,
              ),
            ),
            
            // Back button with safe area
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
            
            // My location button
            Positioned(
              right: 12,
              bottom: 24,
              child: FloatingActionButton(
                heroTag: 'service-recenter',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _recenter,
                child: const Icon(Icons.my_location, color: Colors.black87),
              ),
            ),
            
            // Zoom controls
            Positioned(
              left: 12,
              bottom: 24,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'service-zoom-in',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      final c = _controller;
                      if (c == null) return;
                      await c.animateCamera(CameraUpdate.zoomIn());
                    },
                    child: const Icon(Icons.add, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'service-zoom-out',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      final c = _controller;
                      if (c == null) return;
                      await c.animateCamera(CameraUpdate.zoomOut());
                    },
                    child: const Icon(Icons.remove, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


