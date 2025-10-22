class ApiClient {
  // Change to your actual API Gateway URL
  static const String baseUrl = 'http://192.168.194.248:5000/api/v1';
  static const String websocketUrl = 'ws://192.168.194.248:5000/api/v1/ws';
  
  // For Android emulator: use 10.0.2.2 instead of localhost
  // static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  // static const String websocketUrl = 'ws://10.0.2.2:5000/api/v1/ws';
  
  // For localhost testing (iOS simulator or web)
  // static const String baseUrl = 'http://localhost:5000/api/v1';
  // static const String websocketUrl = 'ws://localhost:5000/api/v1/ws';
}

