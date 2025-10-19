import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_service.dart';

class OrderStateService {
  static const String _activeOrderKey = 'active_order';
  static const String _userRoleKey = 'user_role';
  
  final OrderService _orderService = OrderService();

  // Save active order to local storage
  Future<void> saveActiveOrder({
    required String orderId,
    required String status,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final orderData = {
      'orderId': orderId,
      'status': status,
      'userRole': userRole,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_activeOrderKey, jsonEncode(orderData));
    await prefs.setString(_userRoleKey, userRole);
  }

  // Get active order from local storage
  Future<Map<String, dynamic>?> getActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderDataString = prefs.getString(_activeOrderKey);
    if (orderDataString != null) {
      return jsonDecode(orderDataString);
    }
    return null;
  }

  // Clear active order from local storage
  Future<void> clearActiveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrderKey);
  }

  // Check if there's an active order and return the appropriate route
  Future<String?> checkActiveOrderAndGetRoute() async {
    final activeOrder = await getActiveOrder();
    if (activeOrder == null) return null;

    final orderId = activeOrder['orderId'];
    final userRole = activeOrder['userRole'];

    try {
      // Fetch current order status from server
      final currentOrder = await _orderService.getOrder(orderId);
      final currentStatus = currentOrder['status'];

      // If order is completed or cancelled, clear it
      if (currentStatus == 'COMPLETED' || currentStatus == 'CANCELLED') {
        await clearActiveOrder();
        return null;
      }

      // Return appropriate route based on status and user role
      if (userRole == 'client') {
        switch (currentStatus) {
          case 'PENDING':
            return '/waiting-provider?orderId=$orderId';
          case 'ACCEPTED':
          case 'ON_THE_WAY':
            return '/provider-on-the-way?orderId=$orderId';
          case 'ARRIVED':
            return '/provider-on-the-way?orderId=$orderId'; // You might want to create an arrived page
          default:
            return null;
        }
      } else if (userRole == 'provider') {
        // For providers, redirect to appropriate page based on status
        switch (currentStatus) {
          case 'ACCEPTED':
            return '/navigation?orderId=$orderId';
          case 'ON_THE_WAY':
            return '/navigation?orderId=$orderId';
          case 'ARRIVED':
            return '/navigation?orderId=$orderId';
          default:
            return null;
        }
      }
    } catch (e) {
      // If there's an error fetching the order, clear it
      await clearActiveOrder();
    }

    return null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }
}
