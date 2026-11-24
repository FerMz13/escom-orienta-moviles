import '../../domain/map/map_floor_catalog.dart';
import '../../domain/map/map_models.dart';
import '../../domain/navigation/a_star_route_finder.dart';
import '../../domain/navigation/normalized_map_point.dart';
import '../../domain/navigation/route_calculation_service.dart';
import '../../domain/navigation/route_models.dart';
import 'map_repository.dart';

/// Implementación del cálculo de rutas portada de
/// `DefaultRouteCalculationService.kt`.
///
/// - Mismo piso: A* entre las puertas del origen y del destino.
/// - Varios pisos: prueba cada conector de escaleras de
///   [MapFloorCatalog.stairNodeIdsByConnector] que exista en todos los pisos
///   recorridos y se queda con el de menor costo total.
class DefaultRouteCalculationService implements RouteCalculationService {
  DefaultRouteCalculationService(this._repository);

  final MapRepository _repository;

  @override
  Future<RouteResult> calculateRouteByIds(
    String originPlaceId,
    String destinationPlaceId, {
    bool accessibleOnly = false,
  }) =>
      calculateRoute(
        PlaceIdEndpoint(originPlaceId),
        PlaceIdEndpoint(destinationPlaceId),
        accessibleOnly: accessibleOnly,
      );

  @override
  Future<RouteResult> calculateRoute(
    RouteEndpoint origin,
    RouteEndpoint destination, {
    bool accessibleOnly = false,
  }) async {
    await _repository.ensureLoaded();

    final destinationPlace = switch (destination) {
      PlaceEndpoint(:final place) => place,
      PlaceIdEndpoint(:final placeId) => _repository.placeById(placeId),
      _ => null,
    };
    if (destinationPlace == null) {
      return const RouteResult.failure('Destino inválido o no encontrado');
    }

    final MapPlace? originPlace;
    final NormalizedMapPoint? originPoint;
    final String? originFloorId;
    switch (origin) {
      case PlaceEndpoint(:final place):
        (originPlace, originPoint, originFloorId) =
            (place, place.centerPoint, place.floorId);
      case PlaceIdEndpoint(:final placeId):
        final place = _repository.placeById(placeId);
        (originPlace, originPoint, originFloorId) =
            (place, place?.centerPoint, place?.floorId);
      case ManualPointEndpoint(:final floorId, :final point):
        (originPlace, originPoint, originFloorId) = (null, point, floorId);
      case NoEndpoint():
        (originPlace, originPoint, originFloorId) = (null, null, null);
    }
    if (originPoint == null || originFloorId == null) {
      return const RouteResult.failure('Origen inválido o no encontrado');
    }

    return calculateRouteWithGraphs(
      graphsByFloor: _repository.graphsByFloor,
      accessDataByFloor: _repository.accessDataByFloor,
      originFloorId: originFloorId,
      originPoint: originPoint,
      originPlace: originPlace,
      destinationPlace: destinationPlace,
      accessibleOnly: accessibleOnly,
    ).withEndpoints(origin, destination);
  }

