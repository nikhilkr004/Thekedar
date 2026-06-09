import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _supabase;

  ChatRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Stream<List<Map<String, dynamic>>> getMessages(String projectId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('project_id', projectId)
        .order('created_at', ascending: true);
  }

  @override
  Future<void> sendMessage({
    required String projectId,
    required String receiverId,
    required String content,
  }) async {
    await _supabase.from('messages').insert({
      'project_id': projectId,
      'sender_id': _userId,
      'receiver_id': receiverId,
      'content': content,
    });
  }
}
