import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/api_config.dart';

class DirectionsService {
  static const String _baseUrl = ApiConfig.directionsApiUrl;
  static const String _apiKey = ApiConfig.googleMapsApiKey;
  
  final Dio _dio = Dio();

  /// Get directions between two points using Google Directions API
  /// Returns a list of LatLng points for the route that follows actual roads
  Future<List<LatLng>> getDirections({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String mode = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destinationLat,$destinationLng',
          'mode': mode,
          'key': _apiKey,
          'alternatives': ApiConfig.requestAlternatives.toString(),
          'avoid': ApiConfig.avoidOptions.join('|'),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Get the encoded polyline
          final polyline = route['overview_polyline']['points'];
          
          // Decode the polyline to get LatLng points using flutter_polyline_points
          final List<PointLatLng> polylinePoints = PolylinePoints().decodePolyline(polyline);
          
          // Convert PointLatLng to LatLng
          return polylinePoints.map((point) => LatLng(point.latitude, point.longitude)).toList();
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      // Return a straight line if API fails
      return [
        LatLng(originLat, originLng),
        LatLng(destinationLat, destinationLng),
      ];
    }
  }

  /// Get directions with additional information (distance, duration, etc.)
  Future<DirectionsResult> getDirectionsWithInfo({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String mode = 'driving',
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destinationLat,$destinationLng',
          'mode': mode,
          'key': _apiKey,
          'alternatives': ApiConfig.requestAlternatives.toString(),
          'avoid': ApiConfig.avoidOptions.join('|'),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Get the encoded polyline
          final polyline = route['overview_polyline']['points'];
          
          // Decode the polyline to get LatLng points using flutter_polyline_points
          final List<PointLatLng> polylinePoints = PolylinePoints().decodePolyline(polyline);
          final List<LatLng> points = polylinePoints.map((point) => LatLng(point.latitude, point.longitude)).toList();
          
          // Extract distance and duration
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          final durationValue = leg['duration']['value']; // in seconds
          
          return DirectionsResult(
            points: points,
            distance: distance,
            duration: duration,
            durationInSeconds: durationValue,
          );
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      // Return a straight line if API fails
      return DirectionsResult(
        points: [
          LatLng(originLat, originLng),
          LatLng(destinationLat, destinationLng),
        ],
        distance: 'Unknown',
        duration: 'Unknown',
        durationInSeconds: 0,
      );
    }
  }


  /// Get estimated time of arrival (ETA) in minutes
  Future<int> getETA({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String mode = 'driving',
  }) async {
    try {
      final result = await getDirectionsWithInfo(
        originLat: originLat,
        originLng: originLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        mode: mode,
      );
      
      return (result.durationInSeconds / 60).round();
    } catch (e) {
      print('Error getting ETA: $e');
      return 0;
    }
  }
}

/// Data class to hold directions result
class DirectionsResult {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final int durationInSeconds;

  DirectionsResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.durationInSeconds,
  });
}
