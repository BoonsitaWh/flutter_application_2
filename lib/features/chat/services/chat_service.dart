// ติดต่อ Supabase เพื่อเปิดห้อง สนทนา ส่ง แก้ไข และลบข้อความ
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้แชท');
    return user.id;
  }

  Future<String> getOrCreateCustomerConversation() async {
    final userId = _userId;
    final existing = await _client
        .from('chat_conversations')
        .select('id')
        .eq('customer_id', userId)
        .eq('status', 'open')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) return existing['id'].toString();

    final created = await _client
        .from('chat_conversations')
        .insert({'customer_id': userId})
        .select('id')
        .single();
    return created['id'].toString();
  }

  Stream<List<Map<String, dynamic>>> customerConversations() => _client
      .from('chat_conversations')
      .stream(primaryKey: ['id'])
      .eq('customer_id', _userId)
      .order('updated_at', ascending: false);

  Stream<List<Map<String, dynamic>>> adminConversations() => _client
      .from('chat_conversations')
      .stream(primaryKey: ['id'])
      .order('updated_at', ascending: false);

  Stream<List<Map<String, dynamic>>> messages(String conversationId) => _client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at');

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return;
    if (body.length > 2000) throw Exception('ข้อความยาวเกิน 2,000 ตัวอักษร');

    await _client.from('chat_messages').insert({
      'conversation_id': conversationId,
      'sender_id': _userId,
      'body': body,
    });
  }

  Future<void> updateMessage({
    required String messageId,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) throw Exception('ข้อความห้ามเว้นว่าง');
    if (body.length > 2000) throw Exception('ข้อความยาวเกิน 2,000 ตัวอักษร');

    final updatedRows = await _client
        .from('chat_messages')
        .update({
          'body': body,
          'edited_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', _userId)
        .select('id');

    if (updatedRows.isEmpty) {
      throw Exception('แก้ไขได้เฉพาะข้อความของคุณในห้องแชทที่ยังเปิดอยู่');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final deletedRows = await _client
        .from('chat_messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', _userId)
        .select('id');

    if (deletedRows.isEmpty) {
      throw Exception('ลบได้เฉพาะข้อความของคุณในห้องแชทที่ยังเปิดอยู่');
    }
  }
}
