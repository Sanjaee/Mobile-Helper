import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../data/services/auth_service.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                NavigationHelper.goToAndClearStack(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Layanan', style: AppTextStyles.h2),
            const SizedBox(height: 12),

            // Gojek-style grid menu
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _MenuItem(
                  icon: Icons.map,
                  label: 'Map',
                  onTap: () => NavigationHelper.pushTo(context, '/client-map'),
                ),
                _MenuItem(icon: Icons.delivery_dining, label: 'Delivery'),
                _MenuItem(icon: Icons.shopping_bag, label: 'Mart'),
                _MenuItem(icon: Icons.payment, label: 'Pay'),
                _MenuItem(icon: Icons.fastfood, label: 'Food'),
                _MenuItem(icon: Icons.local_taxi, label: 'Ride'),
                _MenuItem(icon: Icons.build, label: 'Service'),
                _MenuItem(icon: Icons.more_horiz, label: 'More'),
              ],
            ),

            const SizedBox(height: 24),

            // Promo or banner placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Banner / Promo', style: AppTextStyles.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}


