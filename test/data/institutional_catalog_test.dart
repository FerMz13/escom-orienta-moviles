import 'dart:io';

import 'package:escom_orienta_moviles/data/institutional/institutional_json_parser.dart';
import 'package:escom_orienta_moviles/data/institutional/institutional_local_data_source.dart';
import 'package:escom_orienta_moviles/data/institutional/local_institutional_repository.dart';
import 'package:escom_orienta_moviles/data/map/map_repository.dart';
import 'package:escom_orienta_moviles/domain/institutional/institutional_map_action_validator.dart';
import 'package:escom_orienta_moviles/domain/institutional/institutional_models.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> fileLoader(String path) => File(path).readAsString();

void main() {
  late InstitutionalLoadResult load;
  late Set<String> mapPlaceIds;
  late InstitutionalMapActionValidator validator;

  setUpAll(() async {
    load = await InstitutionalLocalDataSource(reader: fileLoader).load();
    final maps = MapRepository(loader: fileLoader);
    await maps.ensureLoaded();
    mapPlaceIds = {for (final p in maps.allPlaces) p.id};
    validator = InstitutionalMapActionValidator(mapPlaceIds.contains);
  });

  group('Catálogo institucional real', () {
    test('carga todos los recursos del manifest sin errores', () {
      final manifest = const InstitutionalJsonParser()
          .parseManifest(File('assets/institutional/manifest.json').readAsStringSync());
      expect(load.issues, isEmpty, reason: load.issues.join('\n'));
      expect(load.resources, hasLength(manifest.length));
      expect(load.resources.map((r) => r.id).toSet(), hasLength(manifest.length));
    });

    test('todos los mapLocationId (recurso y ofertas) existen en el mapa', () {
      final invalid = validator.audit(load.resources);
      expect(invalid, isEmpty, reason: invalid.join('\n'));
      expect(load.resources.expand((r) => r.mapLocationIds), isNotEmpty);
    });

    test('la reposición de credencial se identifica como trámite fuera del plantel', () {
      final credential =
          load.resources.firstWhere((r) => r.id == 'dae_reposicion_credencial_institucional');
      expect(validator.validate(credential), MapActionValidation.offCampus);
    });

    test('la biblioteca se ubica en el mapa y tiene capacidades de ruta', () {
      final library = load.resources.firstWhere((r) => r.id == 'servicios_estudiantiles_biblioteca');
      expect(library.type, ResourceType.service);
      expect(library.location?.mapLocationId, 'biblioteca');
      expect(validator.validate(library), MapActionValidation.valid);
      expect(library.supportedCapabilities, contains(InstitutionalResourceCapability.showRoute));
      expect(library.serviceRules, isNotEmpty);
    });

    test('los trámites tienen pasos ordenados', () {
      final procedures = load.resources.where((r) => r.type == ResourceType.procedure);
      expect(procedures, isNotEmpty);
      for (final p in procedures) {
        final orders = [for (final s in p.steps) s.order];
        expect(orders, orderedEquals([...orders]..sort()), reason: p.id);
      }
    });
  });

  group('LocalInstitutionalRepository', () {
    late LocalInstitutionalRepository repository;
    setUp(() {
      repository = LocalInstitutionalRepository(
        InstitutionalLocalDataSource(reader: fileLoader),
        mapValidator: validator,
      );
    });

    test('búsqueda sin acentos ni mayúsculas', () async {
      final results = await repository.search('PRESTAMO');
      expect(results.map((r) => r.id), contains('servicios_estudiantiles_biblioteca'));
      expect(await repository.search('   '), hasLength(load.resources.length));
      expect(await repository.search('zzz-no-existe'), isEmpty);
    });

    test('getById y getByCategory', () async {
      expect((await repository.getById('servicios_estudiantiles_biblioteca'))?.name, 'Biblioteca');
      expect(await repository.getById('no_existe'), isNull);
      expect(await repository.getByCategory('biblioteca'), isNotEmpty);
    });

    test('no reporta problemas de carga ni de ubicación', () async {
      expect(await repository.loadIssues, isEmpty);
    });
  });

  group('Validaciones del parser', () {
    const parser = InstitutionalJsonParser();

    test('rechaza manifest con rutas peligrosas o sin versión', () {
      expect(() => parser.parseManifest('{"schemaVersion":1,"resources":["../x.json"]}'),
          throwsFormatException);
      expect(() => parser.parseManifest('{"resources":["a.json"]}'), throwsFormatException);
    });

    test('rechaza pasos duplicados y recursos sin id', () {
      expect(
        () => parser.parseResource(
            '{"id":"x","name":"X","type":"PROCEDURE","steps":[{"order":1,"title":"a"},{"order":1,"title":"b"}]}'),
        throwsFormatException,
      );
      expect(() => parser.parseResource('{"name":"X","type":"SERVICE"}'), throwsFormatException);
    });

    test('mapLocationId null no se convierte en "null"', () {
      final r = parser.parseResource(
          '{"id":"x","name":"X","type":"SERVICE","location":{"mapLocationId":null,"displayName":"DAE Zacatenco"}}');
      expect(r.location?.mapLocationId, isNull);
      expect(InstitutionalMapActionValidator((_) => true).validate(r), MapActionValidation.offCampus);
    });

    test('un mapLocationId inexistente se reporta', () {
      final r = parser.parseResource(
          '{"id":"x","name":"X","type":"SERVICE","location":{"mapLocationId":"no_existe","displayName":"?"}}');
      expect(validator.validate(r), MapActionValidation.invalidLocationId);
      expect(validator.audit([r]).single.mapLocationId, 'no_existe');
    });

    test('el arquetipo se deriva del tipo y la categoría', () {
      final r = parser.parseResource('{"id":"x","name":"X","type":"SERVICE","category":"DEPORTE"}');
      expect(r.archetype, InstitutionalArchetype.workshopActivity);
    });
  });
}
