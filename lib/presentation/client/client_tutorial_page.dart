import 'package:flutter/material.dart';

class ClientTutorialPage extends StatelessWidget {
  const ClientTutorialPage({super.key});

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
                icon: Icons.shopping_bag,
                title: 'Cara Memesan Layanan',
                description: 'Pelajari cara memesan layanan dengan mudah',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.payment,
                title: 'Cara Pembayaran',
                description: 'Panduan lengkap metode pembayaran',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.location_on,
                title: 'Melacak Lokasi Provider',
                description: 'Pantau lokasi provider secara real-time',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              
              _TutorialCard(
                icon: Icons.star,
                title: 'Memberikan Rating',
                description: 'Cara memberikan rating dan review',
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

