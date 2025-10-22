import 'dart:convert';

class JwtUtils {
  // Decode JWT token and extract payload
  static Map<String, dynamic> decode(String token) {
    return decodeJwtPayload(token) ?? {};
  }

  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      // Split the token into parts
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (middle part)
      final payload = parts[1];
      
      // Add padding if needed
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      
      return json.decode(resp);
    } catch (e) {
      return null;
    }
  }

  // Extract user ID from JWT token
  static String? getUserIdFromToken(String token) {
    final payload = decodeJwtPayload(token);
    return payload?['user_id']?.toString();
  }

  // Extract user type from JWT token
  static String? getUserTypeFromToken(String token) {
    final payload = decodeJwtPayload(token);
    return payload?['user_type']?.toString();
  }

  // Check if token is expired
  static bool isTokenExpired(String token) {
    final payload = decodeJwtPayload(token);
    if (payload == null) return true;
    
    final exp = payload['exp'];
    if (exp == null) return true;
    
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expirationTime);
  }
}
