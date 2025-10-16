import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_helper.dart';
import 'api_client.dart';
import 'google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Register user
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());
        await StorageHelper.saveUserType(authResponse.user.userType);

        return authResponse;
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Login user
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());
        await StorageHelper.saveUserType(authResponse.user.userType);

        return authResponse;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      // If backend returns 403 with EMAIL_NOT_VERIFIED, rethrow a typed signal
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          final code = data['code']?.toString();
          if (code == 'EMAIL_NOT_VERIFIED') {
            // Attach email for convenience if present
            final email = data['email']?.toString() ?? request.email;
            throw EmailNotVerifiedException(email: email);
          }
        }
      }
      throw _handleError(e);
    }
  }

  // Resend OTP then return success
  Future<void> ensureOtpResentForUnverified(String email) async {
    await resendOTP(email, type: 'registration');
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP(OTPVerifyRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOtp,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());
        await StorageHelper.saveUserType(authResponse.user.userType);

        return authResponse;
      } else {
        throw Exception('OTP verification failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Resend OTP
  Future<void> resendOTP(String email, {String type = 'registration'}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.resendOtp,
        data: {
          'email': email,
          'type': type,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to resend OTP');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Request password reset
  Future<void> requestResetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.requestResetPassword,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request password reset');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Verify OTP for reset password
  Future<void> verifyOTPResetPassword(OTPVerifyRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyOtpResetPassword,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('OTP verification failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Verify reset password
  Future<AuthResponse> verifyResetPassword(
    VerifyResetPasswordRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.verifyResetPassword,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());
        await StorageHelper.saveUserType(authResponse.user.userType);

        return authResponse;
      } else {
        throw Exception('Password reset verification failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Google Sign In with Google Sign In package
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser =
          await GoogleAuthService.signInWithGoogle();

      if (googleUser == null) {
        throw Exception('Google Sign In was cancelled or failed');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      // Create request for backend
      final request = GoogleOAuthRequest(
        email: googleUser.email,
        fullName: googleUser.displayName ?? '',
        profilePhoto: googleUser.photoUrl ?? '',
        googleId: googleUser.id,
      );

      // Send to backend
      final response = await _apiClient.dio.post(
        ApiEndpoints.googleOAuth,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());

        return authResponse;
      } else {
        throw Exception('Google OAuth failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Google OAuth (for direct API calls)
  Future<AuthResponse> googleOAuth(GoogleOAuthRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.googleOAuth,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        // Save tokens and user data
        await StorageHelper.saveTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );
        await StorageHelper.saveUserData(authResponse.user.toJson().toString());

        return authResponse;
      } else {
        throw Exception('Google OAuth failed');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user profile
  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.userProfile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to get user profile');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update user profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiEndpoints.updateProfile,
        data: data,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['user']);
        await StorageHelper.saveUserData(user.toJson().toString());
        return user;
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    await StorageHelper.clearAll();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await StorageHelper.isLoggedIn();
  }

  // Check user status and OTP type
  Future<Map<String, dynamic>> checkUserStatus(String email) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.checkUserStatus,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to check user status');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get stored user data
  Future<UserModel?> getStoredUser() async {
    final userData = await StorageHelper.getUserData();
    if (userData != null) {
      // Parse user data from string
      // This is a simplified version - you might want to use proper JSON parsing
      return null; // Implement proper parsing based on your storage format
    }
    return null;
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
