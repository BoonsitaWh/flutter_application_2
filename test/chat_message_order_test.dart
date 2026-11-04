import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/chat/utils/chat_message_order.dart';

void main() {
  group('ChatMessageOrder.chronological', () {
    test('puts the earliest message first even if the stream is descending', () {
      final messages = ChatMessageOrder.chronological([
        {'id': '2', 'body': 'second', 'created_at': '2026-11-04T14:44:00Z'},
        {'id': '1', 'body': 'first', 'created_at': '2026-11-04T13:56:00Z'},
      ]);

      expect(messages.map((message) => message['body']), ['first', 'second']);
    });

    test('uses id as a stable tie breaker for messages with equal times', () {
      final messages = ChatMessageOrder.chronological([
        {'id': 'b', 'created_at': '2026-11-04T13:56:00Z'},
        {'id': 'a', 'created_at': '2026-11-04T13:56:00Z'},
      ]);

      expect(messages.map((message) => message['id']), ['a', 'b']);
    });
  });
}
