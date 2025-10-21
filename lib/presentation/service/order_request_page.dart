import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/location_service.dart';
import '../../core/widgets/custom_popup.dart';

class OrderRequestPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderRequestPage({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderRequestPage> createState() => _OrderRequestPageState();
}

class _OrderRequestPageState extends State<OrderRequestPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  bool _isLoading = false;

  Future<void> _acceptOrder() async {
    // Show confirmation popup
    final confirmed = await CustomPopup.showConfirmation(
      context: context,
      title: 'Accept Order?',
      message: 'Are you sure you want to accept this order? You will be directed to the navigation page.',
      confirmText: 'Accept',
      cancelText: 'Cancel',
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getUserProfile();

      // Accept the order
      await _orderService.acceptOrder(
        orderId: widget.order['id'],
        providerId: user.id,
      );

      // Get current location and send to backend
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await _locationService.updateLocation(
          orderId: widget.order['id'],
          serviceProviderId: user.id,
          latitude: position.latitude,
          longitude: position.longitude,
          speedKmh: position.speed,
          accuracyMeters: position.accuracy.round(),
          headingDegrees: position.heading.round(),
        );
      } catch (e) {
        print('Error updating location: $e');
        // Continue even if location update fails
      }

      if (mounted) {
        // Show success popup
        await CustomPopup.showSuccess(
          context: context,
          title: 'Order Accepted!',
          message: 'You have successfully accepted the order. Let\'s go to the location!',
          buttonText: 'Start Navigation',
          barrierDismissible: false,
          onConfirm: () {
            context.go('/navigation?orderId=${widget.order['id']}');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        CustomPopup.showError(
          context: context,
          title: 'Failed to Accept',
          message: 'Error accepting order: ${e.toString()}',
        );
      }
    }
  }

  void _rejectOrder() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'New Order Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _rejectOrder,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Map
              Container(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.order['service_latitude'],
                      widget.order['service_longitude'],
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('service_location'),
                      position: LatLng(
                        widget.order['service_latitude'],
                        widget.order['service_longitude'],
                      ),
                      infoWindow: InfoWindow(
                        title: 'Service Location',
                        snippet: widget.order['service_address'],
                      ),
                    ),
                  },
                ),
              ),

              // Order details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.order['order_number']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.order['description'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.order['service_address'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Requested: ${DateTime.parse(widget.order['requested_time']).toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _rejectOrder,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
