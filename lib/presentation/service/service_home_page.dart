import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/order_service.dart';
import 'order_request_page.dart';

class ServiceHomePage extends StatefulWidget {
  const ServiceHomePage({super.key});

  @override
  State<ServiceHomePage> createState() => _ServiceHomePageState();
}

class _ServiceHomePageState extends State<ServiceHomePage> {
  final OrderService _orderService = OrderService();
  Timer? _orderTimer;
  Map<String, dynamic>? _pendingOrder;

  @override
  void initState() {
    super.initState();
    _startOrderPolling();
  }

  void _startOrderPolling() {
    // Check for orders immediately
    _checkForNewOrders();
    
    // Then check every 5 seconds
    _orderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewOrders();
    });
  }

  void _checkForNewOrders() async {
    try {
      // Get all pending orders (not specific to this provider)
      // In a real app, this would be done via RabbitMQ notifications
      final orders = await _orderService.getAllPendingOrders();
      
      if (orders.isNotEmpty && _pendingOrder == null) {
        setState(() {
          _pendingOrder = orders.first;
        });
      }
    } catch (e) {
      print('Error checking for new orders: $e');
    }
  }

  void _showOrderRequest() {
    if (_pendingOrder != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => OrderRequestPage(order: _pendingOrder!),
      ).then((_) {
        setState(() {
          _pendingOrder = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                NavigationHelper.goToAndClearStack(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Operasional', style: AppTextStyles.h2),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _MenuItem(
                      icon: Icons.map,
                      label: 'Map',
                      onTap: () => NavigationHelper.pushTo(context, '/service-map'),
                    ),
                    _MenuItem(icon: Icons.assignment, label: 'Orders'),
                    _MenuItem(icon: Icons.inventory_2, label: 'Inventory'),
                    _MenuItem(icon: Icons.people, label: 'Clients'),
                    _MenuItem(icon: Icons.analytics, label: 'Reports'),
                    _MenuItem(icon: Icons.payments, label: 'Payments'),
                    _MenuItem(icon: Icons.support_agent, label: 'Support'),
                    _MenuItem(icon: Icons.more_horiz, label: 'More'),
                  ],
                ),

                const SizedBox(height: 24),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('Announcements', style: AppTextStyles.bodyLarge),
                  ),
                ),
              ],
            ),
          ),

          // Order notification
          if (_pendingOrder != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _showOrderRequest,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'New Order Available!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order #${_pendingOrder!['order_number']}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}


