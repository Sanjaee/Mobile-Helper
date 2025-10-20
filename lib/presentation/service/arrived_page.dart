import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';

class ServiceArrivedPage extends StatefulWidget {
  final String orderId;

  const ServiceArrivedPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ServiceArrivedPage> createState() => _ServiceArrivedPageState();
}

class _ServiceArrivedPageState extends State<ServiceArrivedPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      
      // If already arrived, navigate to job detail page immediately
      if (mounted && order['status'] == 'ARRIVED') {
        context.go('/provider-job-detail?orderId=${widget.orderId}');
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

  Future<void> _confirmArrival() async {
    try {
      final user = await _authService.getUserProfile();

      await _orderService.updateOrderArrived(
        orderId: widget.orderId,
        providerId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrival confirmed!')),
        );
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error confirming arrival: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrived at Location'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Status card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 80,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'You Have Arrived!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
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
                              const SizedBox(height: 24),
                              const Text(
                                'You have arrived at the client location. Please confirm your arrival.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow('Description', _order!['description']),
                              _buildDetailRow('Address', _order!['service_address']),
                              _buildDetailRow('Status', _order!['status']),
                              _buildDetailRow(
                                'Accepted At',
                                _order!['accepted_time'] != null
                                    ? DateTime.parse(_order!['accepted_time']).toString().split('.')[0]
                                    : 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmArrival,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Confirm Arrival',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
