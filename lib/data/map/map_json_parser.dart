/// Conversión de los JSON de `assets/maps/` a modelos de dominio.
///
/// Funciones puras (sin Flutter) para poder probarlas con cualquier fuente.
library;

import 'dart:convert';

import '../../domain/map/map_models.dart';

abstract final class MapJsonParser {
  /// `places_<piso>.json` → piso y sus lugares.
  static ({MapFloor floor, List<MapPlace> places}) parsePlaces(String source) {
    final root = _object(jsonDecode(source));
    final floorJson = _object(root['floor']);
    final floor = MapFloor(
      id: _string(floorJson['id']),
      name: _string(floorJson['name']),
      imageResName: _string(floorJson['imageResName']),
    );

    final places = [
      for (final raw in _list(root['places']))
        _parsePlace(_object(raw), floor),
    ];
    return (floor: floor, places: places);
  }

  static MapPlace _parsePlace(Map<String, dynamic> json, MapFloor floor) =>
      MapPlace(
        id: _string(json['id']),
        name: _string(json['name']),
        floorId: floor.id,
        floorName: floor.name,
        aliases: _stringList(json['aliases']),
        type: PlaceType.fromJson(_optString(json['tipo'] ?? json['type'])),
        building: _optString(json['building']) ?? 'ESCOM',
        access: _optString(json['acceso']),
        description: _optString(json['description']) ?? '',
        bounds: [
          for (final b in _list(json['bounds'])) _parseBounds(_object(b)),
        ],
        navigationNodeId: _optString(json['navigationNodeId']),
        markerPerBound: json['markerPerBound'] == true,
        code: _optString(json['code']),
        codes: _stringList(json['codes']),
      );

  static MapBounds _parseBounds(Map<String, dynamic> json) => MapBounds(
        left: _double(json['left']),
        top: _double(json['top']),
        right: _double(json['right']),
        bottom: _double(json['bottom']),
      );

  /// `navigation_<piso>.json` → grafo de navegación.
  static MapNavigationGraph parseNavigationGraph(String source) {
    final root = _object(jsonDecode(source));
    final coords = _object(root['coordinateSystem']);
    return MapNavigationGraph(
      floorId: _string(root['floorId']),
      coordinateWidth: _double(coords['width']),
      coordinateHeight: _double(coords['height']),
      mapWidth: _double(coords['mapWidth']),
      mapHeight: _double(coords['mapHeight']),
      verticalOffset: _double(coords['verticalOffset'], 0),
      floorConnectorIds: _stringList(root['conectoresEntrePisos']),
      nodes: [
        for (final raw in _list(root['nodes']))
          () {
            final n = _object(raw);
            return MapNavigationNode(
              id: _string(n['id']),
              x: _double(n['x']),
              y: _double(n['y']),
              type: MapNavigationNodeType.fromJson(
                _optString(n['tipo'] ?? n['type']),
              ),
            );
          }(),
      ],
      edges: [
        for (final raw in _list(root['edges']))
          () {
            final e = _object(raw);
            return MapNavigationEdge(
              from: _string(e['from']),
              to: _string(e['to']),
              weight: _double(e['weight']),
            );
          }(),
      ],
    );
  }

  /// `accesos_<piso>.json` → puertas por lugar.
  static MapFloorAccessData parseAccessData(String source) {
    final root = _object(jsonDecode(source));
    final coords = _object(root['coordinateSystem']);
    return MapFloorAccessData(
      floorId: _string(root['floorId']),
      coordinateWidth: _double(coords['width']),
      mapHeight: _double(coords['mapHeight']),
      verticalOffset: _double(coords['verticalOffset'], 0),
      accessPointsByPlaceId: {
        for (final raw in _list(root['places']))
          _string(_object(raw)['id']): [
            for (final a in _list(_object(raw)['accessPoints']))
              () {
                final ap = _object(a);
                return MapAccessPoint(
                  id: _string(ap['id']),
                  x: _double(ap['x']),
                  y: _double(ap['y']),
                  type: _optString(ap['tipo'] ?? ap['type']) ??
                      'ENTRADA_SALIDA',
                  graphNodeIds: _stringList(ap['graphNodeIds']),
                );
              }(),
          ],
      },
    );
  }

  // --- utilidades tolerantes a campos nulos/faltantes ---

  static Map<String, dynamic> _object(Object? value) =>
      value is Map<String, dynamic>
          ? value
          : throw FormatException('Se esperaba un objeto JSON: $value');

  static List<Object?> _list(Object? value) =>
      value is List ? value : const [];

  static String _string(Object? value) => value is String
      ? value
      : throw FormatException('Se esperaba una cadena: $value');

  static String? _optString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty || trimmed == 'null' ? null : value;
  }

  static List<String> _stringList(Object? value) =>
      [for (final v in _list(value)) if (v is String) v];

  static double _double(Object? value, [double? fallback]) {
    if (value is num) return value.toDouble();
    if (fallback != null) return fallback;
    throw FormatException('Se esperaba un número: $value');
  }
}
