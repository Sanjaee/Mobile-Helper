import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/order_service.dart';
import '../../data/services/auth_service.dart';
import '../../core/widgets/loading_indicator.dart';

class ClientHistoryPage extends StatefulWidget {
  const ClientHistoryPage({super.key});

  @override
  State<ClientHistoryPage> createState() => _ClientHistoryPageState();
}

class _ClientHistoryPageState extends State<ClientHistoryPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'ALL'; // ALL, COMPLETED, CANCELLED

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
      
      // Get client orders
      final orders = await _orderService.getClientOrders(user.id);
      
      setState(() {
        _orders = orders;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'ALL') {
        _filteredOrders = _orders;
      } else if (_selectedFilter == 'COMPLETED') {
        _filteredOrders = _orders.where((order) => order['status'] == 'COMPLETED').toList();
      } else if (_selectedFilter == 'CANCELLED') {
        _filteredOrders = _orders.where((order) => order['status'] == 'CANCELLED').toList();
      }
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
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
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      isSelected: _selectedFilter == 'ALL',
                      onTap: () => _setFilter('ALL'),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Selesai',
                      isSelected: _selectedFilter == 'COMPLETED',
                      onTap: () => _setFilter('COMPLETED'),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Dibatalkan',
                      isSelected: _selectedFilter == 'CANCELLED',
                      onTap: () => _setFilter('CANCELLED'),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      : _filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.history, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedFilter == 'ALL' 
                                        ? 'Belum ada riwayat order'
                                        : _selectedFilter == 'COMPLETED'
                                            ? 'Belum ada order selesai'
                                            : 'Belum ada order dibatalkan',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadOrders,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredOrders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final order = _filteredOrders[index];
                                  final providerId = order['service_provider_id'];
                                  final providerName = providerId != null ? 'Provider' : 'Belum ada provider';
                                  
                                  return _HistoryCard(
                                    providerName: providerName,
                                    orderNumber: order['order_number'] ?? 'N/A',
                                    serviceName: order['description'] ?? 'No description',
                                    date: _formatDate(order['created_at']),
                                    status: _getStatusLabel(order['status'] ?? ''),
                                    statusColor: _getStatusColor(order['status'] ?? ''),
                                    price: 'Rp ${order['total_amount']?.toString() ?? '0'}',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String providerName;
  final String orderNumber;
  final String serviceName;
  final String date;
  final String status;
  final Color statusColor;
  final String price;

  const _HistoryCard({
    required this.providerName,
    required this.orderNumber,
    required this.serviceName,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.price,
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
          // Header: Provider name and status
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
                    providerName,
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
          
          // Footer: Date and price
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
                price,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
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

