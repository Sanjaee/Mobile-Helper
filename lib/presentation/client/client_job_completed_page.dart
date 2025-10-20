import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/order_state_service.dart';
import '../../data/services/websocket_service.dart';

class ClientJobCompletedPage extends StatefulWidget {
  final String orderId;

  const ClientJobCompletedPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ClientJobCompletedPage> createState() => _ClientJobCompletedPageState();
}

class _ClientJobCompletedPageState extends State<ClientJobCompletedPage> {
  final OrderService _orderService = OrderService();
  final OrderStateService _orderStateService = OrderStateService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _connectToOrderWebSocket();
  }

  void _connectToOrderWebSocket() {
    print('🔌 Connecting to Order WebSocket for: ${widget.orderId}');
    _wsSubscription = _wsService.connectToOrder(widget.orderId).listen(
      (message) {
        final type = message['type'];
        final data = message['data'];
        
        print('📩 Received WebSocket message: $type');
        
        if (type == 'job_completed' && data != null) {
          setState(() {
            _order = Map<String, dynamic>.from(data);
          });
        }
      },
      onError: (error) {
        print('❌ WebSocket error: $error');
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
        userRole: 'client',
      );
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

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $mins minute${mins != 1 ? 's' : ''}';
    }
    return '$mins minute${mins != 1 ? 's' : ''}';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _approveCompletion() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Job'),
        content: const Text('Are you satisfied with the completed job? This will mark the order as finished and process the payment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performApproval();
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _performApproval() async {
    try {
      // In a real application, you would call an approve endpoint
      // For now, we'll just navigate away after a delay
      
      if (mounted) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          
          // Clear active order state
          await _orderStateService.clearActiveOrder();
          
          // Disconnect WebSocket
          _wsSubscription?.cancel();
          _wsService.disconnect();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job approved successfully! Payment processed.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home
          if (mounted) {
            context.go('/client-home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please review and approve the completed job'),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Completed'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _order == null
                ? const Center(child: Text('Order not found'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Success icon
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.task_alt,
                                  size: 80,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Job Completed!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please review and approve the work',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Job summary
                        _buildSummaryCard(
                          'Job Summary',
                          Icons.summarize,
                          [
                            _buildSummaryRow('Order Number', _order!['order_number']),
                            _buildSummaryRow('Description', _order!['description']),
                            _buildSummaryRow('Address', _order!['service_address']),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Time details
                        _buildSummaryCard(
                          'Time Details',
                          Icons.access_time,
                          [
                            _buildSummaryRow('Arrived At', _formatDateTime(_order!['arrived_time'])),
                            _buildSummaryRow('Started At', _formatDateTime(_order!['started_time'])),
                            _buildSummaryRow('Completed At', _formatDateTime(_order!['completed_time'])),
                            if (_order!['duration_minutes'] != null && _order!['duration_minutes'] > 0)
                              _buildSummaryRow(
                                'Work Duration',
                                _formatDuration(_order!['duration_minutes']),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Payment details (if available)
                        if (_order!['total_amount'] != null && _order!['total_amount'] > 0)
                          _buildSummaryCard(
                            'Payment',
                            Icons.payment,
                            [
                              _buildSummaryRow(
                                'Base Amount',
                                'Rp ${_order!['base_amount']?.toStringAsFixed(0) ?? '0'}',
                              ),
                              _buildSummaryRow(
                                'Service Fee',
                                'Rp ${_order!['service_fee']?.toStringAsFixed(0) ?? '0'}',
                              ),
                              const Divider(),
                              _buildSummaryRow(
                                'Total Amount',
                                'Rp ${_order!['total_amount']?.toStringAsFixed(0) ?? '0'}',
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Info message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'The provider has completed the job. Please review the work and approve if you are satisfied.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Approve button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _approveCompletion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.thumb_up, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Approve & Complete',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Report issue button (optional)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // In a real app, you would show a form to report issues
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report issue feature coming soon'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report_problem, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Report Issue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Colors.black87 : Colors.grey,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: isHighlighted ? Colors.black87 : Colors.grey,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Colors.green : Colors.black87,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

