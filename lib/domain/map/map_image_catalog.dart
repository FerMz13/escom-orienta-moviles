/// Resolución de las imágenes de cada piso (`assets/images/maps/`).
///
/// Portado de `resolveMapDrawableResource` / `determineMapResolutionLevel`
/// de `MapScreen.kt`.
library;

/// Variante de resolución de la imagen; el sufijo coincide con el archivo.
enum MapResolutionLevel {
  low('b'),
  medium('m'),
  high('a');

  const MapResolutionLevel(this.suffix);

  final String suffix;
}

abstract final class MapImageCatalog {
  static const String imagesDir = 'assets/images/maps';

  static const double mediumEnterScale = 1.8;
  static const double mediumExitScale = 1.5;
  static const double highEnterScale = 3.6;
  static const double highExitScale = 3.2;

  static final RegExp _legacyNumericFloor = RegExp(r'^(.*_mapa_)([12])$');

  /// Nombre base canónico de la imagen.
  ///
  /// `places_p2.json` declara `"escom_mapa_2"` mientras que el archivo real es
  /// `escom_mapa_p2_*.png`; se normaliza aquí sin tocar el JSON original.
  static String canonicalBaseName(String imageResName) {
    final trimmed = imageResName.trim();
    final match = _legacyNumericFloor.firstMatch(trimmed);
    return match == null ? trimmed : '${match[1]}p${match[2]}';
  }

  /// Ruta del asset para un piso y nivel de resolución.
  static String assetPath(String imageResName, MapResolutionLevel level) =>
      '$imagesDir/${canonicalBaseName(imageResName)}_${level.suffix}.png';

  /// Rutas candidatas en orden de preferencia: primero el nivel pedido y
  /// después el resto, por si alguna variante no existe.
  static List<String> candidatePaths(
    String imageResName,
    MapResolutionLevel preferred,
  ) =>
      [
        assetPath(imageResName, preferred),
        for (final level in MapResolutionLevel.values)
          if (level != preferred) assetPath(imageResName, level),
      ];

  /// Nivel de resolución según la escala del zoom, con histéresis para no
  /// alternar imágenes cuando la escala ronda un umbral.
  static MapResolutionLevel resolutionFor(
    double scale, {
    MapResolutionLevel current = MapResolutionLevel.low,
  }) {
    switch (current) {
      case MapResolutionLevel.low:
        if (scale >= highEnterScale) return MapResolutionLevel.high;
        if (scale >= mediumEnterScale) return MapResolutionLevel.medium;
        return MapResolutionLevel.low;
      case MapResolutionLevel.medium:
        if (scale >= highEnterScale) return MapResolutionLevel.high;
        if (scale <= mediumExitScale) return MapResolutionLevel.low;
        return MapResolutionLevel.medium;
      case MapResolutionLevel.high:
        if (scale > highExitScale) return MapResolutionLevel.high;
        return scale <= mediumExitScale
            ? MapResolutionLevel.low
            : MapResolutionLevel.medium;
    }
  }
}
