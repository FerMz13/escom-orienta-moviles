import 'package:geolocator/geolocator.dart';

/// Resultado de una consulta de ubicación.
sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  const LocationSuccess(this.latitude, this.longitude, this.accuracyMeters);
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class LocationDenied extends LocationResult {
  const LocationDenied(this.message);
  final String message;
}

/// Integración opcional con GPS (RF3). Se usa para mostrar la ubicación actual
/// del dispositivo (demostración de sensor); el mapa interno de ESCOM no está
/// georreferenciado, por lo que no se traza ruta a partir del GPS.
class LocationService {
  const LocationService();

  Future<LocationResult> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationDenied('Activa el GPS del dispositivo para continuar.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationDenied('Permiso de ubicación denegado.');
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationDenied(
        'Permiso de ubicación bloqueado. Habilítalo en los ajustes del sistema.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LocationSuccess(position.latitude, position.longitude, position.accuracy);
    } catch (e) {
      return LocationDenied('No se pudo obtener la ubicación: $e');
    }
  }
}
