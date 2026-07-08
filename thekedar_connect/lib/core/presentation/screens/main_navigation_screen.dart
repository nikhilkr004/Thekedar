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
import '../../theme/design_system.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
          backgroundColor: AppColors.darkDialog,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
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
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    status,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary, 
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/profile_setup');
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Go to Profile Setup',
                      style: AppTypography.button.copyWith(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
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

        final safeIndex = _currentIndex < screens.length ? _currentIndex : 0;

        Widget buildSidebar(String role) {
          return Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.darkSurface,
              border: Border(right: BorderSide(color: AppColors.darkBorder, width: 1.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: const Icon(AppIcons.handyman, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thekedar',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, idx) {
                      final item = navItems[idx];
                      final isActive = idx == safeIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: InkWell(
                          onTap: () => _onTabTapped(role, idx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  (item.icon as Icon).icon,
                                  color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  item.label ?? '',
                                  style: TextStyle(
                                    color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.darkBorder),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton.icon(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) context.go('/auth');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                    label: const Text('Log out', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildNavigationRail(String role) {
          return NavigationRail(
            selectedIndex: safeIndex,
            backgroundColor: AppColors.darkSurface,
            selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
            unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
            selectedLabelTextStyle: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            onDestinationSelected: (index) => _onTabTapped(role, index),
            labelType: NavigationRailLabelType.all,
            destinations: navItems.map((item) {
              return NavigationRailDestination(
                icon: item.icon,
                label: Text(item.label ?? ''),
              );
            }).toList(),
          );
        }

        final double screenWidth = MediaQuery.of(context).size.width;

        if (screenWidth > 900) {
          return Scaffold(
            body: Row(
              children: [
                buildSidebar(role),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        } else if (screenWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                buildNavigationRail(role),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: IndexedStack(
              index: safeIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: safeIndex,
              selectedItemColor: AppColors.primaryLight,
              unselectedItemColor: AppColors.textMuted,
              backgroundColor: AppColors.darkSurface,
              type: BottomNavigationBarType.fixed,
              items: navItems,
              onTap: (index) => _onTabTapped(role, index),
            ),
          );
        }
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text('Error resolving user role: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}
