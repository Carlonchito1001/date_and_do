class ChatTimelineApiItem {
  final String itemType; // "message" | "event"
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const ChatTimelineApiItem({
    required this.itemType,
    required this.timestamp,
    required this.data,
  });

  factory ChatTimelineApiItem.fromJson(Map<String, dynamic> json) {
    return ChatTimelineApiItem(
      itemType: (json["item_type"] ?? "").toString(),
      timestamp: DateTime.tryParse(json["timestamp"]?.toString() ?? "") ??
          DateTime.now(),
      data: (json["data"] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  bool get isMessage => itemType == "message";
  bool get isEvent => itemType == "event";
}