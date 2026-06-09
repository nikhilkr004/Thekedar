import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../presentation/screens/main_navigation_screen.dart';
import '../../features/projects/presentation/screens/post_project_screen.dart';
import '../../features/contractor/presentation/screens/send_proposal_screen.dart';
import '../../features/contractor/presentation/screens/wallet_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer_home',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/post_project',
        builder: (context, state) => const PostProjectScreen(),
      ),
      GoRoute(
        path: '/my_projects',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
      ),

      // Contractor Routes
      GoRoute(
        path: '/profile_setup',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
      ),
      GoRoute(
        path: '/leads',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/contractor_quotes',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/send_proposal',
        builder: (context, state) {
          final projectId = state.extra as String? ?? '';
          return SendProposalScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),

      // Communication Routes
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final projectId = state.extra as String? ?? '';
          return ChatScreen(projectId: projectId);
        },
      ),
      GoRoute(
        path: '/chat_list',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
      ),
    ],
  );
});
