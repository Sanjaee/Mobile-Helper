import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_state_service.dart';
import '../../data/services/websocket_service.dart';

class ProviderJobDetailPage extends StatefulWidget {
  final String orderId;

  const ProviderJobDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ProviderJobDetailPage> createState() => _ProviderJobDetailPageState();
}

class _ProviderJobDetailPageState extends State<ProviderJobDetailPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
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
        userRole: 'provider',
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

  Future<void> _startJob() async {
    try {
      final user = await _authService.getUserProfile();

      await _orderService.startJob(
        orderId: widget.orderId,
        providerId: user.id,
      );

      if (mounted) {
        setState(() {
          _jobStarted = true;
        });
        _startTimeTracking();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeJob() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text('Are you sure you want to mark this job as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCompleteJob();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCompleteJob() async {
    try {
      final user = await _authService.getUserProfile();

      await _orderService.completeJob(
        orderId: widget.orderId,
        providerId: user.id,
      );

      if (mounted) {
        _navigateToCompletedPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCompletedPage() {
    if (mounted) {
      context.go('/provider-job-completed?orderId=${widget.orderId}');
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
                context.go('/service-home');
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
            content: Text('Please complete the job to continue'),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Detail'),
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
                        // Order status card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _jobStarted 
                                ? const Color(0xFF00BFA5).withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _jobStarted 
                                  ? const Color(0xFF00BFA5) 
                                  : Colors.orange,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _jobStarted ? Icons.play_circle : Icons.pending,
                                size: 48,
                                color: _jobStarted 
                                    ? const Color(0xFF00BFA5) 
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _jobStarted ? 'Job In Progress' : 'Ready to Start',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _jobStarted 
                                            ? const Color(0xFF00BFA5) 
                                            : Colors.orange,
                                      ),
                                    ),
                                    if (_jobStarted)
                                      Text(
                                        'Time: ${_formatElapsedTime()}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Order details
                        _buildDetailCard(
                          'Order Information',
                          [
                            _buildDetailRow('Order Number', _order!['order_number']),
                            _buildDetailRow('Description', _order!['description']),
                            _buildDetailRow('Address', _order!['service_address']),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Client location
                        _buildDetailCard(
                          'Location',
                          [
                            _buildDetailRow('Latitude', _order!['service_latitude'].toString()),
                            _buildDetailRow('Longitude', _order!['service_longitude'].toString()),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: !_jobStarted
                              ? ElevatedButton(
                                  onPressed: _startJob,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00BFA5),
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
                                      Icon(Icons.play_arrow, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Job',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _completeJob,
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
                                      Icon(Icons.check_circle, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Complete Job',
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

  Widget _buildDetailCard(String title, List<Widget> children) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
            width: 100,
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
}

