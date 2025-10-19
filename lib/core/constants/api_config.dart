class ApiConfig {
  // Google Maps API Key
  // This key should be the same as the one used in android/app/src/main/AndroidManifest.xml
  // and ios/Runner/AppDelegate.swift for Maps SDK for Android/iOS
  static const String googleMapsApiKey = 'AIzaSyDc6TXmd_MiPsQhHwM8807iwp25WjdPTqQ';
  
  // API Endpoints
  static const String directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  
  // Directions API Configuration
  static const String defaultTravelMode = 'driving';
  static const List<String> avoidOptions = ['tolls', 'highways'];
  static const bool requestAlternatives = false;
}
