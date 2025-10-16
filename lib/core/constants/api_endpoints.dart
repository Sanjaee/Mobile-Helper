class ApiEndpoints {
  // Base URL - API Gateway
  static const String baseUrl = 'http://192.168.194.248:5000';

  // Auth endpoints
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String resendOtp = '/api/v1/auth/resend-otp';
  static const String refreshToken = '/api/v1/auth/refresh-token';
  static const String googleOAuth = '/api/v1/auth/google-oauth';
  static const String requestResetPassword =
      '/api/v1/auth/request-reset-password';
  static const String verifyOtpResetPassword =
      '/api/v1/auth/verify-otp-reset-password';
  static const String verifyResetPassword =
      '/api/v1/auth/verify-reset-password';
  static const String checkUserStatus = '/api/v1/auth/check-user-status';

  // User endpoints
  static const String userProfile = '/api/v1/user/profile';
  static const String updateProfile = '/api/v1/user/profile';

  // Health check
  static const String health = '/health';
}
