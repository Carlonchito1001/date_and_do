typedef AsyncVoidCallback = Future<void> Function();

class ChatDateRefreshHelper {
  static Future<void> refreshAll({
    required AsyncVoidCallback loadDates,
    AsyncVoidCallback? loadAliniStatus,
  }) async {
    await loadDates();

    if (loadAliniStatus != null) {
      await loadAliniStatus();
    }
  }
}