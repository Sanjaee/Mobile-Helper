import 'package:flutter/material.dart';

class ServiceTutorialPage extends StatelessWidget {
  const ServiceTutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tutorial',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              _TutorialCard(
                icon: Icons.notifications_active,
                title: 'Menerima Pesanan',
                description: 'Cara menerima dan memproses pesanan baru',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.navigation,
                title: 'Navigasi ke Lokasi',
                description: 'Panduan menggunakan fitur navigasi',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.check_circle,
                title: 'Menyelesaikan Order',
                description: 'Cara menandai pesanan selesai',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.account_balance_wallet,
                title: 'Sistem Pembayaran',
                description: 'Cara menerima pembayaran dari client',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.black, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