  @override
  RouteResult calculateRouteWithGraphs({
    required Map<String, MapNavigationGraph> graphsByFloor,
    required Map<String, MapFloorAccessData> accessDataByFloor,
    required String originFloorId,
    required NormalizedMapPoint originPoint,
    MapPlace? originPlace,
    required MapPlace destinationPlace,
    bool accessibleOnly = false,
  }) {
    final destinationFloorId = destinationPlace.floorId;
    final originGraph = graphsByFloor[originFloorId];
    if (originGraph == null) {
      return RouteResult.failure(
          'Grafo no disponible para el piso de origen: $originFloorId');
    }
    final destinationGraph = graphsByFloor[destinationFloorId];
    if (destinationGraph == null) {
      return RouteResult.failure(
          'Grafo no disponible para el piso de destino: $destinationFloorId');
    }

    final originCandidates = originPlace != null
        ? buildEndpointCandidates(
            originPlace, originGraph, accessDataByFloor[originFloorId])
        : [?_manualCandidate(originPoint, originGraph)];
    final destinationCandidates = buildEndpointCandidates(
      destinationPlace,
      destinationGraph,
      accessDataByFloor[destinationFloorId],
    );
    if (originCandidates.isEmpty) {
      return const RouteResult.failure('El origen no tiene acceso al grafo');
    }
    if (destinationCandidates.isEmpty) {
      return const RouteResult.failure('El destino no tiene acceso al grafo');
    }

    // Caso 1: mismo piso.
    if (originFloorId == destinationFloorId) {
      final finder = AStarRouteFinder(originGraph, accessibleOnly: accessibleOnly);
      _FloorRoute? best;
      for (final o in originCandidates) {
        for (final d in destinationCandidates) {
          final path = finder.findPath(o.graphNodeId, d.graphNodeId);
          if (path == null) continue;
          final cost = o.connectorCost + path.cost + d.connectorCost;
          if (best == null || cost < best.cost) {
            best = _FloorRoute(
              _distinctConsecutive([
                ...o.pointsToGraph(originGraph),
                for (final id in path.nodeIds)
                  originGraph.normalize(originGraph.nodesById[id]!),
                ...d.pointsFromGraph(originGraph),
              ]),
              cost,
            );
          }
        }
      }
      if (best == null) {
        return const RouteResult.failure('No se encontró ruta en el mismo piso');
      }
      return RouteResult(
        success: true,
        segments: [
          RouteSegment(floorId: originFloorId, points: best.points, cost: best.cost),
        ],
        totalCost: best.cost,
      );
    }

    // Caso 2: varios pisos.
    if (accessibleOnly) {
      // Los datos no incluyen elevadores ni rampas entre pisos.
      return const RouteResult.failure(
          'No hay una ruta accesible (sin escaleras) entre pisos distintos');
    }

    final originLevel = MapFloorCatalog.levelOf(originFloorId);
    final destinationLevel = MapFloorCatalog.levelOf(destinationFloorId);
    if (originLevel < 0 || destinationLevel < 0) {
      return const RouteResult.failure('Índices de piso inválidos');
    }
    final step = destinationLevel > originLevel ? 1 : -1;
    final traversedFloorIds = [
      for (var i = originLevel; i != destinationLevel + step; i += step)
        MapFloorCatalog.floorIds[i],
    ];
    for (final floorId in traversedFloorIds) {
      if (!graphsByFloor.containsKey(floorId)) {
        return RouteResult.failure('Grafo intermedio no disponible para $floorId');
      }
    }

    final originFinder = AStarRouteFinder(originGraph);
    final destinationFinder = AStarRouteFinder(destinationGraph);

    _MultiFloorRoute? best;
    for (final MapEntry(key: connectorId, value: nodeIdsByFloor)
        in MapFloorCatalog.stairNodeIdsByConnector.entries) {
      final stairsByFloor = <String, MapNavigationNode>{};
      for (final floorId in traversedFloorIds) {
        final node = graphsByFloor[floorId]!.nodesById[nodeIdsByFloor[floorId]];
        if (node == null || !node.isStairs) break;
        stairsByFloor[floorId] = node;
      }
      if (stairsByFloor.length != traversedFloorIds.length) continue;

      // El costo total es la suma de ambos tramos, así que cada lado se
      // optimiza de forma independiente.
      final originSide = _bestLeg(
        originFinder,
        originCandidates,
        stairsByFloor[originFloorId]!.id,
        towardsStairs: true,
      );
      final destinationSide = _bestLeg(
        destinationFinder,
        destinationCandidates,
        stairsByFloor[destinationFloorId]!.id,
        towardsStairs: false,
      );
      if (originSide == null || destinationSide == null) continue;

      final total = originSide.cost + destinationSide.cost;
      if (best == null || total < best.totalCost) {
        best = _MultiFloorRoute(
          connectorId: connectorId,
          stairsByFloor: stairsByFloor,
          origin: originSide,
          destination: destinationSide,
        );
      }
    }
    if (best == null) {
      return const RouteResult.failure('No se encontró conexión entre pisos');
    }

    final route = best;
    final segments = <RouteSegment>[
      for (final floorId in traversedFloorIds)
        if (floorId == originFloorId)
          RouteSegment(
            floorId: floorId,
            points: route.origin.points(originGraph),
            cost: route.origin.cost,
          )
        else if (floorId == destinationFloorId)
          RouteSegment(
            floorId: floorId,
            points: route.destination.points(destinationGraph),
            cost: route.destination.cost,
          )
        else
          RouteSegment(
            floorId: floorId,
            points: [
              graphsByFloor[floorId]!.normalize(route.stairsByFloor[floorId]!),
            ],
          ),
    ];

    final transitions = [
      for (var i = 0; i < traversedFloorIds.length - 1; i++)
        RouteTransition(
          connectorId: route.connectorId,
          fromFloorId: traversedFloorIds[i],
          toFloorId: traversedFloorIds[i + 1],
          stairNodeId: route.stairsByFloor[traversedFloorIds[i]]!.id,
          point: graphsByFloor[traversedFloorIds[i]]!
              .normalize(route.stairsByFloor[traversedFloorIds[i]]!),
        ),
    ];

    return RouteResult(
      success: true,
      segments: segments,
      transitions: transitions,
      totalCost: route.totalCost,
    );
  }

  /// Mejor tramo entre una puerta del lugar y el nodo de escaleras.
  _Leg? _bestLeg(
    AStarRouteFinder finder,
    List<RouteEndpointCandidate> candidates,
    String stairNodeId, {
    required bool towardsStairs,
  }) {
    _Leg? best;
    for (final candidate in candidates) {
      final path = towardsStairs
          ? finder.findPath(candidate.graphNodeId, stairNodeId)
          : finder.findPath(stairNodeId, candidate.graphNodeId);
      if (path == null) continue;
      final cost = candidate.connectorCost + path.cost;
      if (best == null || cost < best.cost) {
        best = _Leg(candidate, path, cost, towardsStairs);
      }
    }
    return best;
  }

