import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_state_service.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/utils/jwt_utils.dart';
import 'arrived_page.dart';

class NavigationPage extends StatefulWidget {
  final String orderId;

  const NavigationPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final OrderService _orderService = OrderService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final OrderStateService _orderStateService = OrderStateService();
  Timer? _locationTimer;
  Timer? _orderStatusTimer;
  GoogleMapController? _mapController;
  Map<String, dynamic>? _order;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _getCurrentLocation();
    _startLocationTracking();
    _startOrderStatusPolling();
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
        userRole: 'provider',
      );

      // Check if order is completed
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

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentPosition != null) {
        await _updateLocation();
      }
    });
  }

  void _startOrderStatusPolling() {
    _orderStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadOrder();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final user = await _authService.getUserProfile();

      await _locationService.updateLocation(
        orderId: widget.orderId,
        serviceProviderId: user.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        speedKmh: _currentPosition!.speed,
        accuracyMeters: _currentPosition!.accuracy.round(),
        headingDegrees: _currentPosition!.heading.round(),
      );
    } catch (e) {
      // Log error but don't show to user
      print('Error updating location: $e');
    }
  }

  Future<void> _startJourney() async {
    try {
      final user = await _authService.getUserProfile();

      await _orderService.updateOrderOnTheWay(
        orderId: widget.orderId,
        providerId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journey started!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting journey: $e')),
        );
      }
    }
  }

  void _navigateToArrivedPage() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceArrivedPage(orderId: widget.orderId),
        ),
      );
    }
  }

  void _handleOrderCancelled(Map<String, dynamic> order) async {
    if (mounted) {
      // Cancel polling timers
      _locationTimer?.cancel();
      _orderStatusTimer?.cancel();
      
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
                  '/service-home', 
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
        content: const Text('You cannot exit while navigating to the client. You can only cancel the order.'),
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
        reason: "Cancelled by provider",
      );

      if (mounted) {
        // Cancel polling timers
        _locationTimer?.cancel();
        _orderStatusTimer?.cancel();
        
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
            '/service-home', 
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
    _locationTimer?.cancel();
    _orderStatusTimer?.cancel();
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
          title: const Text('Navigation'),
          backgroundColor: Colors.blue,
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
                        markers: {
                          // Client location
                          Marker(
                            markerId: const MarkerId('client_location'),
                            position: LatLng(
                              _order!['service_latitude'],
                              _order!['service_longitude'],
                            ),
                            infoWindow: const InfoWindow(title: 'Client Location'),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          ),
                          // Provider location
                          if (_currentPosition != null)
                            Marker(
                              markerId: const MarkerId('provider_location'),
                              position: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              infoWindow: const InfoWindow(title: 'Your Location'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            ),
                        },
                      ),
                    ),

                    // Order info and controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Order details
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order #${_order!['order_number']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_order!['description']),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _order!['service_address'],
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action buttons
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startJourney,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Start Journey',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Cancel button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _cancelOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel Order',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
