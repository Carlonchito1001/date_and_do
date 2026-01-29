import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/location/location_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionBootstrapService {
  Future<void> ensureDeviceData() async {
    final sp = SharedPreferencesService();
    final userInfo = await sp.getUserInfo();
    if (userInfo == null) return;

    final userIdRaw = userInfo['use_int_id'];
    if (userIdRaw == null) return;

    final int userId = (userIdRaw as num).toInt();

    final lat = userInfo['use_double_latitude'];
    final lng = userInfo['use_double_longitude'];
    final bool needsLocation = lat == null || lng == null;

    final prefs = await SharedPreferences.getInstance();
    final String? fcmTokenRaw = prefs.getString(
      SharedPreferencesService.fcmToken,
    );
    final String? fcmToken =
        (fcmTokenRaw != null && fcmTokenRaw.trim().isNotEmpty)
        ? fcmTokenRaw.trim()
        : null;

    double? latitude;
    double? longitude;

    if (needsLocation) {
      final gps = await LocationService().getCurrentPositionSafe();
      if (gps != null) {
        latitude = double.parse(gps.latitude.toStringAsFixed(4));
        longitude = double.parse(gps.longitude.toStringAsFixed(4));
      }
    }

    if (fcmToken == null && latitude == null && longitude == null) return;

    try {
      await ApiService().patchUserDevice(
        userId: userId,
        fcmToken: fcmToken,
        latitude: latitude,
        longitude: longitude,
      );

      final access = await sp.getAccessToken();
      if (access != null && access.isNotEmpty) {
        final refreshed = await ApiService().infoUser(accessToken: access);
        await sp.saveUserInfo(refreshed);
      }
    } catch (_) {}
  }
}
