import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/projects/presentation/screens/customer_home_screen.dart';
import '../../../features/projects/presentation/screens/my_projects_screen.dart';
import '../../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../../features/contractor/presentation/screens/profile_setup_screen.dart';
import '../../../features/contractor/presentation/screens/leads_feed_screen.dart';
import '../../../features/contractor/presentation/screens/contractor_quotes_screen.dart';

import '../../../features/auth/presentation/providers/auth_provider.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value ?? Supabase.instance.client.auth.currentUser;
  if (user == null) return 'customer';
  
  final metadataRole = user.userMetadata?['role'];
  if (metadataRole != null) return metadataRole.toString();
  
  try {
    final profile = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();
    return profile['role'] ?? 'customer';
  } catch (_) {
    return 'customer';
  }
});

class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabTapped(String role, int index) {
    if (role == 'customer') {
      switch (index) {
        case 0:
          context.go('/customer_home');
          break;
        case 1:
          context.go('/my_projects');
          break;
        case 2:
          context.go('/chat_list');
          break;
        case 3:
          context.go('/profile_setup');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/leads');
          break;
        case 1:
          context.go('/contractor_quotes');
          break;
        case 2:
          context.go('/chat_list');
          break;
        case 3:
          context.go('/profile_setup');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);

    return roleAsync.when(
      data: (role) {
        final List<Widget> screens = role == 'customer'
            ? const [
                CustomerHomeScreen(),
                MyProjectsScreen(),
                ChatListScreen(),
                ProfileSetupScreen(),
              ]
            : const [
                LeadsFeedScreen(),
                ContractorQuotesScreen(),
                ChatListScreen(),
                ProfileSetupScreen(),
              ];

        final List<BottomNavigationBarItem> navItems = role == 'customer'
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Projects'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
                BottomNavigationBarItem(icon: Icon(Icons.request_quote), label: 'Quotes'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ];

        // Safeguard to prevent out-of-range indices
        final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            selectedItemColor: const Color(0xFF0284C7),
            unselectedItemColor: const Color(0xFF64748B),
            type: BottomNavigationBarType.fixed,
            items: navItems,
            onTap: (index) => _onTabTapped(role, index),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Text('Error resolving user role: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
