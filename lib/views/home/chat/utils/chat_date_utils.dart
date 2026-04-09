import 'package:intl/intl.dart';

class ChatDateUtils {
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String formatSeparatorLabel(DateTime date) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (isSameDay(target, today)) return 'Hoy';
    if (isSameDay(target, yesterday)) return 'Ayer';

    return DateFormat("EEEE, d 'de' MMMM", 'es').format(target);
  }

  static bool shouldShowDateSeparator({
    required List<dynamic> timelineItems,
    required int realIndex,
    required DateTime Function(dynamic raw) safeParseToLocal,
  }) {
    final item = timelineItems[realIndex];

    if (item.type.toString() != 'ChatTimelineItemType.message') return false;

    final currentMsg = item.message!;
    final currentRaw = currentMsg['created_at_iso'] ?? currentMsg['fecha'];
    final currentDate = safeParseToLocal(currentRaw);

    if (realIndex == 0) return true;

    final previousItem = timelineItems[realIndex - 1];
    if (previousItem.type.toString() != 'ChatTimelineItemType.message') {
      return true;
    }

    final previousMsg = previousItem.message!;
    final previousRaw = previousMsg['created_at_iso'] ?? previousMsg['fecha'];
    final previousDate = safeParseToLocal(previousRaw);

    return !isSameDay(currentDate, previousDate);
  }
}