import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  // โหลดการแจ้งเตือนของผู้ใช้ที่ล็อกอินอยู่
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // นับจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน
  Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;

    if (user == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return response.length;
  }

  // ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(int notificationId) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', user.id);
  }
}
