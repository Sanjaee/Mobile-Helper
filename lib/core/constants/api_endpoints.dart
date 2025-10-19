class ApiEndpoints {
  // Base URL - API Gateway
  static const String baseUrl = 'http://192.168.194.248:5000';

  // Auth endpoints
  static const String register = '$baseUrl/api/v1/auth/register';
  static const String login = '$baseUrl/api/v1/auth/login';
  static const String verifyOtp = '$baseUrl/api/v1/auth/verify-otp';
  static const String resendOtp = '$baseUrl/api/v1/auth/resend-otp';
  static const String refreshToken = '$baseUrl/api/v1/auth/refresh-token';
  static const String googleOAuth = '$baseUrl/api/v1/auth/google-oauth';
  static const String requestResetPassword =
      '$baseUrl/api/v1/auth/request-reset-password';
  static const String verifyOtpResetPassword =
      '$baseUrl/api/v1/auth/verify-otp-reset-password';
  static const String verifyResetPassword =
      '$baseUrl/api/v1/auth/verify-reset-password';
  static const String checkUserStatus = '$baseUrl/api/v1/auth/check-user-status';

  // User endpoints
  static const String userProfile = '$baseUrl/api/v1/user/profile';
  static const String updateProfile = '$baseUrl/api/v1/user/profile';

  // Order endpoints
  static const String createOrder = '$baseUrl/api/v1/orders';
  static const String getOrder = '$baseUrl/api/v1/orders';
  static const String acceptOrder = '$baseUrl/api/v1/orders';
  static const String updateOrderOnTheWay = '$baseUrl/api/v1/orders';
  static const String updateOrderArrived = '$baseUrl/api/v1/orders';
  static const String getClientOrders = '$baseUrl/api/v1/orders/client';
  static const String getProviderOrders = '$baseUrl/api/v1/orders/provider';

  // Location endpoints
  static const String updateLocation = '$baseUrl/api/v1/locations/track';
  static const String getOrderLocation = '$baseUrl/api/v1/locations/order';
  static const String getLocationHistory = '$baseUrl/api/v1/locations/order';
  static const String getProviderLocation = '$baseUrl/api/v1/locations/provider';

  // WebSocket endpoints
  static const String wsBaseUrl = 'ws://192.168.194.248:5000';
  static const String wsOrders = '$wsBaseUrl/api/v1/ws/orders';
  static const String wsLocations = '$wsBaseUrl/api/v1/ws/locations';

  // Health check
  static const String health = '/health';
}
