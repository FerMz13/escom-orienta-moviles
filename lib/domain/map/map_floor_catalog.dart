/// Catálogo estático de pisos y de la correspondencia física de escaleras.
library;

/// Archivos de assets que describen un piso.
class FloorAssets {
  const FloorAssets({
    required this.floorId,
    required this.placesAsset,
    required this.navigationAsset,
    required this.accessAsset,
  });

  final String floorId;
  final String placesAsset;
  final String navigationAsset;
  final String accessAsset;
}

abstract final class MapFloorCatalog {
  static const String assetsDir = 'assets/maps';

  /// Pisos en orden vertical, de abajo hacia arriba.
  static const List<FloorAssets> floors = [
    FloorAssets(
      floorId: 'PB',
      placesAsset: 'places_pb.json',
      navigationAsset: 'navigation_pb.json',
      accessAsset: 'accesos_pb.json',
    ),
    FloorAssets(
      floorId: '1',
      placesAsset: 'places_p1.json',
      navigationAsset: 'navigation_p1.json',
      accessAsset: 'accesos_p1.json',
    ),
    FloorAssets(
      floorId: '2',
      placesAsset: 'places_p2.json',
      navigationAsset: 'navigation_p2.json',
      accessAsset: 'accesos_p2.json',
    ),
  ];

  static List<String> get floorIds => [for (final f in floors) f.floorId];

  static FloorAssets? byFloorId(String floorId) {
    for (final f in floors) {
      if (f.floorId == floorId) return f;
    }
    return null;
  }

  /// Índice vertical del piso (PB = 0), o -1 si no existe.
  static int levelOf(String floorId) => floorIds.indexOf(floorId);

  /// Correspondencia física de cada escalera entre pisos.
  ///
  /// Los IDs `S0x` NO se pueden comparar directamente entre pisos: la escalera
  /// `S03` de PB sube a `S04` en P1 y P2. Un conector solo sirve para recorrer
  /// los pisos en los que está declarado (p. ej. `PB_S07` no llega a P2).
  static const Map<String, Map<String, String>> stairNodeIdsByConnector = {
    'PB_S01': {'PB': 'S01', '1': 'S01', '2': 'S01'},
    'PB_S02': {'PB': 'S02', '1': 'S02', '2': 'S02'},
    'PB_S03': {'PB': 'S03', '1': 'S04', '2': 'S04'},
    'PB_S04': {'PB': 'S04', '1': 'S05', '2': 'S05'},
    'PB_S05': {'PB': 'S05', '1': 'S06', '2': 'S06'},
    'PB_S06': {'PB': 'S06', '1': 'S07', '2': 'S07'},
    'PB_S07': {'PB': 'S07', '1': 'S08'},
    'PB_S08': {'PB': 'S08', '1': 'S03', '2': 'S03'},
  };
}
