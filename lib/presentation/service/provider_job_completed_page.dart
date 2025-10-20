import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/order_service.dart';
import '../../data/services/order_state_service.dart';

class ProviderJobCompletedPage extends StatefulWidget {
  final String orderId;

  const ProviderJobCompletedPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ProviderJobCompletedPage> createState() => _ProviderJobCompletedPageState();
}

class _ProviderJobCompletedPageState extends State<ProviderJobCompletedPage> {
  final OrderService _orderService = OrderService();
  final OrderStateService _orderStateService = OrderStateService();
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

  Future<void> _goToHome() async {
    // Clear active order state
    await _orderStateService.clearActiveOrder();
    
    if (mounted) {
      context.go('/service-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goToHome();
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
                        // Success animation/icon
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
                                  Icons.check_circle,
                                  size: 80,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Job Completed Successfully!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Waiting for client approval',
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
                            _buildSummaryRow('Started At', _formatDateTime(_order!['started_time'])),
                            _buildSummaryRow('Completed At', _formatDateTime(_order!['completed_time'])),
                            if (_order!['duration_minutes'] != null && _order!['duration_minutes'] > 0)
                              _buildSummaryRow(
                                'Total Duration',
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
                                'Total',
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
                                  'The client will review and approve the completed job. You will receive payment once approved.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Back to home button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BFA5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Back to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

