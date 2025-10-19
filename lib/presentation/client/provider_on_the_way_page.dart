import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/order_state_service.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/utils/jwt_utils.dart';
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
  final OrderStateService _orderStateService = OrderStateService();
  Timer? _timer;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _location;
  Map<String, dynamic>? _providerLocation;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

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

      // Save active order state
      await _orderStateService.saveActiveOrder(
        orderId: widget.orderId,
        status: order['status'],
        userRole: 'client',
      );

      // Check if provider has arrived
      if (order['status'] == 'ARRIVED') {
        _navigateToArrivedPage();
      }
      
      // Check if order is cancelled
      if (order['status'] == 'CANCELLED') {
        _handleOrderCancelled(order);
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
    if (_order != null) {
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
        };
        
        _polylines = {};
        
        // Add provider location and polyline if available
        if (_providerLocation != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('provider_location'),
              position: LatLng(
                _providerLocation!['latitude'],
                _providerLocation!['longitude'],
              ),
              infoWindow: const InfoWindow(title: 'Provider Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
          
          // Add polyline from provider to client
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(
                  _providerLocation!['latitude'],
                  _providerLocation!['longitude'],
                ),
                LatLng(
                  _order!['service_latitude'],
                  _order!['service_longitude'],
                ),
              ],
              color: Colors.blue,
              width: 4,
              patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            ),
          );
        }
      });
    }
  }

  void _startLocationPolling() {
    _loadLocation();
    _loadProviderLocation();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadOrder();
      _loadLocation();
      _loadProviderLocation();
    });
  }

  Future<void> _loadProviderLocation() async {
    try {
      final location = await _locationService.getProviderLocation(widget.orderId);
      setState(() {
        _providerLocation = location;
      });
      _updateMarkers();
    } catch (e) {
      // Provider location might not be available yet
      print('Provider location not available: $e');
    }
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

  void _handleOrderCancelled(Map<String, dynamic> order) async {
    if (mounted) {
      // Cancel polling timer
      _timer?.cancel();
      
      // Clear active order state
      await _orderStateService.clearActiveOrder();
      
      // Show cancellation popup
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Cancelled'),
          content: Text(
            order['cancellation_reason'] ?? 'This order has been cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/client-home', 
                  (route) => false
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exit Order'),
        content: const Text('You cannot exit while the provider is on the way. You can only cancel the order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder();
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancelOrder();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelOrder() async {
    try {
      // Get current user ID from JWT token
      final token = await StorageHelper.getAccessToken();
      if (token == null) {
        throw Exception('No access token found');
      }
      
      final userId = JwtUtils.getUserIdFromToken(token);
      if (userId == null) {
        throw Exception('Could not extract user ID from token');
      }
      
      await _orderService.cancelOrder(
        orderId: widget.orderId,
        cancelledBy: userId,
        reason: "Cancelled by client",
      );

      if (mounted) {
        // Cancel polling timer
        _timer?.cancel();
        
        // Clear active order state
        await _orderStateService.clearActiveOrder();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/client-home', 
            (route) => false
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return PopScope(
      canPop: false, // Prevent back button navigation
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Show dialog when user tries to go back
        _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider On The Way'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Remove back button
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
                        polylines: _polylines,
                      ),
                    ),

                    // Minimal status info
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Status indicator
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  size: 24,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Provider is on the way',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Order #${_order!['order_number']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ETA info
                              if (_location != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_location!['estimated_arrival_minutes'] ?? 'N/A'} min',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Cancel button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _cancelOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cancel Order',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
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
