import '../../core/constants/api_endpoints.dart';
import 'api_client.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient();
  
  LocationService() {
    _apiClient.init();
  }

  // Update location
  Future<Map<String, dynamic>> updateLocation({
    required String orderId,
    required String serviceProviderId,
    required double latitude,
    required double longitude,
    double speedKmh = 0.0,
    int accuracyMeters = 0,
    int headingDegrees = 0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.updateLocation,
        data: {
          'order_id': orderId,
          'service_provider_id': serviceProviderId,
          'latitude': latitude,
          'longitude': longitude,
          'speed_kmh': speedKmh,
          'accuracy_meters': accuracyMeters,
          'heading_degrees': headingDegrees,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  // Get order location
  Future<Map<String, dynamic>> getOrderLocation(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getOrderLocation}/$orderId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get order location');
      }
    } catch (e) {
      throw Exception('Error getting order location: $e');
    }
  }

  // Get location history
  Future<List<Map<String, dynamic>>> getLocationHistory(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getLocationHistory}/$orderId/history',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get location history');
      }
    } catch (e) {
      throw Exception('Error getting location history: $e');
    }
  }

  // Get provider location
  Future<Map<String, dynamic>> getProviderLocation(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.getProviderLocation}/$orderId',
      );

      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get provider location');
      }
    } catch (e) {
      throw Exception('Error getting provider location: $e');
    }
  }
}
