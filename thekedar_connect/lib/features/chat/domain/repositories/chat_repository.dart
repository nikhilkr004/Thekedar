abstract class ChatRepository {
  Stream<List<Map<String, dynamic>>> getMessages(String projectId);
  Future<void> sendMessage({
    required String projectId,
    required String receiverId,
    required String content,
  });
}
