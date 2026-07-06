import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/localization/locale_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/design_system.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final localeState = ref.read(localeProvider);
    if (!localeState.hasSelectedLanguage) {
      context.go('/language');
      return;
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final role = session.user.userMetadata?['role'];
      if (role == 'customer') {
        context.go('/customer_home');
      } else if (role == 'contractor') {
        context.go('/leads');
      } else {
        context.go('/role');
      }
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: AppShadows.darkCardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Thekedar Connect',
              style: AppTypography.title.copyWith(fontSize: 24, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
