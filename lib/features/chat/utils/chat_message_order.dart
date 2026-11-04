class ChatMessageOrder {
  const ChatMessageOrder._();

  static List<Map<String, dynamic>> chronological(
    Iterable<Map<String, dynamic>> messages,
  ) {
    final ordered = messages.map(Map<String, dynamic>.from).toList();
    ordered.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
      if (aDate != null && bDate != null) {
        final byDate = aDate.compareTo(bDate);
        if (byDate != 0) return byDate;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
    });
    return ordered;
  }
}
