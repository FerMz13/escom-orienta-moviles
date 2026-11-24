import 'package:flutter/foundation.dart' show debugPrint;

import '../../domain/institutional/institutional_map_action_validator.dart';
import '../../domain/institutional/institutional_models.dart';
import '../../domain/institutional/institutional_repository.dart';
import '../../domain/text/text_normalization.dart';
import 'institutional_local_data_source.dart';

/// Repositorio del catálogo institucional con caché en memoria.
class LocalInstitutionalRepository implements InstitutionalRepository {
  LocalInstitutionalRepository(this._dataSource, {this.mapValidator});

  final InstitutionalLocalDataSource _dataSource;

  /// Si se proporciona, al cargar se reportan los `mapLocationId` que no
  /// existen en el mapa.
  final InstitutionalMapActionValidator? mapValidator;

  Future<_Catalog>? _catalog;

  /// Problemas detectados en la última carga (archivos inválidos o
  /// ubicaciones inexistentes).
  Future<List<String>> get loadIssues async => (await _load()).issues;

  Future<_Catalog> _load() => _catalog ??= () async {
        final result = await _dataSource.load();
        if (result.resources.isEmpty && result.issues.isNotEmpty) {
          _catalog = null; // Permite reintentar.
          throw StateError(
              'No se pudo cargar el catálogo institucional: ${result.issues.first.message}');
        }
        final issues = [
          for (final issue in result.issues) issue.toString(),
          if (mapValidator case final validator?)
            for (final invalid in validator.audit(result.resources))
              'Ubicación inexistente en el mapa: $invalid',
        ];
        for (final issue in issues) {
          debugPrint('InstitutionalData: $issue');
        }
        return _Catalog(result.resources, issues);
      }();

  Future<List<InstitutionalResource>> _resources() async => (await _load()).resources;

  @override
  Future<List<InstitutionalResource>> getAll() => _resources();

  @override
  Future<InstitutionalResource?> getById(String id) async =>
      (await _resources()).where((r) => r.id == id).firstOrNull;

  @override
  Future<List<InstitutionalResource>> getByCategory(String category) async {
    final wanted = category.toLowerCase();
    return [
      for (final r in await _resources())
        if (r.category.toLowerCase() == wanted) r,
    ];
  }

  @override
  Future<List<InstitutionalResource>> search(String query) async {
    final resources = await _resources();
    final needle = normalizeForSearch(query);
    if (needle.isEmpty) return resources;

    final matches = [
      for (final r in resources)
        if ([r.name, r.shortDescription, ...r.aliases, ...r.keywords]
            .any((text) => normalizeForSearch(text).contains(needle)))
          r,
    ];
    // Primero los que empiezan con el texto buscado; luego por nombre.
    matches.sort((a, b) {
      final aPrefix = normalizeForSearch(a.name).startsWith(needle) ? 0 : 1;
      final bPrefix = normalizeForSearch(b.name).startsWith(needle) ? 0 : 1;
      return aPrefix != bPrefix ? aPrefix - bPrefix : a.name.compareTo(b.name);
    });
    return matches;
  }
}

class _Catalog {
  const _Catalog(this.resources, this.issues);
  final List<InstitutionalResource> resources;
  final List<String> issues;
}
