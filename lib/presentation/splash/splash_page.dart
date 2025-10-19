import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/storage_helper.dart';
import '../../data/services/order_state_service.dart';

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
    await Future.delayed(const Duration(seconds: 1));
    final loggedIn = await StorageHelper.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      context.go('/login');
      return;
    }

    // Check for active orders first
    final orderStateService = OrderStateService();
    final activeOrderRoute = await orderStateService.checkActiveOrderAndGetRoute();
    
    if (activeOrderRoute != null) {
      if (!mounted) return;
      context.go(activeOrderRoute);
      return;
    }

    // If no active order, proceed with normal navigation
    final type = (await StorageHelper.getUserType())?.toUpperCase() ?? 'CLIENT';
    final isService = type == 'SERVICE' || type == 'SERVICE_PROVIDER' || type == 'PROVIDER';
    final target = isService ? '/service-home' : '/client-home';
    if (!mounted) return;
    context.go(target);
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
