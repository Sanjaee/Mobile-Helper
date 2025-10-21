import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../core/widgets/profile_avatar.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  UserModel? _user;
  
  final List<String> _bannerImages = [
    'https://images.tokopedia.net/img/cache/1208/NsjrJu/2025/10/2/6df4fcc2-9ec1-4083-ae5c-a67b3ead7a70.jpg',
    'https://images.tokopedia.net/img/cache/1208/NsjrJu/2025/10/16/dbadf1ea-8b6b-43b1-83dd-6b6b89acc152.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _startAutoPlay();
  }
  
  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= _bannerImages.length) nextPage = 0;
        
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ).then((_) => _startAutoPlay());
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getUserProfile();
      setState(() {
        _user = user;
      });
    } catch (e) {
      // Handle error silently or show minimal error
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar and Profile
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Cari layanan',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _user != null
                        ? ProfileAvatar(
                            photoUrl: _user!.profilePhoto,
                            fullName: _user!.fullName,
                            size: 40,
                            onTap: () => context.push('/client-profile'),
                          )
                        : IconButton(
                            icon: const Icon(Icons.account_circle),
                            iconSize: 40,
                            onPressed: () => context.push('/client-profile'),
                          ),
                  ],
                ),
              ),

              // Carousel Banner
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _bannerImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_bannerImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                    // Page indicators
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: _bannerImages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.white,
                            dotColor: Colors.white.withOpacity(0.5),
                            dotHeight: 6,
                            dotWidth: 6,
                            expansionFactor: 3,
                            spacing: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Layanan Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                  children: [
                    _MenuItem(
                      icon: Icons.add_circle,
                      label: 'Order',
                      onTap: () => context.go('/create-order'),
                    ),
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
                    _MenuItem(icon: Icons.more_horiz, label: 'More'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


