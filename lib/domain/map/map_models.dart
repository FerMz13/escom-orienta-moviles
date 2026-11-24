/// Modelos de dominio del mapa del plantel (Dart puro, sin dependencias de Flutter).
///
/// Portados desde `data/map/MapModels.kt` de la versión Kotlin.
library;

import '../navigation/normalized_map_point.dart';
import 'map_image_catalog.dart';

export 'map_image_catalog.dart' show MapResolutionLevel;

/// Piso del plantel tal como aparece en `places_<piso>.json`.
class MapFloor {
  const MapFloor({
    required this.id,
    required this.name,
    required this.imageResName,
  });

  /// `PB`, `1` o `2`.
  final String id;
  final String name;
  /// Valor tal cual viene en el JSON (puede ser el heredado `escom_mapa_2`).
  final String imageResName;

  /// Ruta de la imagen del piso para un nivel de zoom.
  String imageAssetPath([MapResolutionLevel level = MapResolutionLevel.medium]) =>
      MapImageCatalog.assetPath(imageResName, level);

  @override
  String toString() => 'MapFloor($id, $name)';
}

/// Rectángulo en coordenadas normalizadas [0, 1] respecto a la imagen del piso.
class MapBounds {
  const MapBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;

  NormalizedMapPoint get center =>
      NormalizedMapPoint((left + right) / 2, (top + bottom) / 2);
}

enum PlaceType {
  classroom('Aula'),
  laboratory('Laboratorio'),
  computerLab('Aula de cómputo'),
  administrative('Área administrativa'),
  office('Oficina'),
  service('Servicio'),
  restroom('Baño'),
  library('Biblioteca'),
  auditorium('Auditorio'),
  club('Club'),
  meetingRoom('Sala de reuniones'),
  maintenance('Mantenimiento'),
  institutionalArea('Área institucional'),
  sportsArea('Área deportiva'),
  recreationArea('Área recreativa'),
  studyArea('Área de estudio'),
  accessibility('Accesibilidad'),
  parking('Estacionamiento'),
  greenArea('Área verde'),
  smokingArea('Área para fumar'),
  entrance('Entrada'),
  reference('Referencia'),
  general('Área general');

  const PlaceType(this.displayName);

  final String displayName;

  /// Acepta tanto los valores en español del JSON (`AULA`, `AREA_DEPORTIVA`…)
  /// como los nombres en inglés heredados.
  static PlaceType fromJson(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'CLASSROOM' || 'AULA':
        return classroom;
      case 'LABORATORY' || 'LABORATORIO':
        return laboratory;
      case 'COMPUTER_LAB' || 'LABORATORIO_COMPUTO' || 'AULA_COMPUTO':
        return computerLab;
      case 'ADMINISTRATIVE' || 'ADMINISTRATIVO' || 'AREA_ADMINISTRATIVA':
        return administrative;
      case 'OFFICE' || 'OFICINA':
        return office;
      case 'SERVICE' || 'SERVICIO':
        return service;
      case 'RESTROOM' || 'BANO' || 'BAÑO' || 'SANITARIO':
        return restroom;
      case 'LIBRARY' || 'BIBLIOTECA':
        return library;
      case 'AUDITORIUM' || 'AUDITORIO':
        return auditorium;
      case 'CLUB':
        return club;
      case 'MEETING_ROOM' || 'SALA_REUNIONES':
        return meetingRoom;
      case 'MAINTENANCE' || 'MANTENIMIENTO':
        return maintenance;
      case 'INSTITUTIONAL_AREA' || 'AREA_INSTITUCIONAL':
        return institutionalArea;
      case 'SPORTS_AREA' || 'AREA_DEPORTIVA':
        return sportsArea;
      case 'RECREATION_AREA' || 'AREA_RECREATIVA':
        return recreationArea;
      case 'STUDY_AREA' || 'AREA_ESTUDIO':
        return studyArea;
      case 'ACCESSIBILITY' || 'ACCESIBILIDAD':
        return accessibility;
      case 'PARKING' || 'ESTACIONAMIENTO':
        return parking;
      case 'GREEN_AREA' || 'AREA_VERDE':
        return greenArea;
      case 'SMOKING_AREA' || 'AREA_FUMADORES':
        return smokingArea;
      case 'ENTRANCE' || 'ENTRADA':
        return entrance;
      case 'REFERENCE' || 'REFERENCIA':
        return reference;
      default:
        return general;
    }
  }
}

