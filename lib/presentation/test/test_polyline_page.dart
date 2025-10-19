import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/google_directions_service.dart';

class TestPolylinePage extends StatefulWidget {
  const TestPolylinePage({Key? key}) : super(key: key);

  @override
  State<TestPolylinePage> createState() => _TestPolylinePageState();
}

class _TestPolylinePageState extends State<TestPolylinePage> {
  final GoogleDirectionsService directionsService = GoogleDirectionsService();
  GoogleMapController? mapController;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getPolyline();
  }

  Future<void> _getPolyline() async {
    final points = await directionsService.getPolylinePoints(
      -6.200000, 106.816666, // Jakarta
      -6.917464, 107.619125, // Bandung
    );

    final polylineCoordinates =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        color: const Color(0xFF00BFA5), // Gojek green
        width: 6,
        points: polylineCoordinates,
        jointType: JointType.round,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        patterns: [PatternItem.dash(30), PatternItem.gap(15)],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Polyline - Jakarta to Bandung'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        polylines: _polylines,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-6.5, 107.2), // Center between Jakarta and Bandung
          zoom: 8,
        ),
        markers: {
          const Marker(
            markerId: MarkerId('start'),
            position: LatLng(-6.200000, 106.816666),
            infoWindow: InfoWindow(title: 'Jakarta'),
          ),
          const Marker(
            markerId: MarkerId('end'),
            position: LatLng(-6.917464, 107.619125),
            infoWindow: InfoWindow(title: 'Bandung'),
          ),
        },
      ),
    );
  }
}
