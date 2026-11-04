// แสดงการแจ้งเตือนและปรับสถานะเป็นอ่านแล้วเมื่อผู้ใช้เปิดรายการ
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  late Stream<List<Map<String, dynamic>>> _notificationStream;

  @override
  void initState() {
    super.initState();
    _notificationStream = _service.watchNotifications();
  }

  void _refresh() {
    setState(() => _notificationStream = _service.watchNotifications());
  }

  Future<void> _markAsRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    try {
      await _service.markAsRead((notification['id'] as num).toInt());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          IconButton(
            tooltip: 'โหลดการแจ้งเตือนใหม่',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _messageState(
              icon: Icons.notifications_off_outlined,
              message: 'โหลดการแจ้งเตือนไม่สำเร็จ: ${snapshot.error}',
              action: TextButton(
                onPressed: _refresh,
                child: const Text('ลองอีกครั้ง'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return _messageState(
              icon: Icons.notifications_none,
              message: 'ยังไม่มีการแจ้งเตือน',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final isRead = item['is_read'] == true;
                return ListTile(
                  leading: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: isRead
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    item['title']?.toString() ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(item['message']?.toString() ?? ''),
                  trailing: isRead
                      ? null
                      : const Icon(
                          Icons.circle,
                          size: 10,
                          color: Colors.orange,
                        ),
                  tileColor: isRead
                      ? null
                      : Colors.orange.withValues(alpha: 0.06),
                  onTap: () => _markAsRead(item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String message,
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
