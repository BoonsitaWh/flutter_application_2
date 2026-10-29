import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'โหลดการแจ้งเตือนไม่สำเร็จ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
  ) async {
    if (notification['is_read'] == true) return;

    try {
      await _service.markAsRead(
        (notification['id'] as num).toInt(),
      );

      if (!mounted) return;

      setState(() {
        notification['is_read'] = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 56,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('ยังไม่มีการแจ้งเตือน'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
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
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              item['message']?.toString() ?? '',
                            ),
                            trailing: isRead
                                ? null
                                : const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                            tileColor: isRead
                                ? null
                                : Colors.orange.withValues(
                                    alpha: 0.06,
                                  ),
                            onTap: () => _markAsRead(item),
                          );
                        },
                      ),
                    ),
    );
  }
}
