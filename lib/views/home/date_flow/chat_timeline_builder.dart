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

  const ChatTimelineItem._({
    required this.type,
    this.headerTitle,
    this.date,
    this.message,
  });

  factory ChatTimelineItem.sectionHeader(String title) {
    return ChatTimelineItem._(
      type: ChatTimelineItemType.sectionHeader,
      headerTitle: title,
    );
  }

  factory ChatTimelineItem.dateCard(DdDate date) {
    return ChatTimelineItem._(
      type: ChatTimelineItemType.dateCard,
      date: date,
    );
  }

  factory ChatTimelineItem.message(Map<String, dynamic> message) {
    return ChatTimelineItem._(
      type: ChatTimelineItemType.message,
      message: message,
    );
  }
}

class ChatTimelineBuilder {
  static List<ChatTimelineItem> build({
    required List<DdDate> dates,
    required List<Map<String, dynamic>> messages,
  }) {
    final items = <ChatTimelineItem>[];

    if (dates.isNotEmpty) {
      items.add(ChatTimelineItem.sectionHeader("Próximas citas"));
      for (final d in dates) {
        items.add(ChatTimelineItem.dateCard(d));
      }
    }

    if (messages.isNotEmpty) {
      items.add(ChatTimelineItem.sectionHeader("Mensajes"));
      for (final m in messages) {
        items.add(ChatTimelineItem.message(m));
      }
    }

    return items;
  }
}