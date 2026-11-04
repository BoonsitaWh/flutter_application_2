// แสดงบทสนทนาแบบเรียลไทม์ พร้อมส่ง แก้ไข และลบข้อความของตัวเอง
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
  final Set<String> _deletedMessageIds = <String>{};
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

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final controller = TextEditingController(
      text: message['body']?.toString() ?? '',
    );
    final editedText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขข้อความ'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'ข้อความ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (editedText == null || editedText.trim() == message['body']) return;

    try {
      await _service.updateMessage(
        messageId: message['id'].toString(),
        text: editedText,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('แก้ไขข้อความไม่สำเร็จ: $error')));
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบข้อความ'),
        content: const Text('ต้องการลบข้อความนี้ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final messageId = message['id'].toString();
      await _service.deleteMessage(messageId);
      if (mounted) {
        setState(() => _deletedMessageIds.add(messageId));
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบข้อความไม่สำเร็จ: $error')));
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
                  snapshot.data!
                      .where(
                        (message) => !_deletedMessageIds.contains(
                          message['id'].toString(),
                        ),
                      )
                      .toList(growable: false),
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
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message['edited_at'] != null) ...[
                                  Text(
                                    'แก้ไขแล้ว',
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (createdAt != null)
                                  Text(
                                    '${createdAt.toLocal().hour.toString().padLeft(2, '0')}:${createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (isMine)
                                  PopupMenuButton<String>(
                                    tooltip: 'จัดการข้อความ',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 36,
                                    ),
                                    iconSize: 18,
                                    icon: Icon(
                                      Icons.more_horiz,
                                      color: isMine
                                          ? Colors.white70
                                          : Colors.grey,
                                    ),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _editMessage(message);
                                      } else if (action == 'delete') {
                                        _deleteMessage(message);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('แก้ไขข้อความ'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('ลบข้อความ'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
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
