import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
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
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  UserModel? _user;
  
  final List<String> _bannerImages = [
    'https://images.tokopedia.net/img/cache/1208/NsjrJu/2025/10/2/6df4fcc2-9ec1-4083-ae5c-a67b3ead7a70.jpg',
    'https://images.tokopedia.net/img/cache/1208/NsjrJu/2025/10/16/dbadf1ea-8b6b-43b1-83dd-6b6b89acc152.jpg',
  ];
  
  // For infinite scroll
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    _loadUserProfile();
    _startAutoPlay();
  }
  
  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _pageController.hasClients) {
        final currentPage = _pageController.page?.toInt() ?? _initialPage;
        _pageController.animateToPage(
          currentPage + 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _autoPlayTimer?.cancel();
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
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: ProfileAvatar(
                              photoUrl: _user!.profilePhoto,
                              fullName: _user!.fullName,
                              size: 40,
                              onTap: () => context.push('/client-profile'),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.account_circle),
                              iconSize: 40,
                              onPressed: () => context.push('/client-profile'),
                            ),
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
                      itemBuilder: (context, index) {
                        final imageIndex = index % _bannerImages.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_bannerImages[imageIndex]),
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
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            final page = _pageController.hasClients 
                                ? (_pageController.page ?? _initialPage)
                                : _initialPage.toDouble();
                            final activeIndex = (page % _bannerImages.length).round() % _bannerImages.length;
                            
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_bannerImages.length, (index) {
                                return Container(
                                  width: activeIndex == index ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    color: activeIndex == index 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                );
                              }),
                            );
                          },
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


