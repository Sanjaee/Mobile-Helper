class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String userType;
  final String? profilePhoto;
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLogin;
  final String loginType;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.userType,
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    required this.isActive,
    required this.isVerified,
    this.lastLogin,
    required this.loginType,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      fullName: json['full_name'] ?? '',
      userType: json['user_type'] ?? 'CLIENT',
      profilePhoto: json['profile_photo'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      loginType: json['login_type'] ?? 'CREDENTIAL',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'user_type': userType,
      'profile_photo': profilePhoto,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'is_active': isActive,
      'is_verified': isVerified,
      'last_login': lastLogin?.toIso8601String(),
      'login_type': loginType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  
  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 3600,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String? phone;
  final String password;
  final String userType;
  final String? gender;
  final DateTime? dateOfBirth;
  
  RegisterRequest({
    required this.fullName,
    required this.email,
    this.phone,
    required this.password,
    required this.userType,
    this.gender,
    this.dateOfBirth,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'user_type': userType,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({
    required this.email,
    required this.password,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class OTPVerifyRequest {
  final String email;
  final String otpCode;
  
  OTPVerifyRequest({
    required this.email,
    required this.otpCode,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
    };
  }
}

class ResetPasswordRequest {
  final String email;
  
  ResetPasswordRequest({
    required this.email,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class VerifyResetPasswordRequest {
  final String email;
  final String otpCode;
  final String newPassword;
  
  VerifyResetPasswordRequest({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
      'new_password': newPassword,
    };
  }
}

class GoogleOAuthRequest {
  final String email;
  final String fullName;
  final String? profilePhoto;
  final String googleId;
  
  GoogleOAuthRequest({
    required this.email,
    required this.fullName,
    this.profilePhoto,
    required this.googleId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': fullName,
      'profile_photo': profilePhoto,
      'google_id': googleId,
    };
  }
}
