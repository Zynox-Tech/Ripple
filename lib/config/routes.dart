import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens
import '../features/auth/presentation/splash_page.dart';
import '../features/auth/presentation/onboarding_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/profile/presentation/profile_setup_page.dart';
import '../features/home/presentation/navigation_shell.dart';
import '../features/home/presentation/home_page.dart';
import '../features/matches/presentation/matches_page.dart';
import '../features/matches/presentation/match_detail_page.dart';
import '../features/chats/presentation/chats_page.dart';
import '../features/chats/presentation/chat_room_page.dart';
import '../features/insights/presentation/insights_page.dart';
import '../features/schools/presentation/school_detail_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/subscriptions/presentation/plans_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Non-shell top-level routes
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/plans',
      builder: (context, state) => const PlansPage(),
    ),
    
    // Subroutes that push on top of the shell
    GoRoute(
      path: '/matches/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return MatchDetailPage(matchId: id);
      },
    ),
    GoRoute(
      path: '/chats/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ChatRoomPage(chatId: id);
      },
    ),
    GoRoute(
      path: '/schools/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return SchoolDetailPage(schoolId: id);
      },
    ),

    // Shell route for bottom tab bar items
    ShellRoute(
      builder: (context, state, child) {
        return MainNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesPage(),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatsPage(),
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
