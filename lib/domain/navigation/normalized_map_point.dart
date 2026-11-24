import 'dart:math' as math;

/// Punto 2D en coordenadas normalizadas [0, 1] sobre la imagen de un piso.
class NormalizedMapPoint {
  const NormalizedMapPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceSquaredTo(NormalizedMapPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double distanceTo(NormalizedMapPoint other) =>
      math.sqrt(distanceSquaredTo(other));

  /// Distancia tras escalar cada eje (p. ej. a píxeles del mapa).
  double scaledDistanceTo(
    NormalizedMapPoint other,
    double scaleX,
    double scaleY,
  ) {
    final dx = (x - other.x) * scaleX;
    final dy = (y - other.y) * scaleY;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) =>
      other is NormalizedMapPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      '(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)})';
}
