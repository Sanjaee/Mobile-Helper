import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/location_service.dart';
import 'arrived_page.dart';

class ProviderOnTheWayPage extends StatefulWidget {
  final String orderId;

  const ProviderOnTheWayPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ProviderOnTheWayPage> createState() => _ProviderOnTheWayPageState();
}

class _ProviderOnTheWayPageState extends State<ProviderOnTheWayPage> {
  final OrderService _orderService = OrderService();
  final LocationService _locationService = LocationService();
  Timer? _timer;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _location;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startLocationPolling();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });

      // Check if provider has arrived
      if (order['status'] == 'ARRIVED') {
        _navigateToArrivedPage();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
        );
      }
    }
  }

  Future<void> _loadLocation() async {
    try {
      final location = await _locationService.getOrderLocation(widget.orderId);
      setState(() {
        _location = location;
        _updateMarkers();
      });
    } catch (e) {
      // Location might not be available yet
    }
  }

  void _updateMarkers() {
    if (_order != null && _location != null) {
      setState(() {
        _markers = {
          // Client location
          Marker(
            markerId: const MarkerId('client_location'),
            position: LatLng(
              _order!['service_latitude'],
              _order!['service_longitude'],
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
          // Provider location
          Marker(
            markerId: const MarkerId('provider_location'),
            position: LatLng(
              _location!['latitude'],
              _location!['longitude'],
            ),
            infoWindow: const InfoWindow(title: 'Provider Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        };
      });
    }
  }

  void _startLocationPolling() {
    _loadLocation();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadOrder();
      _loadLocation();
    });
  }

  void _navigateToArrivedPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ArrivedPage(orderId: widget.orderId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider On The Way'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : Column(
                  children: [
                    // Map
                    Expanded(
                      flex: 2,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _order!['service_latitude'],
                            _order!['service_longitude'],
                          ),
                          zoom: 15,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        markers: _markers,
                      ),
                    ),

                    // Status info
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Provider is on the way!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Order #${_order!['order_number']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location info
                          if (_location != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoCard(
                                  'Distance',
                                  '${_location!['distance_km']?.toStringAsFixed(1) ?? 'N/A'} km',
                                  Icons.straighten,
                                ),
                                _buildInfoCard(
                                  'ETA',
                                  '${_location!['estimated_arrival_minutes'] ?? 'N/A'} min',
                                  Icons.access_time,
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Order details
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_order!['description']),
                                  const SizedBox(height: 4),
                                  Text(
                                    _order!['service_address'],
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
