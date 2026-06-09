import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/analytics/analytics_repository.dart';

import 'core/notifications/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase. For local development or remote connection.
  // Replace with actual keys when available.
  await Supabase.initialize(
    url: 'https://eswjtunzibrhimcpcnss.supabase.co',
    anonKey:
        'sb_publishable_8mCUlHYxLAUhM9MYQ68Q2Q_b24pi85s',
  );

  // Initialize Firebase Cloud Messaging
  await FcmService.instance.initialize();

  // Log startup event
  await AnalyticsRepository.instance.logEvent('session_start', 'app_launch');

  runApp(const ProviderScope(child: ThekedarConnectApp()));
}

class ThekedarConnectApp extends ConsumerWidget {
  const ThekedarConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final themeAsync = ref.watch(dynamicThemeProvider);

    return MaterialApp.router(
      title: 'Thekedar Connect',
      theme: themeAsync.value ?? AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
