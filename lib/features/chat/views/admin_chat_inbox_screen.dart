// แสดงกล่องข้อความของลูกค้าสำหรับเจ้าของร้านเลือกเข้าไปตอบ
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class AdminChatInboxScreen extends StatefulWidget {
  const AdminChatInboxScreen({super.key});

  @override
  State<AdminChatInboxScreen> createState() => _AdminChatInboxScreenState();
}

class _AdminChatInboxScreenState extends State<AdminChatInboxScreen> {
  final ChatService _service = ChatService();
  late final Stream<List<Map<String, dynamic>>> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = _service.adminConversations();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('กล่องข้อความลูกค้า')),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _conversations,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('โหลดรายการแชทไม่ได้ กรุณาตรวจสิทธิ์และการเชื่อมต่อ'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final conversations = snapshot.data!;
        if (conversations.isEmpty) {
          return const Center(child: Text('ยังไม่มีข้อความจากลูกค้า'));
        }
        return ListView.separated(
          itemCount: conversations.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final id = conversation['id'].toString();
            final customerId = conversation['customer_id'].toString();
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text('ลูกค้า ${customerId.substring(0, 8)}'),
              subtitle: Text(
                conversation['status'] == 'open' ? 'กำลังสนทนา' : 'ปิดการสนทนา',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: conversation['status'] == 'open'
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(conversationId: id, isAdmin: true),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    ),
  );
}
