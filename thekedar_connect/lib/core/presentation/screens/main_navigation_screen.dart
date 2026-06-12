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
import 'package:lottie/lottie.dart';
import '../../../features/contractor/presentation/providers/contractor_provider.dart';

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

  void _showVerificationDialog(BuildContext context, String status) {
    String title = 'Verification Pending';
    String message = 'Your account is currently under review. Please wait for admin approval.';
    String lottieUrl = 'https://lottie.host/575e9e04-d5cf-4df5-b98a-76192d19b6eb/s8U5YkR8eK.json';

    if (status == 'DRAFT' || status == 'PROFILE_INCOMPLETE') {
      title = 'Complete Profile';
      message = 'Please complete your profile details and documents to submit for verification.';
    } else if (status == 'REJECTED') {
      title = 'Verification Rejected';
      message = 'Your profile verification was rejected. Please review and update your information.';
    } else if (status == 'SUSPENDED' || status == 'BLOCKED') {
      title = 'Account Suspended';
      message = 'Your account has been suspended or blocked due to policy violations. Please contact support.';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Lottie.network(
                    lottieUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock,
                      size: 80,
                      color: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1E293B)
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF475569)
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14, 
                    color: Color(0xFF64748B), 
                    height: 1.4
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/profile_setup');
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Go to Profile Setup',
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      // For contractors, if they select index 0 (leads), 1 (quotes), or 2 (chat), verify status
      if (index != 3) {
        final profileAsync = ref.read(contractorProfileProvider);
        final profile = profileAsync.value;
        final status = profile?.status ?? 'DRAFT';
        
        if (status != 'APPROVED' && status != 'ACTIVE') {
          _showVerificationDialog(context, status);
          return;
        }
      }
      
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
    // Watch contractor profile to keep it active and updated in the cache
    ref.watch(contractorProfileProvider);

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
