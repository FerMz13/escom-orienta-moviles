import '../map/map_models.dart';
import 'normalized_map_point.dart';

/// Origen o destino de una ruta.
sealed class RouteEndpoint {
  const RouteEndpoint();
}

class PlaceEndpoint extends RouteEndpoint {
  const PlaceEndpoint(this.place);
  final MapPlace place;
}

class PlaceIdEndpoint extends RouteEndpoint {
  const PlaceIdEndpoint(this.placeId);
  final String placeId;
}

/// Punto elegido manualmente por el usuario sobre el mapa de un piso.
class ManualPointEndpoint extends RouteEndpoint {
  const ManualPointEndpoint({required this.floorId, required this.point});
  final String floorId;
  final NormalizedMapPoint point;
}

class NoEndpoint extends RouteEndpoint {
  const NoEndpoint();
}

/// Tramo continuo de la ruta dentro de un piso.
class RouteSegment {
  const RouteSegment({
    required this.floorId,
    required this.points,
    this.cost = 0,
  });

  final String floorId;
  final List<NormalizedMapPoint> points;

  /// Costo en píxeles del sistema de coordenadas del piso.
  final double cost;
}

/// Cambio de piso por escaleras.
class RouteTransition {
  const RouteTransition({
    required this.connectorId,
    required this.fromFloorId,
    required this.toFloorId,
    required this.stairNodeId,
    required this.point,
  });

  final String connectorId;
  final String fromFloorId;
  final String toFloorId;

  /// Nodo de escalera en [fromFloorId].
  final String stairNodeId;
  final NormalizedMapPoint point;
}

/// Resultado del cálculo de una ruta.
class RouteResult {
  const RouteResult({
    required this.success,
    this.origin = const NoEndpoint(),
    this.destination = const NoEndpoint(),
    this.segments = const [],
    this.transitions = const [],
    this.totalCost = 0,
    this.errorMessage,
  });

  const RouteResult.failure(String message)
      : this(success: false, errorMessage: message);

  final bool success;
  final RouteEndpoint origin;
  final RouteEndpoint destination;
  final List<RouteSegment> segments;
  final List<RouteTransition> transitions;
  final double totalCost;
  final String? errorMessage;

  bool get isMultiFloor => transitions.isNotEmpty;

  /// Puntos a dibujar por piso.
  Map<String, List<NormalizedMapPoint>> get pointsByFloor =>
      {for (final s in segments) s.floorId: s.points};

  RouteResult withEndpoints(RouteEndpoint origin, RouteEndpoint destination) =>
      RouteResult(
        success: success,
        origin: origin,
        destination: destination,
        segments: segments,
        transitions: transitions,
        totalCost: totalCost,
        errorMessage: errorMessage,
      );
}