  /// Candidatos de conexión de un lugar al grafo.
  ///
  /// Usa las puertas de `accesos_<piso>.json` si existen; si no, el
  /// `navigationNodeId` del lugar o, en último caso, el nodo de pasillo más
  /// cercano a su centro.
  List<RouteEndpointCandidate> buildEndpointCandidates(
    MapPlace place,
    MapNavigationGraph graph,
    MapFloorAccessData? accessData,
  ) {
    final location = place.centerPoint;
    if (location == null) return const [];

    final accessPoints = accessData?.accessPointsByPlaceId[place.id];
    if (accessData != null && accessPoints != null) {
      final explicit = <RouteEndpointCandidate>[
        for (final ap in accessPoints)
          for (final nodeId in ap.graphNodeIds)
            if (graph.nodesById[nodeId] case final node?)
              () {
                final apPoint = accessData.normalize(ap);
                return RouteEndpointCandidate(
                  graphNodeId: nodeId,
                  locationPoint: location,
                  accessPoint: apPoint,
                  connectorCost: graph.pixelDistance(apPoint, graph.normalize(node)),
                  usesExplicitAccess: true,
                );
              }(),
      ];
      if (explicit.isNotEmpty) return explicit;
    }

    final node = graph.nodesById[place.navigationNodeId] ??
        _nearestPathNode(location, graph);
    if (node == null) return const [];
    return [
      RouteEndpointCandidate(
        graphNodeId: node.id,
        locationPoint: location,
        accessPoint: location,
        connectorCost: graph.pixelDistance(location, graph.normalize(node)),
      ),
    ];
  }

  RouteEndpointCandidate? _manualCandidate(
    NormalizedMapPoint point,
    MapNavigationGraph graph,
  ) {
    final node = _nearestPathNode(point, graph);
    if (node == null) return null;
    return RouteEndpointCandidate(
      graphNodeId: node.id,
      locationPoint: point,
      accessPoint: point,
      connectorCost: graph.pixelDistance(point, graph.normalize(node)),
    );
  }

  static MapNavigationNode? _nearestPathNode(
    NormalizedMapPoint point,
    MapNavigationGraph graph,
  ) {
    MapNavigationNode? nearest;
    var bestDistance = double.infinity;
    for (final node in graph.nodes) {
      if (node.isStairs) continue;
      final d = graph.pixelDistance(point, graph.normalize(node));
      if (d < bestDistance) {
        bestDistance = d;
        nearest = node;
      }
    }
    return nearest;
  }
}

/// Forma de conectar un lugar (o punto manual) con un nodo del grafo.
class RouteEndpointCandidate {
  const RouteEndpointCandidate({
    required this.graphNodeId,
    required this.locationPoint,
    required this.accessPoint,
    required this.connectorCost,
    this.usesExplicitAccess = false,
  });

  final String graphNodeId;
  final NormalizedMapPoint locationPoint;
  final NormalizedMapPoint accessPoint;

  /// Distancia en píxeles del mapa entre la puerta y el nodo del grafo.
  final double connectorCost;
  final bool usesExplicitAccess;

  List<NormalizedMapPoint> pointsToGraph(MapNavigationGraph graph) =>
      _distinctConsecutive([
        usesExplicitAccess ? accessPoint : locationPoint,
        graph.normalize(graph.nodesById[graphNodeId]!),
      ]);

  List<NormalizedMapPoint> pointsFromGraph(MapNavigationGraph graph) =>
      pointsToGraph(graph).reversed.toList();
}

List<NormalizedMapPoint> _distinctConsecutive(List<NormalizedMapPoint> points) {
  final result = <NormalizedMapPoint>[];
  for (final p in points) {
    if (result.isEmpty || result.last != p) result.add(p);
  }
  return result;
}

class _FloorRoute {
  const _FloorRoute(this.points, this.cost);
  final List<NormalizedMapPoint> points;
  final double cost;
}

class _Leg {
  const _Leg(this.candidate, this.path, this.cost, this.towardsStairs);
  final RouteEndpointCandidate candidate;
  final GraphPath path;
  final double cost;
  final bool towardsStairs;

  List<NormalizedMapPoint> points(MapNavigationGraph graph) {
    final pathPoints = [
      for (final id in path.nodeIds) graph.normalize(graph.nodesById[id]!),
    ];
    return _distinctConsecutive(towardsStairs
        ? [...candidate.pointsToGraph(graph), ...pathPoints]
        : [...pathPoints, ...candidate.pointsFromGraph(graph)]);
  }
}

class _MultiFloorRoute {
  const _MultiFloorRoute({
    required this.connectorId,
    required this.stairsByFloor,
    required this.origin,
    required this.destination,
  });
  final String connectorId;
  final Map<String, MapNavigationNode> stairsByFloor;
  final _Leg origin;
  final _Leg destination;

  double get totalCost => origin.cost + destination.cost;
}
