import 'dart:io';

import 'package:escom_orienta_moviles/data/map/default_route_calculation_service.dart';
import 'package:escom_orienta_moviles/data/map/map_repository.dart';
import 'package:escom_orienta_moviles/domain/map/map_floor_catalog.dart';
import 'package:escom_orienta_moviles/domain/navigation/a_star_route_finder.dart';
import 'package:escom_orienta_moviles/domain/navigation/normalized_map_point.dart';
import 'package:escom_orienta_moviles/domain/navigation/route_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lee los assets reales desde disco (`flutter test` corre en la raíz del proyecto).
Future<String> fileLoader(String path) => File(path).readAsString();

void main() {
  late MapRepository repository;
  late DefaultRouteCalculationService service;

  setUpAll(() async {
    repository = MapRepository(loader: fileLoader);
    await repository.ensureLoaded();
    service = DefaultRouteCalculationService(repository);
  });

  group('Carga de assets/maps', () {
    test('carga los tres pisos con lugares, grafo y accesos', () {
      expect(repository.floors.map((f) => f.id), ['PB', '1', '2']);
      for (final floorId in MapFloorCatalog.floorIds) {
        expect(repository.placesOnFloor(floorId), isNotEmpty);
        final graph = repository.graphsByFloor[floorId]!;
        expect(graph.nodes, isNotEmpty);
        expect(graph.edges, isNotEmpty);
        expect(repository.accessDataByFloor[floorId]!.accessPointsByPlaceId,
            isNotEmpty);
      }
    });

    test('todas las aristas apuntan a nodos existentes', () {
      for (final graph in repository.graphsByFloor.values) {
        for (final e in graph.edges) {
          expect(graph.nodesById, contains(e.from), reason: '${graph.floorId}: ${e.from}');
          expect(graph.nodesById, contains(e.to), reason: '${graph.floorId}: ${e.to}');
        }
      }
    });

    test('los conectores de escaleras existen y son ESCALERAS en cada piso', () {
      MapFloorCatalog.stairNodeIdsByConnector.forEach((connector, byFloor) {
        byFloor.forEach((floorId, nodeId) {
          final node = repository.graphsByFloor[floorId]!.nodesById[nodeId];
          expect(node, isNotNull, reason: '$connector en piso $floorId');
          expect(node!.isStairs, isTrue, reason: '$connector en piso $floorId');
        });
      });
    });

    test('cada escalera conectora es alcanzable dentro de su piso', () {
      MapFloorCatalog.stairNodeIdsByConnector.forEach((connector, byFloor) {
        byFloor.forEach((floorId, nodeId) {
          final graph = repository.graphsByFloor[floorId]!;
          final finder = AStarRouteFinder(graph);
          final reachable = graph.nodes
              .where((n) => !n.isStairs)
              .any((n) => finder.findPath(n.id, nodeId) != null);
          expect(reachable, isTrue, reason: '$connector ($nodeId) en piso $floorId');
        });
      });
    });
  });

  group('DefaultRouteCalculationService', () {
    test('ruta en el mismo piso (P1)', () async {
      final result = await service.calculateRouteByIds('salon_1101', 'salon_1104');
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.isMultiFloor, isFalse);
      expect(result.segments.single.floorId, '1');
      expect(result.segments.single.points.length, greaterThanOrEqualTo(2));
      expect(result.totalCost, greaterThan(0));
    });

    test('ruta de PB a P2 pasa por P1 con una escalera coherente', () async {
      final result = await service.calculateRouteByIds('entrada_principal', 'salon_1201');
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.isMultiFloor, isTrue);
      expect(result.segments.map((s) => s.floorId), ['PB', '1', '2']);
      expect(result.transitions.map((t) => (t.fromFloorId, t.toFloorId)),
          [('PB', '1'), ('1', '2')]);

      final connector = result.transitions.first.connectorId;
      expect(result.transitions.every((t) => t.connectorId == connector), isTrue);
      final mapping = MapFloorCatalog.stairNodeIdsByConnector[connector]!;
      expect(mapping.containsKey('2'), isTrue,
          reason: 'el conector elegido debe llegar hasta P2');
      expect(result.transitions[0].stairNodeId, mapping['PB']);
      expect(result.transitions[1].stairNodeId, mapping['1']);
    });

    test('la ruta de bajada es simétrica en costo a la de subida', () async {
      final up = await service.calculateRouteByIds('entrada_principal', 'salon_1201');
      final down = await service.calculateRouteByIds('salon_1201', 'entrada_principal');
      expect(down.success, isTrue, reason: down.errorMessage);
      expect(down.segments.map((s) => s.floorId), ['2', '1', 'PB']);
      expect(down.totalCost, closeTo(up.totalCost, 1e-6));
    });

    test('todos los puntos están normalizados en [0, 1]', () async {
      final result = await service.calculateRouteByIds('salon_1101', 'entrada_principal');
      expect(result.success, isTrue, reason: result.errorMessage);
      for (final s in result.segments) {
        for (final p in s.points) {
          expect(p.x, inInclusiveRange(0, 1));
          expect(p.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('origen manual sobre el mapa', () async {
      final result = await service.calculateRoute(
        const ManualPointEndpoint(floorId: 'PB', point: NormalizedMapPoint(0.5, 0.5)),
        const PlaceIdEndpoint('salon_1102'),
      );
      expect(result.success, isTrue, reason: result.errorMessage);
      expect(result.segments.first.points.first, const NormalizedMapPoint(0.5, 0.5));
      expect(result.origin, isA<ManualPointEndpoint>());
    });

    test('modo accesible no permite cambiar de piso', () async {
      final result = await service.calculateRouteByIds(
        'entrada_principal', 'salon_1201', accessibleOnly: true);
      expect(result.success, isFalse);
    });

    test('destino inexistente falla con mensaje', () async {
      final result = await service.calculateRouteByIds('salon_1101', 'no_existe');
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });

    test('se encuentra ruta desde la entrada principal a todo lugar con acceso al grafo', () async {
      final failures = <String>[];
      for (final place in repository.allPlaces) {
        final candidates = service.buildEndpointCandidates(
          place,
          repository.graphsByFloor[place.floorId]!,
          repository.accessDataByFloor[place.floorId],
        );
        if (candidates.isEmpty) continue;
        final r = await service.calculateRouteByIds('entrada_principal', place.id);
        if (!r.success) failures.add('${place.id} (${place.floorId}): ${r.errorMessage}');
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}
