import '../map/map_models.dart';
import 'normalized_map_point.dart';
import 'route_models.dart';

/// Contrato del cálculo de rutas peatonales (uno o varios pisos).
abstract interface class RouteCalculationService {
  /// Calcula la ruta resolviendo los extremos con los datos del repositorio.
  Future<RouteResult> calculateRoute(
    RouteEndpoint origin,
    RouteEndpoint destination, {
    bool accessibleOnly = false,
  });

  Future<RouteResult> calculateRouteByIds(
    String originPlaceId,
    String destinationPlaceId, {
    bool accessibleOnly = false,
  });

  /// Cálculo síncrono con grafos y accesos ya cargados (indexados por piso).
  RouteResult calculateRouteWithGraphs({
    required Map<String, MapNavigationGraph> graphsByFloor,
    required Map<String, MapFloorAccessData> accessDataByFloor,
    required String originFloorId,
    required NormalizedMapPoint originPoint,
    MapPlace? originPlace,
    required MapPlace destinationPlace,
    bool accessibleOnly = false,
  });
}
