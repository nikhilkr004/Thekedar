import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  static final AnalyticsRepository instance = AnalyticsRepository._internal();
  
  AnalyticsRepository._internal();

  final _supabase = Supabase.instance.client;
  String? _sessionId;

  // Initialize a session ID
  void initSession() {
    _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Log an event to the Supabase database
  Future<void> logEvent(
    String eventType, 
    String screenName, {
    Map<String, dynamic>? metadata,
  }) async {
    initSession();
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      final payload = {
        'user_id': currentUserId, // UUID or null
        'screen_name': screenName,
        'session_id': _sessionId,
        'event_type': eventType,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Perform insert to Supabase analytics_events table
      await _supabase.from('analytics_events').insert(payload);
      dev.log('Analytics event logged: $eventType on $screenName');
    } catch (e) {
      dev.log('Failed to log analytics event: $e', error: e);
    }
  }
}
