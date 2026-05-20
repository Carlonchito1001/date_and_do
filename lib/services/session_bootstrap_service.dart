import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/location/location_service.dart';
import 'package:date_and_doing/services/fcm_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';

class SessionBootstrapService {
  Future<void> ensureDeviceData() async {
    final sp = SharedPreferencesService();

    final userInfo = await sp.getUserInfo();
    if (userInfo == null) return;

    final userId = _toIntSafe(userInfo['use_int_id']);

    if (userId == null || userId <= 0) return;

    final lat = userInfo['use_double_latitude'];
    final lng = userInfo['use_double_longitude'];

    final bool needsLocation = lat == null || lng == null;

    double? latitude;
    double? longitude;

    if (needsLocation) {
      final gps = await LocationService().getCurrentPositionSafe();

      if (gps != null) {
        latitude = double.parse(gps.latitude.toStringAsFixed(4));
        longitude = double.parse(gps.longitude.toStringAsFixed(4));
      }
    }

    try {
      await FcmService.syncTokenWithBackendIfPossible();
    } catch (_) {}

    if (latitude == null && longitude == null) return;

    try {
      await ApiService().patchUserDevice(
        userId: userId,
        fcmToken: null,
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

  int? _toIntSafe(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}
