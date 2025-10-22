import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_state_service.dart';
import '../../data/services/google_directions_service.dart';
import '../../data/services/websocket_service.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/utils/jwt_utils.dart';

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
  final GoogleDirectionsService _directionsService = GoogleDirectionsService();
  final WebSocketService _wsService = WebSocketService();
  Timer? _locationTimer;
  StreamSubscription? _wsSubscription;
  GoogleMapController? _mapController;
  Map<String, dynamic>? _order;
  Position? _currentPosition;
  bool _isLoading = true;
  Set<Polyline> _polylines = {};
  LatLng? _lastCameraPosition;
  String _distanceText = '';
  String _durationText = '';
  int _etaMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _getCurrentLocation();
    _startLocationTracking();
    _connectToOrderWebSocket();
  }

  void _connectToOrderWebSocket() {
    print('🔌 Connecting to Order WebSocket for: ${widget.orderId}');
    _wsSubscription = _wsService.connectToOrder(widget.orderId).listen(
      (message) {
        final type = message['type'];
        final data = message['data'];
        
        print('📩 Received WebSocket message: $type');
        
        switch (type) {
          case 'order_on_the_way':
          case 'order_arrived':
          case 'order_cancelled':
            // Update order data
            if (data != null) {
              setState(() {
                _order = Map<String, dynamic>.from(data);
              });
              
              // Handle status changes
              if (type == 'order_arrived') {
                _navigateToArrivedPage();
              } else if (type == 'order_cancelled') {
                _handleOrderCancelled(_order!);
              }
            }
            break;
        }
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
        // Fallback: reload order manually if WebSocket fails
        _loadOrder();
      },
    );
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
      
      // Load directions if we have both order and current position
      if (_currentPosition != null) {
        _loadDirections();
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
      
      // Update camera to follow provider
      _updateCameraPosition();
      
      // Load directions if we have both order and current position
      if (_order != null) {
        _loadDirections();
      }
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
        // Update directions when location changes
        await _loadDirections();
      }
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

  Future<void> _markArrived() async {
    try {
      final user = await _authService.getUserProfile();

      // Directly mark as arrived
      await _orderService.updateOrderArrived(
        orderId: widget.orderId,
        providerId: user.id,
      );

      if (mounted) {
        // Navigate to job detail page
        _navigateToArrivedPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking arrived: $e')),
        );
      }
    }
  }

  void _navigateToArrivedPage() {
    if (mounted) {
      context.go('/service-arrived?orderId=${widget.orderId}');
    }
  }

  void _handleOrderCancelled(Map<String, dynamic> order) async {
    if (mounted) {
      // Cancel timers and disconnect WebSocket
      _locationTimer?.cancel();
      _wsSubscription?.cancel();
      _wsService.disconnect();
      
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
                context.go('/service-home');
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
        // Cancel timers and disconnect WebSocket
        _locationTimer?.cancel();
        _wsSubscription?.cancel();
        _wsService.disconnect();
        
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
          context.go('/service-home');
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

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_order != null) {
      // Client location with custom icon
      markers.add(
        Marker(
          markerId: const MarkerId('client_location'),
          position: LatLng(
            _order!['service_latitude'],
            _order!['service_longitude'],
          ),
          infoWindow: const InfoWindow(title: 'Tujuan'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      
      // Provider location (current position) with custom icon
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('provider_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Lokasi Anda'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            rotation: _currentPosition!.heading, // Rotate marker based on heading
          ),
        );
      }
    }
    
    return markers;
  }

  Future<void> _loadDirections() async {
    if (_order != null && _currentPosition != null) {
      try {
        // Get polyline points that follow actual roads
        final points = await _directionsService.getPolylinePoints(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _order!['service_latitude'],
          _order!['service_longitude'],
        );
        
        // Convert PointLatLng to LatLng
        final polylineCoordinates = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: const Color(0xFF00BFA5), // Gojek-like green color
              width: 6,
              patterns: [PatternItem.dash(30), PatternItem.gap(15)],
              jointType: JointType.round,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
            ),
          };
        });
        
        // Get additional info for ETA
        try {
          final result = await _directionsService.getPolylinePointsWithInfo(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _order!['service_latitude'],
            _order!['service_longitude'],
          );
          
          setState(() {
            _distanceText = result.distance;
            _durationText = result.duration;
            _etaMinutes = result.durationInSeconds ~/ 60;
          });
        } catch (e) {
          print('Error getting route info: $e');
        }
      } catch (e) {
        print('Error loading directions: $e');
        // Fallback to straight line
        setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              LatLng(
                _order!['service_latitude'],
                _order!['service_longitude'],
              ),
            ],
              color: const Color(0xFF00BFA5), // Gojek-like green color
              width: 6,
              patterns: [PatternItem.dash(30), PatternItem.gap(15)],
              jointType: JointType.round,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
            ),
          };
        });
      }
    }
  }

  Future<void> _updateCameraPosition() async {
    if (_mapController != null && _currentPosition != null) {
      final newPosition = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      // Only update camera if position changed significantly
      if (_lastCameraPosition == null || 
          _calculateDistance(_lastCameraPosition!, newPosition) > 50) {
        
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newPosition,
              zoom: 16.0, // Closer zoom for navigation
              tilt: 45.0, // Slight tilt for better 3D effect
              bearing: _currentPosition!.heading, // Rotate based on heading
            ),
          ),
        );
        
        _lastCameraPosition = newPosition;
      }
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _wsSubscription?.cancel();
    _wsService.disconnect();
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.white,
          body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SafeArea(
                  top: false, // Allow map to extend under status bar
                  child: Column(
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
                        markers: _buildMarkers(),
                        polylines: _polylines,
                      ),
                    ),

                    // Minimal order info and controls
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          // Order info with ETA
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  size: 24,
                                  color: Color(0xFF00BFA5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${_order!['order_number']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _order!['description'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // ETA info
                              if (_etaMinutes > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BFA5).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF00BFA5).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_etaMinutes',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00BFA5),
                                        ),
                                      ),
                                      const Text(
                                        'menit',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF00BFA5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Distance and duration info
                          if (_distanceText.isNotEmpty && _durationText.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.straighten,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _distanceText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _durationText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ),
                          const SizedBox(height: 16),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _markArrived,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00BFA5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sampai di Tempat',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
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
                                    'Cancel',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
