import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/splash/splash_page.dart';
import '../presentation/auth/login_page.dart';
import '../presentation/auth/register_page.dart';
import '../presentation/auth/verify_otp_page.dart';
import '../presentation/auth/reset_password_page.dart';
import '../presentation/auth/change_password_page.dart';
import '../presentation/auth/update_password_page.dart';
import '../presentation/home/home_page.dart';
import '../presentation/client/client_home_page.dart';
import '../presentation/service/service_home_page.dart';
import '../presentation/client/client_map_full_page.dart';
import '../presentation/service/service_map_full_page.dart';
import '../presentation/client/waiting_provider_page.dart';
import '../presentation/client/provider_on_the_way_page.dart';
import '../presentation/service/navigation_page.dart';
import '../presentation/service/arrived_page.dart';
import '../presentation/client/arrived_page.dart';
import '../presentation/client/create_order_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  static const String updatePassword = '/update-password';
  static const String home = '/home';
  static const String clientHome = '/client-home';
  static const String serviceHome = '/service-home';
  static const String clientMap = '/client-map';
  static const String serviceMap = '/service-map';
  static const String waitingProvider = '/waiting-provider';
  static const String providerOnTheWay = '/provider-on-the-way';
  static const String navigation = '/navigation';
  static const String serviceArrived = '/service-arrived';
  static const String clientArrived = '/client-arrived';
  static const String createOrder = '/create-order';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash route
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // Auth routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      // verify-otp route is declared below; keeping single declaration

      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      GoRoute(
        path: verifyOtp,
        name: 'verify-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final isPasswordReset =
              (state.uri.queryParameters['isPasswordReset'] ?? 'false') == 'true';
          return VerifyOTPPage(email: email, isPasswordReset: isPasswordReset);
        },
      ),

      GoRoute(
        path: resetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),

      GoRoute(
        path: changePassword,
        name: 'change-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otpCode = state.uri.queryParameters['otpCode'] ?? '';
          return ChangePasswordPage(email: email, otpCode: otpCode);
        },
      ),

      GoRoute(
        path: updatePassword,
        name: 'update-password',
        builder: (context, state) => const UpdatePasswordPage(),
      ),

      // Home route
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // Role-based homes
      GoRoute(
        path: clientHome,
        name: 'client-home',
        builder: (context, state) => const ClientHomePage(),
      ),
      GoRoute(
        path: serviceHome,
        name: 'service-home',
        builder: (context, state) => const ServiceHomePage(),
      ),

      // Full screen maps
      GoRoute(
        path: clientMap,
        name: 'client-map',
        builder: (context, state) => const ClientMapFullPage(),
      ),
      GoRoute(
        path: serviceMap,
        name: 'service-map',
        builder: (context, state) => const ServiceMapFullPage(),
      ),

      // Order pages
      GoRoute(
        path: waitingProvider,
        name: 'waiting-provider',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return WaitingProviderPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: providerOnTheWay,
        name: 'provider-on-the-way',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return ProviderOnTheWayPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: navigation,
        name: 'navigation',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return NavigationPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: serviceArrived,
        name: 'service-arrived',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return ServiceArrivedPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: clientArrived,
        name: 'client-arrived',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return ArrivedPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: createOrder,
        name: 'create-order',
        builder: (context, state) => const CreateOrderPage(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Page not found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'The page you are looking for does not exist.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );
}
