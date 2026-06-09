import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/screens/main_navigation_screen.dart';

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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Role')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoleCard(
                    context,
                    title: 'I am a Homeowner',
                    description:
                        'Post projects, hire contractors, and manage renovations.',
                    icon: Icons.house,
                    color: Colors.blue,
                    onTap: () => _selectRole('customer', '/customer_home'),
                  ),
                  const SizedBox(height: 24),
                  _buildRoleCard(
                    context,
                    title: 'I am a Contractor',
                    description:
                        'Find leads, send proposals, and grow your business.',
                    icon: Icons.handyman,
                    color: Colors.orange,
                    onTap: () => _selectRole('contractor', '/profile_setup'),
                  ),
                ],
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
