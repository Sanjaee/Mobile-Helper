import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../data/services/auth_service.dart';

class ServiceHomePage extends StatelessWidget {
  const ServiceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Home'),
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
            Text('Operasional', style: AppTextStyles.h2),
            const SizedBox(height: 12),
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
                  onTap: () => NavigationHelper.pushTo(context, '/service-map'),
                ),
                _MenuItem(icon: Icons.assignment, label: 'Orders'),
                _MenuItem(icon: Icons.inventory_2, label: 'Inventory'),
                _MenuItem(icon: Icons.people, label: 'Clients'),
                _MenuItem(icon: Icons.analytics, label: 'Reports'),
                _MenuItem(icon: Icons.payments, label: 'Payments'),
                _MenuItem(icon: Icons.support_agent, label: 'Support'),
                _MenuItem(icon: Icons.more_horiz, label: 'More'),
              ],
            ),

            const SizedBox(height: 24),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Announcements', style: AppTextStyles.bodyLarge),
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


