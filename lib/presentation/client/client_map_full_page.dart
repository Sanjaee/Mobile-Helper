import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/widgets/dynamic_map.dart';

class ClientMapFullPage extends StatefulWidget {
  const ClientMapFullPage({super.key});

  @override
  State<ClientMapFullPage> createState() => _ClientMapFullPageState();
}

class _ClientMapFullPageState extends State<ClientMapFullPage> {
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
    const center = LatLng(-6.200000, 106.816666);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('center'),
        position: center,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      // Dummy nearby service providers
      const Marker(
        markerId: MarkerId('sp1'),
        position: LatLng(-6.195, 106.812),
        infoWindow: InfoWindow(title: 'Service Provider A'),
      ),
      const Marker(
        markerId: MarkerId('sp2'),
        position: LatLng(-6.205, 106.820),
        infoWindow: InfoWindow(title: 'Service Provider B'),
      ),
      const Marker(
        markerId: MarkerId('sp3'),
        position: LatLng(-6.198, 106.825),
        infoWindow: InfoWindow(title: 'Service Provider C'),
      ),
      const Marker(
        markerId: MarkerId('sp4'),
        position: LatLng(-6.207, 106.810),
        infoWindow: InfoWindow(title: 'Service Provider D'),
      ),
      const Marker(
        markerId: MarkerId('sp5'),
        position: LatLng(-6.192, 106.818),
        infoWindow: InfoWindow(title: 'Service Provider E'),
      ),
      const Marker(
        markerId: MarkerId('sp6'),
        position: LatLng(-6.210, 106.822),
        infoWindow: InfoWindow(title: 'Service Provider F'),
      ),
      const Marker(
        markerId: MarkerId('sp7'),
        position: LatLng(-6.203, 106.815),
        infoWindow: InfoWindow(title: 'Service Provider G'),
      ),
      const Marker(
        markerId: MarkerId('sp8'),
        position: LatLng(-6.197, 106.807),
        infoWindow: InfoWindow(title: 'Service Provider H'),
      ),
      const Marker(
        markerId: MarkerId('sp9'),
        position: LatLng(-6.212, 106.816),
        infoWindow: InfoWindow(title: 'Service Provider I'),
      ),
      const Marker(
        markerId: MarkerId('sp10'),
        position: LatLng(-6.189, 106.823),
        infoWindow: InfoWindow(title: 'Service Provider J'),
      ),
    };
    final topInset = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DynamicMap(
              initialPosition: center,
              initialZoom: 13,
              markers: markers,
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
              heroTag: 'client-recenter',
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
                  heroTag: 'client-zoom-in',
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
                  heroTag: 'client-zoom-out',
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


