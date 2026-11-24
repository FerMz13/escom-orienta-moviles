import 'package:flutter/services.dart' show rootBundle;

import '../../domain/map/map_floor_catalog.dart';
import '../../domain/map/map_models.dart';
import 'map_json_parser.dart';

/// Lee el contenido de un asset a partir de su ruta (p. ej. `assets/maps/x.json`).
typedef AssetTextLoader = Future<String> Function(String assetPath);

/// Carga y cachea los datos del mapa desde `assets/maps/`.
///
/// El [loader] es inyectable para poder usar el repositorio en pruebas sin
/// `rootBundle`.
class MapRepository {
  MapRepository({AssetTextLoader? loader})
      : _loader = loader ?? rootBundle.loadString;

  final AssetTextLoader _loader;

  final Map<String, MapFloor> _floors = {};
  final Map<String, List<MapPlace>> _placesByFloor = {};
  final Map<String, MapNavigationGraph> _graphs = {};
  final Map<String, MapFloorAccessData> _accessData = {};
  Future<void>? _loading;

  /// Carga todos los pisos una sola vez (las llamadas concurrentes comparten
  /// la misma carga).
  Future<void> ensureLoaded() => _loading ??= _loadAll();

  Future<void> _loadAll() async {
    await Future.wait(MapFloorCatalog.floors.map(_loadFloor));
  }

  Future<void> _loadFloor(FloorAssets assets) async {
    String path(String file) => '${MapFloorCatalog.assetsDir}/$file';
    final [placesJson, navJson, accessJson] = await Future.wait([
      _loader(path(assets.placesAsset)),
      _loader(path(assets.navigationAsset)),
      _loader(path(assets.accessAsset)),
    ]);

    final parsed = MapJsonParser.parsePlaces(placesJson);
    _floors[assets.floorId] = parsed.floor;
    _placesByFloor[assets.floorId] = parsed.places;
    _graphs[assets.floorId] = MapJsonParser.parseNavigationGraph(navJson);
    _accessData[assets.floorId] = MapJsonParser.parseAccessData(accessJson);
  }

  List<MapFloor> get floors => [
        for (final id in MapFloorCatalog.floorIds) ?_floors[id],
      ];

  List<MapPlace> get allPlaces => [
        for (final id in MapFloorCatalog.floorIds) ...?_placesByFloor[id],
      ];

  List<MapPlace> placesOnFloor(String floorId) =>
      _placesByFloor[floorId] ?? const [];

  MapPlace? placeById(String id) {
    for (final place in allPlaces) {
      if (place.id == id) return place;
    }
    return null;
  }

  Map<String, MapNavigationGraph> get graphsByFloor => Map.unmodifiable(_graphs);

  Map<String, MapFloorAccessData> get accessDataByFloor =>
      Map.unmodifiable(_accessData);
}