/// Lugar del plantel (aula, laboratorio, baño, área exterior…).
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    required this.floorId,
    required this.floorName,
    this.aliases = const [],
    this.type = PlaceType.general,
    this.building = 'ESCOM',
    this.access,
    this.description = '',
    this.bounds = const [],
    this.navigationNodeId,
    this.markerPerBound = false,
    this.code,
    this.codes = const [],
  });

  final String id;
  final String name;
  final String floorId;
  final String floorName;
  final List<String> aliases;
  final PlaceType type;
  final String building;

  /// `ESTUDIANTES`, `PERSONAL`, `PUBLICO`, `RESTRINGIDO`…
  final String? access;
  final String description;
  final List<MapBounds> bounds;
  final String? navigationNodeId;

  /// Dibuja un marcador al centro de cada área desconectada.
  final bool markerPerBound;
  final String? code;
  final List<String> codes;

  /// Rectángulo que envuelve todos los [bounds], o `null` si no hay ninguno.
  MapBounds? get enclosingBounds {
    if (bounds.isEmpty) return null;
    var left = bounds.first.left, top = bounds.first.top;
    var right = bounds.first.right, bottom = bounds.first.bottom;
    for (final b in bounds.skip(1)) {
      if (b.left < left) left = b.left;
      if (b.top < top) top = b.top;
      if (b.right > right) right = b.right;
      if (b.bottom > bottom) bottom = b.bottom;
    }
    return MapBounds(left: left, top: top, right: right, bottom: bottom);
  }

  /// Centro del rectángulo envolvente, en coordenadas normalizadas.
  NormalizedMapPoint? get centerPoint => enclosingBounds?.center;

  /// Número de salón de 4 dígitos (p. ej. `1101`), si se puede deducir.
  String? get roomNumber {
    if (code != null && code!.trim().isNotEmpty) return code;
    final fourDigits = RegExp(r'^\d{4}$');
    for (final alias in aliases) {
      if (fourDigits.hasMatch(alias)) return alias;
    }
    return RegExp(r'(\d{4})').firstMatch(id)?.group(1) ??
        RegExp(r'\b(\d{4})\b').firstMatch(name)?.group(1);
  }

  @override
  String toString() => 'MapPlace($id, piso $floorId)';
}

enum MapNavigationNodeType {
  path,
  stairs;

  static MapNavigationNodeType fromJson(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'STAIRS' || 'ESCALERAS':
        return stairs;
      default:
        return path;
    }
  }
}

/// Nodo del grafo de navegación, en píxeles del sistema de coordenadas del piso.
class MapNavigationNode {
  const MapNavigationNode({
    required this.id,
    required this.x,
    required this.y,
    this.type = MapNavigationNodeType.path,
  });

  final String id;
  final double x;
  final double y;
  final MapNavigationNodeType type;

  bool get isStairs => type == MapNavigationNodeType.stairs;

  @override
  String toString() => 'Node($id, $x, $y, ${type.name})';
}

/// Arista no dirigida del grafo de navegación.
class MapNavigationEdge {
  const MapNavigationEdge({
    required this.from,
    required this.to,
    required this.weight,
  });

  final String from;
  final String to;
  final double weight;
}

/// Grafo de pasillos de un piso (`navigation_<piso>.json`).
class MapNavigationGraph {
  MapNavigationGraph({
    required this.floorId,
    required this.coordinateWidth,
    required this.coordinateHeight,
    required this.mapWidth,
    required this.mapHeight,
    this.verticalOffset = 0,
    required this.nodes,
    required this.edges,
    this.floorConnectorIds = const [],
  }) : nodesById = {for (final n in nodes) n.id: n};

  final String floorId;
  final double coordinateWidth;
  final double coordinateHeight;
  final double mapWidth;
  final double mapHeight;
  final double verticalOffset;
  final List<MapNavigationNode> nodes;
  final List<MapNavigationEdge> edges;

  /// IDs de nodos de escalera declarados en `conectoresEntrePisos`.
  final List<String> floorConnectorIds;
  final Map<String, MapNavigationNode> nodesById;

  /// Convierte un nodo a coordenadas normalizadas [0, 1] de la imagen.
  NormalizedMapPoint normalize(MapNavigationNode node) => NormalizedMapPoint(
        (node.x / coordinateWidth).clamp(0.0, 1.0),
        ((node.y + verticalOffset) / mapHeight).clamp(0.0, 1.0),
      );

  /// Distancia en píxeles del mapa entre dos puntos normalizados.
  double pixelDistance(NormalizedMapPoint a, NormalizedMapPoint b) =>
      a.scaledDistanceTo(b, mapWidth, mapHeight);
}

/// Punto de acceso (puerta) de un lugar (`accesos_<piso>.json`).
class MapAccessPoint {
  const MapAccessPoint({
    required this.id,
    required this.x,
    required this.y,
    this.type = 'ENTRADA_SALIDA',
    this.graphNodeIds = const [],
  });

  final String id;
  final double x;
  final double y;
  final String type;

  /// Nodos del grafo a los que esta puerta da acceso directo.
  final List<String> graphNodeIds;
}

/// Puntos de acceso de todos los lugares de un piso.
class MapFloorAccessData {
  const MapFloorAccessData({
    required this.floorId,
    required this.coordinateWidth,
    required this.mapHeight,
    this.verticalOffset = 0,
    required this.accessPointsByPlaceId,
  });

  final String floorId;
  final double coordinateWidth;
  final double mapHeight;
  final double verticalOffset;
  final Map<String, List<MapAccessPoint>> accessPointsByPlaceId;

  NormalizedMapPoint normalize(MapAccessPoint point) => NormalizedMapPoint(
        (point.x / coordinateWidth).clamp(0.0, 1.0),
        ((point.y + verticalOffset) / mapHeight).clamp(0.0, 1.0),
      );
}
