import 'package:date_and_doing/models/dd_date.dart';

enum ChatTimelineItemType {
  sectionHeader,
  dateCard,
  message,
}

class ChatTimelineItem {
  final ChatTimelineItemType type;
  final String? headerTitle;
  final DdDate? date;
  final Map<String, dynamic>? message;
  final DateTime sortAt;

  const ChatTimelineItem._({
    required this.type,
    required this.sortAt,
    this.headerTitle,
    this.date,
    this.message,
  });

  factory ChatTimelineItem.sectionHeader(String title, DateTime sortAt) {
    return ChatTimelineItem._(
      type: ChatTimelineItemType.sectionHeader,
      headerTitle: title,
      sortAt: sortAt,
    );
  }

  factory ChatTimelineItem.dateCard(DdDate date) {
    return ChatTimelineItem._(
      type: ChatTimelineItemType.dateCard,
      date: date,
      sortAt: date.createdAt ?? date.scheduledAt,
    );
  }

  factory ChatTimelineItem.message(Map<String, dynamic> message) {
    final dt = DateTime.tryParse(
          "${message["fecha"]}T${message["hora"]}:00",
        ) ??
        DateTime.now();

    return ChatTimelineItem._(
      type: ChatTimelineItemType.message,
      message: message,
      sortAt: dt,
    );
  }
}

class ChatTimelineBuilder {
  static List<ChatTimelineItem> build({
    required List<DdDate> dates,
    required List<Map<String, dynamic>> messages,
  }) {
    final items = <ChatTimelineItem>[
      ...dates.map(ChatTimelineItem.dateCard),
      ...messages.map(ChatTimelineItem.message),
    ];

    items.sort((a, b) => a.sortAt.compareTo(b.sortAt));
    return items;
  }
}