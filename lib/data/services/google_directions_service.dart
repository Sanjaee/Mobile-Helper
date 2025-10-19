import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../core/constants/api_config.dart';

class GoogleDirectionsService {
  final Dio _dio = Dio();
  final String apiKey = ApiConfig.googleMapsApiKey;

  /// Get polyline points that follow actual roads
  Future<List<PointLatLng>> getPolylinePoints(
      double startLat, double startLng, double endLat, double endLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey';

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        return PolylinePoints().decodePolyline(points);
      } else {
        print('Error: ${data['status']}');
        return [];
      }
    } catch (e) {
      print('Error getPolylinePoints: $e');
      return [];
    }
  }

  /// Get polyline points with additional route information
  Future<DirectionsResult> getPolylinePointsWithInfo(
      double startLat, double startLng, double endLat, double endLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey';

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final points = route['overview_polyline']['points'];
        
        final polylinePoints = PolylinePoints().decodePolyline(points);
        
        return DirectionsResult(
          points: polylinePoints,
          distance: leg['distance']['text'],
          duration: leg['duration']['text'],
          durationInSeconds: leg['duration']['value'],
        );
      } else {
        print('Error: ${data['status']}');
        return DirectionsResult(
          points: [],
          distance: 'Unknown',
          duration: 'Unknown',
          durationInSeconds: 0,
        );
      }
    } catch (e) {
      print('Error getPolylinePointsWithInfo: $e');
      return DirectionsResult(
        points: [],
        distance: 'Unknown',
        duration: 'Unknown',
        durationInSeconds: 0,
      );
    }
  }

  /// Get ETA in minutes
  Future<int> getETA(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      final result = await getPolylinePointsWithInfo(
        startLat, startLng, endLat, endLng,
      );
      return result.durationInSeconds ~/ 60;
    } catch (e) {
      print('Error getting ETA: $e');
      return 0;
    }
  }
}

/// Data class to hold directions result with polyline points
class DirectionsResult {
  final List<PointLatLng> points;
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
