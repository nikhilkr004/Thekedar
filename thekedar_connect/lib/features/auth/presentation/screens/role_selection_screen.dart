import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/screens/main_navigation_screen.dart';
import '../../../../core/theme/design_system.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isLoading = false;

  Future<void> _selectRole(String role, String nextRoute) async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final name = user.userMetadata?['full_name'] ?? 'Google User';
        final email = user.email ?? '';
        final phone = (user.phone != null && user.phone!.isNotEmpty) ? user.phone! : '0000000000';
        
        await Supabase.instance.client.from('users').upsert({
          'id': user.id,
          'role': role,
          'email': email,
          'full_name': name,
          'phone': phone,
        });
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'role': role}),
      );
      ref.invalidate(userRoleProvider);
      if (mounted) context.go(nextRoute);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Text(
          'Choose Your Role',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoleCard(
                        context,
                        title: 'I am a Homeowner',
                        description: 'Post projects, hire contractors, and manage renovations.',
                        icon: Icons.house,
                        color: AppColors.primaryLight,
                        onTap: () => _selectRole('customer', '/customer_home'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRoleCard(
                        context,
                        title: 'I am a Contractor',
                        description: 'Find leads, send proposals, and grow your business.',
                        icon: AppIcons.handyman,
                        color: AppColors.secondary,
                        onTap: () => _selectRole('contractor', '/profile_setup'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: AppShadows.darkCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
