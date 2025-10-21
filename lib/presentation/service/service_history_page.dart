import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/widgets/loading_indicator.dart';

class ServiceHistoryPage extends StatefulWidget {
  const ServiceHistoryPage({super.key});

  @override
  State<ServiceHistoryPage> createState() => _ServiceHistoryPageState();
}

class _ServiceHistoryPageState extends State<ServiceHistoryPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user
      final user = await _authService.getUserProfile();
      
      // Get provider orders
      final orders = await _orderService.getProviderOrders(user.id);
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu';
      case 'ACCEPTED':
        return 'Diterima';
      case 'ON_THE_WAY':
        return 'Dalam Perjalanan';
      case 'ARRIVED':
        return 'Tiba';
      case 'IN_PROGRESS':
        return 'Sedang Dikerjakan';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'IN_PROGRESS':
      case 'ON_THE_WAY':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadOrders,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadOrders,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : _orders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada riwayat order',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _orders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  
                                  return _HistoryCard(
                                    clientName: 'Client',
                                    orderNumber: order['order_number'] ?? 'N/A',
                                    serviceName: order['description'] ?? 'No description',
                                    date: _formatDate(order['created_at']),
                                    status: _getStatusLabel(order['status'] ?? ''),
                                    statusColor: _getStatusColor(order['status'] ?? ''),
                                    earnings: 'Rp ${order['total_amount']?.toString() ?? '0'}',
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String clientName;
  final String orderNumber;
  final String serviceName;
  final String date;
  final String status;
  final Color statusColor;
  final String earnings;

  const _HistoryCard({
    required this.clientName,
    required this.orderNumber,
    required this.serviceName,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getDarkerShade(statusColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Order number
          Text(
            orderNumber,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            serviceName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          
          // Footer: Date and earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                earnings,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getDarkerShade(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1,
    );
  }
}

