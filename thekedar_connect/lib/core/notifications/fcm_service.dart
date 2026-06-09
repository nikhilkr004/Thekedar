import 'dart:io';
import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If background initialization is required, do it here.
  dev.log('Handling background notification payload: ${message.messageId}');
}

class FcmService {
  static final FcmService instance = FcmService._internal();

  FcmService._internal();

  final _supabase = Supabase.instance.client;

  // Initialize Firebase and messaging listeners
  Future<void> initialize() async {
    try {
      // 1. Initialize Firebase app (if not already initialized by platform configs)
      await Firebase.initializeApp();
      
      // 2. Setup background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request permissions for iOS / Android 13+
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      dev.log('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 4. Retrieve FCM Token and sync with database
        await syncToken();

        // 5. Watch for token updates
        messaging.onTokenRefresh.listen((token) async {
          dev.log('FCM token refreshed: $token');
          await _saveTokenToDatabase(token);
        });

        // 6. Foreground message listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          dev.log('Received foreground message: ${message.notification?.title}');
          // Note: In foreground, Flutter does not automatically show head-up notification alerts.
          // You can show a custom snackbar, local notification popup, or dispatch UI events.
        });

        // 7. Handle notification taps when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          dev.log('App opened via notification tap: ${message.data}');
          _handleNotificationRouting(message.data);
        });

        // 8. Handle terminated state initial message tap
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          dev.log('App launched from terminated state via notification: ${initialMessage.data}');
          _handleNotificationRouting(initialMessage.data);
        }
      }
    } catch (e) {
      dev.log('Failed to initialize FCM Service: $e', error: e);
    }
  }

  // Fetch current token and save to database
  Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        dev.log('Current FCM Device Token: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      dev.log('Error syncing FCM token: $e');
    }
  }

  // Save the device details and token to the user_devices table in Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get device parameters
      final platformName = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      final deviceName = Platform.localHostname;

      // Upsert record to public.user_devices table
      await _supabase.from('user_devices').upsert({
        'user_id': currentUser.id,
        'fcm_token': token,
        'device_name': deviceName,
        'platform': platformName,
        'is_active': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');

      dev.log('Device FCM token successfully synced to Supabase database.');
    } catch (e) {
      dev.log('Failed to save FCM token to Supabase: $e', error: e);
    }
  }

  // Remove device token on sign out
  Future<void> deleteToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _supabase.from('user_devices').delete().eq('fcm_token', token);
        dev.log('FCM token deleted from database on sign out.');
      }
    } catch (e) {
      dev.log('Error deleting token on sign out: $e');
    }
  }

  // Routing actions when tapping push notifications (Deep Links)
  void _handleNotificationRouting(Map<String, dynamic> data) {
    // Read route path or type from notification payload data
    final route = data['click_action'] ?? data['route'];
    if (route != null) {
      // Dispatch routing request (GoRouter paths, etc.)
      dev.log('Requesting navigation route: $route');
    }
  }
}
