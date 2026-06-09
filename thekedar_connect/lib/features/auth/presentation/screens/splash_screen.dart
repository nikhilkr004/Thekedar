import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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
    // Add a small delay so the splash screen is visible
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
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

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Thekedar Connect',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
