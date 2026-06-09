import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(Supabase.instance.client);
});

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, projectId) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.getMessages(projectId);
    });
