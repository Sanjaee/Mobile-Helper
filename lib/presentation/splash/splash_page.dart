import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/navigation.dart';
import '../../data/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (mounted) {
        if (isLoggedIn) {
          // User is logged in, go to home
          NavigationHelper.goToAndClearStack(context, '/home');
        } else {
          // User is not logged in, go to login
          NavigationHelper.goToAndClearStack(context, '/login');
        }
      }
    } catch (e) {
      // If there's an error, go to login page
      if (mounted) {
        NavigationHelper.goToAndClearStack(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                color: AppColors.textOnPrimary,
                size: 60,
              ),
            ),

            const SizedBox(height: 32),

            // App name
            Text(
              'Mobile Helper',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // App tagline
            Text(
              'Your Personal Assistant',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(color: AppColors.primary),

            const SizedBox(height: 16),

            // Loading text
            Text(
              'Loading...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
