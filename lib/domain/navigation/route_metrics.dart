import 'route_models.dart';

/// Distancia y tiempo estimados de una ruta.
class RouteMetrics {
  const RouteMetrics({required this.meters, required this.seconds});
  final int meters;
  final int seconds;

  int get minutes => (seconds / 60).ceil().clamp(1, 1 << 30);
}

/// Calibración física de los planos (de `MapScaleCalibration.kt`).
///
/// - PB: 3.33 px del frame 1260 × 1600 = 1 m.
/// - P1 y P2 están ampliados ×2 respecto a PB: 0.15 m/px.
/// - Caminata a 1.2 m/s; cada cambio de piso suma ~7 m y ~18 s de escalera.
abstract final class RouteMetricsCalculator {
  static const double pbMetersPerPixel = 1 / 3.33;
  static const double upperFloorMetersPerPixel = pbMetersPerPixel / 2;
  static const double walkingSpeed = 1.2;
  static const double stairMetersPerFloor = 7;
  static const double stairSecondsPerFloor = 18;

  static double metersPerPixel(String floorId) =>
      floorId == 'PB' ? pbMetersPerPixel : upperFloorMetersPerPixel;

  static RouteMetrics estimate(RouteResult route) {
    var horizontal = 0.0;
    for (final segment in route.segments) {
      horizontal += segment.cost * metersPerPixel(segment.floorId);
    }
    final floors = route.transitions.length;
    final meters = horizontal + floors * stairMetersPerFloor;
    final seconds = horizontal / walkingSpeed + floors * stairSecondsPerFloor;
    return RouteMetrics(meters: meters.round(), seconds: seconds.round());
  }
}
