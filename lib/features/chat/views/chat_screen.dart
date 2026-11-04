import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../utils/chat_message_order.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final bool isAdmin;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.isAdmin = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _service = ChatService();
  final TextEditingController _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messages;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = _service.messages(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );
      _messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ChatService().currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'แชทกับลูกค้า' : 'แชทกับแอดมิน'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ChatMessageState(
                    icon: Icons.wifi_off,
                    text: 'โหลดข้อความไม่ได้ กรุณาตรวจการเชื่อมต่อและสิทธิ์แชท',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = ChatMessageOrder.chronological(
                  snapshot.data!,
                );
                if (messages.isEmpty) {
                  return const _ChatMessageState(
                    icon: Icons.chat_bubble_outline,
                    text: 'เริ่มต้นบทสนทนาได้เลย',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMine = message['sender_id'] == myId;
                    final createdAt = DateTime.tryParse(
                      message['created_at']?.toString() ?? '',
                    );
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: isMine
                              ? null
                              : Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message['body']?.toString() ?? '',
                              style: TextStyle(
                                color: isMine ? Colors.white : null,
                                fontSize: 16,
                              ),
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: isMine ? Colors.white70 : Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความ…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'ส่งข้อความ',
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChatMessageState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
