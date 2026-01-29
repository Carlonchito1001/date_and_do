import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Verifica y solicita permisos
  Future<bool> _ensurePermission() async {
    final status = await Permission.locationWhenInUse.status;

    if (status.isGranted) return true;

    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  Future<Position?> getCurrentPositionSafe() async {
    try {
      final hasPermission = await _ensurePermission();
      if (!hasPermission) {
        print('📍 Permiso de ubicación denegado');
        return null;
      }

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

      if (!isLocationEnabled) {
        print('📍 GPS desactivado');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      print(
        '📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      print('📍 Error obteniendo ubicación: $e');
      return null;
    }
  }
}
