import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class GoogleAuthService {
  // Tidak perlu clientId manual, Firebase akan otomatis menggunakan dari google-services.json
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Sign in with Google
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      return googleUser;
    } catch (error) {
      debugPrint('Google Sign In Error: $error');
      return null;
    }
  }

  // Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Google Sign Out Error: $error');
    }
  }

  // Check if user is currently signed in
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current user
  static Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }

  // Disconnect from Google (revoke access)
  static Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      debugPrint('Google Disconnect Error: $error');
    }
  }
}
