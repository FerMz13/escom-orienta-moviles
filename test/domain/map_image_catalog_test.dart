import 'dart:io';

import 'package:escom_orienta_moviles/data/map/map_json_parser.dart';
import 'package:escom_orienta_moviles/domain/map/map_floor_catalog.dart';
import 'package:escom_orienta_moviles/domain/map/map_image_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza el nombre heredado "escom_mapa_2" a "escom_mapa_p2"', () {
    expect(MapImageCatalog.canonicalBaseName('escom_mapa_2'), 'escom_mapa_p2');
    expect(MapImageCatalog.canonicalBaseName('escom_mapa_1'), 'escom_mapa_p1');
    expect(MapImageCatalog.canonicalBaseName('escom_mapa_p1'), 'escom_mapa_p1');
    expect(MapImageCatalog.canonicalBaseName('escom_mapa_pb'), 'escom_mapa_pb');
  });

  test('cada piso de places_*.json resuelve imágenes que existen en disco', () {
    for (final floor in MapFloorCatalog.floors) {
      final source = File('assets/maps/${floor.placesAsset}').readAsStringSync();
      final parsed = MapJsonParser.parsePlaces(source).floor;
      for (final level in MapResolutionLevel.values) {
        final path = parsed.imageAssetPath(level);
        expect(File(path).existsSync(), isTrue, reason: '${floor.floorId}: $path');
      }
    }
  });

  test('el JSON original de P2 no se modificó', () {
    final source = File('assets/maps/places_p2.json').readAsStringSync();
    expect(MapJsonParser.parsePlaces(source).floor.imageResName, 'escom_mapa_2');
  });

  test('nivel de resolución con histéresis', () {
    const low = MapResolutionLevel.low, medium = MapResolutionLevel.medium, high = MapResolutionLevel.high;
    expect(MapImageCatalog.resolutionFor(1.0), low);
    expect(MapImageCatalog.resolutionFor(1.8), medium);
    expect(MapImageCatalog.resolutionFor(3.6), high);
    // Entre umbrales se conserva el nivel actual.
    expect(MapImageCatalog.resolutionFor(1.6, current: medium), medium);
    expect(MapImageCatalog.resolutionFor(1.6, current: low), low);
    expect(MapImageCatalog.resolutionFor(3.4, current: high), high);
    expect(MapImageCatalog.resolutionFor(3.0, current: high), medium);
    expect(MapImageCatalog.resolutionFor(1.2, current: high), low);
  });
}
