import 'package:flutter/services.dart' show rootBundle;

import '../../domain/institutional/institutional_models.dart';
import 'institutional_json_parser.dart';

/// Lee el contenido de texto de un asset.
typedef InstitutionalAssetReader = Future<String> Function(String assetPath);

/// Problema al cargar un archivo del catálogo (no detiene la carga del resto).
class InstitutionalLoadIssue {
  const InstitutionalLoadIssue(this.path, this.message);
  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

class InstitutionalLoadResult {
  const InstitutionalLoadResult(this.resources, this.issues);
  final List<InstitutionalResource> resources;
  final List<InstitutionalLoadIssue> issues;
}

/// Carga `assets/institutional/manifest.json` y cada recurso que declara.
class InstitutionalLocalDataSource {
  InstitutionalLocalDataSource({
    InstitutionalAssetReader? reader,
    this.parser = const InstitutionalJsonParser(),
    this.rootDir = 'assets/institutional',
  }) : _reader = reader ?? rootBundle.loadString;

  final InstitutionalAssetReader _reader;
  final InstitutionalJsonParser parser;
  final String rootDir;

  String get manifestPath => '$rootDir/manifest.json';

  Future<InstitutionalLoadResult> load() async {
    final List<String> paths;
    try {
      paths = parser.parseManifest(await _reader(manifestPath));
    } catch (error) {
      return InstitutionalLoadResult(
        const [],
        [InstitutionalLoadIssue(manifestPath, _message(error, 'Error de lectura'))],
      );
    }

    final resources = <InstitutionalResource>[];
    final issues = <InstitutionalLoadIssue>[];
    final loaded = await Future.wait(paths.map((relative) async {
      final path = '$rootDir/${relative.replaceAll('\\', '/').replaceFirst(RegExp('^/+'), '')}';
      try {
        return (path, parser.parseResource(await _reader(path)), null);
      } catch (error) {
        return (path, null, _message(error, 'JSON inválido'));
      }
    }));

    // Se conserva el orden del manifest.
    final seen = <String, int>{};
    for (final (path, resource, error) in loaded) {
      if (resource == null) {
        issues.add(InstitutionalLoadIssue(path, error!));
        continue;
      }
      final count = seen.update(resource.id, (c) => c + 1, ifAbsent: () => 1);
      if (count == 1) resources.add(resource);
    }
    seen.forEach((id, count) {
      if (count > 1) {
        issues.add(InstitutionalLoadIssue(
          manifestPath,
          "ID duplicado '$id' ($count recursos); se conserva el primero",
        ));
      }
    });
    return InstitutionalLoadResult(resources, issues);
  }

  static String _message(Object error, String fallback) => switch (error) {
        FormatException(:final message) when message.isNotEmpty => message,
        _ => error.toString().isEmpty ? fallback : error.toString(),
      };
}
