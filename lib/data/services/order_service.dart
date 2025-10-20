import '../../core/constants/api_endpoints.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _apiClient = ApiClient();
  
  OrderService() {
    _apiClient.init();
  }

  // Create a new order
  Future<Map<String, dynamic>> createOrder({
    required String clientId,
    required String description,
    required double serviceLatitude,
    required double serviceLongitude,
    required String serviceAddress,
    required DateTime requestedTime,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.createOrder,
        data: {
          'client_id': clientId,
          'description': description,
          'service_latitude': serviceLatitude,
          'service_longitude': serviceLongitude,
          'service_address': serviceAddress,
          'requested_time': requestedTime.toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>> getOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getOrder}/$orderId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get order');
      }
    } catch (e) {
      throw Exception('Error getting order: $e');
    }
  }

  // Accept order
  Future<Map<String, dynamic>> acceptOrder({
    required String orderId,
    required String providerId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.acceptOrder}/$orderId/accept',
        data: {
          'provider_id': providerId,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to accept order');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  // Update order to on the way
  Future<Map<String, dynamic>> updateOrderOnTheWay({
    required String orderId,
    required String providerId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.updateOrderOnTheWay}/$orderId/on-the-way?provider_id=$providerId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Update order to arrived
  Future<Map<String, dynamic>> updateOrderArrived({
    required String orderId,
    required String providerId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.updateOrderArrived}/$orderId/arrived?provider_id=$providerId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Get client orders
  Future<List<Map<String, dynamic>>> getClientOrders(String clientId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getClientOrders}/$clientId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get client orders');
      }
    } catch (e) {
      throw Exception('Error getting client orders: $e');
    }
  }

  // Get provider orders
  Future<List<Map<String, dynamic>>> getProviderOrders(String providerId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getProviderOrders}/$providerId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get provider orders');
      }
    } catch (e) {
      throw Exception('Error getting provider orders: $e');
    }
  }

  // Get all pending orders (for providers to see available orders)
  Future<List<Map<String, dynamic>>> getAllPendingOrders() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getOrder}/pending',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get pending orders');
      }
    } catch (e) {
      throw Exception('Error getting pending orders: $e');
    }
  }

  // Start job
  Future<Map<String, dynamic>> startJob({
    required String orderId,
    required String providerId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.getOrder}/$orderId/start-job?provider_id=$providerId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to start job');
      }
    } catch (e) {
      throw Exception('Error starting job: $e');
    }
  }

  // Complete job
  Future<Map<String, dynamic>> completeJob({
    required String orderId,
    required String providerId,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.getOrder}/$orderId/complete-job?provider_id=$providerId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to complete job');
      }
    } catch (e) {
      throw Exception('Error completing job: $e');
    }
  }

  // Cancel order
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String cancelledBy,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '${ApiEndpoints.getOrder}/$orderId/cancel',
        data: {
          'cancelled_by': cancelledBy,
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }
}
