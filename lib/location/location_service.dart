import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> _ensurePermission() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    status = await Permission.locationWhenInUse.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    return false;
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

      // 1) Primero intentamos obtener la última ubicación conocida.
      // Esto evita bloquear el registro si el GPS demora demasiado.
      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        print(
          '📍 Última ubicación conocida: ${lastPosition.latitude}, ${lastPosition.longitude}',
        );

        // Mientras usamos la última ubicación, intentamos actualizar en segundo plano.
        _refreshLocationInBackground();

        return lastPosition;
      }

      // 2) Si no hay última ubicación, intentamos con precisión media.
      // Es más rápido que high y suficiente para mostrar sugerencias por distancia.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      print(
        '📍 Ubicación obtenida: ${position.latitude}, ${position.longitude}',
      );

      return position;
    } catch (e) {
      print('📍 Error obteniendo ubicación: $e');

      try {
        // 3) Último intento: baja precisión, suele responder más rápido.
        final fallback = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 12),
        );

        print(
          '📍 Ubicación fallback obtenida: ${fallback.latitude}, ${fallback.longitude}',
        );

        return fallback;
      } catch (e2) {
        print('📍 Error obteniendo ubicación fallback: $e2');
        return null;
      }
    }
  }

  Future<void> _refreshLocationInBackground() async {
    try {
      final fresh = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      print(
        '📍 Ubicación actualizada en segundo plano: ${fresh.latitude}, ${fresh.longitude}',
      );
    } catch (e) {
      print('📍 No se pudo actualizar ubicación en segundo plano: $e');
    }
  }
}
