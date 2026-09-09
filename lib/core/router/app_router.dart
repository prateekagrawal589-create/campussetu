// lib/core/router/app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

import '../../features/auth/welcome_screen.dart';
import '../../features/auth/auth_confirm_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/connect/connect_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_detail_screen.dart';
import '../../features/tshare/tshare_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/resume/resume_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/startup/startup_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/legal/privacy_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../shell/main_shell.dart';

class AppRoutes {
  static const welcome = '/';
  static const authConfirm = '/auth-confirm';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const connect = '/connect';
  static const chat = '/chat';
  static const chatDetail = '/chat/:chatId';
  static const tshare = '/tshare';
  static const jobs = '/jobs';
  static const products = '/products';
  static const productDetail = '/products/:productId';
  static const resume = '/resume';
  static const profile = '/profile';
  static const startup = '/startup';
  static const admin = '/admin';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const notifications = '/notifications';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final isLoading = authAsync.isLoading;
  final user = authAsync.value;
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      if (isLoading) return null;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.authConfirm ||
          state.matchedLocation == AppRoutes.profileSetup;

      if (user == null && !isOnAuthRoute) return AppRoutes.welcome;
      if (user != null && isOnAuthRoute && state.matchedLocation == AppRoutes.welcome) return AppRoutes.home;
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: AppRoutes.authConfirm,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AuthConfirmScreen(userData: extra ?? {});
        },
      ),
      GoRoute(path: AppRoutes.profileSetup, builder: (_, __) => const ProfileSetupScreen()),

      GoRoute(path: AppRoutes.privacy, builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.terms, builder: (_, __) => const TermsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),

      // Admin route (no main shell)
      GoRoute(path: AppRoutes.admin, builder: (_, __) => const AdminDashboardScreen()),

      // Main app shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.connect, builder: (_, __) => const ConnectScreen()),
          GoRoute(path: AppRoutes.chat, builder: (_, __) => const ChatListScreen()),
          GoRoute(
            path: AppRoutes.chatDetail,
            builder: (_, state) => ChatDetailScreen(chatId: state.pathParameters['chatId']!),
          ),
          GoRoute(path: AppRoutes.tshare, builder: (_, __) => const TshareScreen()),
          GoRoute(path: AppRoutes.jobs, builder: (_, __) => const JobsScreen()),
          GoRoute(path: AppRoutes.products, builder: (_, __) => const ProductsScreen()),
          GoRoute(
            path: AppRoutes.productDetail,
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['productId']!),
          ),
          GoRoute(path: AppRoutes.resume, builder: (_, __) => const ResumeScreen()),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, state) {
              final userId = state.uri.queryParameters['userId'];
              return ProfileScreen(userId: userId);
            },
          ),
          GoRoute(path: AppRoutes.startup, builder: (_, __) => const StartupScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFE9EBEE),
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
