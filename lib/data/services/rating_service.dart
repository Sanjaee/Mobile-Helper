import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import 'api_client.dart';

class RatingService {
  final ApiClient _apiClient = ApiClient();

  // Create rating
  Future<Map<String, dynamic>> createRating({
    required String orderId,
    required String serviceProviderId,
    required int rating,
    String? review,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiEndpoints.baseUrl}/api/v1/ratings',
        data: {
          'order_id': orderId,
          'service_provider_id': serviceProviderId,
          'rating': rating,
          if (review != null && review.isNotEmpty) 'review': review,
        },
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to create rating');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get rating by order ID
  Future<Map<String, dynamic>?> getRatingByOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/ratings/order/$orderId',
      );

      if (response.statusCode == 200) {
        return response.data['rating'];
      } else {
        return null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  // Check if order has been rated
  Future<bool> checkIfRated(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/ratings/order/$orderId/check',
      );

      if (response.statusCode == 200) {
        return response.data['is_rated'] ?? false;
      } else {
        return false;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get provider ratings
  Future<List<Map<String, dynamic>>> getProviderRatings(
    String providerId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/ratings/provider/$providerId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['ratings'] ?? []);
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get provider rating stats
  Future<Map<String, dynamic>?> getProviderStats(String providerId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/ratings/provider/$providerId/stats',
      );

      if (response.statusCode == 200) {
        return response.data['stats'];
      } else {
        return null;
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get my ratings (ratings given by current user)
  Future<List<Map<String, dynamic>>> getMyRatings({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiEndpoints.baseUrl}/api/v1/ratings/my-ratings',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['ratings'] ?? []);
      } else {
        return [];
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(DioException e) {
    if (e.response?.data != null) {
      final errorData = e.response!.data;
      if (errorData is Map<String, dynamic>) {
        return errorData['error'] ??
            errorData['message'] ??
            'An error occurred';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

