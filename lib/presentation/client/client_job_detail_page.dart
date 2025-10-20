import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/order_state_service.dart';
import '../../data/services/websocket_service.dart';

class ClientJobDetailPage extends StatefulWidget {
  final String orderId;

  const ClientJobDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ClientJobDetailPage> createState() => _ClientJobDetailPageState();
}

class _ClientJobDetailPageState extends State<ClientJobDetailPage> {
  final OrderService _orderService = OrderService();
  final OrderStateService _orderStateService = OrderStateService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _wsSubscription;
  Timer? _timeTracker;
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  int _elapsedSeconds = 0;
  bool _jobStarted = false;

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
        
        switch (type) {
          case 'job_started':
            if (data != null) {
              setState(() {
                _order = Map<String, dynamic>.from(data);
                _jobStarted = true;
              });
              _startTimeTracking();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Provider has started the job!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            break;
          case 'job_completed':
            if (data != null) {
              setState(() {
                _order = Map<String, dynamic>.from(data);
              });
              _navigateToCompletedPage();
            }
            break;
          case 'order_cancelled':
            if (data != null) {
              setState(() {
                _order = Map<String, dynamic>.from(data);
              });
              _handleOrderCancelled(_order!);
            }
            break;
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
        _jobStarted = order['status'] == 'IN_PROGRESS';
      });

      // Save active order state
      await _orderStateService.saveActiveOrder(
        orderId: widget.orderId,
        status: order['status'],
        userRole: 'client',
      );

      // Check if job has already started
      if (_jobStarted && order['started_time'] != null) {
        // Calculate elapsed time
        final startedTime = DateTime.parse(order['started_time']);
        _elapsedSeconds = DateTime.now().difference(startedTime).inSeconds;
        _startTimeTracking();
      }

      // Navigate to completed if already completed
      if (order['status'] == 'COMPLETED') {
        _navigateToCompletedPage();
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

  void _startTimeTracking() {
    _timeTracker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatElapsedTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _navigateToCompletedPage() {
    if (mounted) {
      context.go('/client-job-completed?orderId=${widget.orderId}');
    }
  }

  void _handleOrderCancelled(Map<String, dynamic> order) async {
    if (mounted) {
      // Cancel timers and disconnect WebSocket
      _timeTracker?.cancel();
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
                context.go('/client-home');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timeTracker?.cancel();
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
        // Don't allow back navigation during job
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the job to complete'),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job In Progress'),
          backgroundColor: const Color(0xFF00BFA5),
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
                        // Status card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _jobStarted
                                  ? [const Color(0xFF00BFA5), const Color(0xFF00897B)]
                                  : [Colors.orange, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (_jobStarted ? const Color(0xFF00BFA5) : Colors.orange).withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _jobStarted ? Icons.engineering : Icons.hourglass_empty,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _jobStarted ? 'Provider is Working' : 'Waiting for Provider to Start',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_jobStarted) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _formatElapsedTime(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Elapsed Time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Order details
                        _buildDetailCard(
                          'Order Information',
                          Icons.receipt_long,
                          [
                            _buildDetailRow('Order Number', _order!['order_number']),
                            _buildDetailRow('Description', _order!['description']),
                            _buildDetailRow('Address', _order!['service_address']),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Status info
                        _buildDetailCard(
                          'Status',
                          Icons.info_outline,
                          [
                            _buildDetailRow('Current Status', _jobStarted ? 'In Progress' : 'Arrived'),
                            if (_order!['arrived_time'] != null)
                              _buildDetailRow(
                                'Arrived At', 
                                _formatDateTime(_order!['arrived_time']),
                              ),
                            if (_order!['started_time'] != null)
                              _buildDetailRow(
                                'Started At', 
                                _formatDateTime(_order!['started_time']),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _jobStarted
                                      ? 'The provider is currently working on your request. You will be notified when the job is completed.'
                                      : 'The provider has arrived at your location. Waiting for them to start the job.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
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

  Widget _buildDetailCard(String title, IconData icon, List<Widget> children) {
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
              Icon(icon, color: const Color(0xFF00BFA5)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}

