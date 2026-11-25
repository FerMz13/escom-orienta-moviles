import 'package:material_ui/material_ui.dart';

import '../../domain/schedule/classroom_rules.dart';
import '../../domain/schedule/schedule_models.dart';

/// Colores institucionales (de `theme/Color.kt`).
abstract final class EscomColors {
  static const blue = Color(0xFF006699);
  static const blueDark = Color(0xFF004B73);
  static const blueDeep = Color(0xFF00344F);
  static const blueLight = Color(0xFFD7ECF5);
  static const routeOrigin = Color(0xFF2E7D32);
  static const routeDestination = Color(0xFFC62828);
  static const route = Color(0xFF007DB8);
  static const warning = Color(0xFFB26A00);
}

/// Paletas de color del horario (personalización local, RF-41). Cada materia
/// recibe siempre el mismo color dentro de la paleta elegida.
abstract final class SchedulePalettes {
  static const Map<SchedulePaletteMode, List<Color>> _palettes = {
    SchedulePaletteMode.institutional: [
      Color(0xFF006699), Color(0xFF004B73), Color(0xFF2B7BA6), Color(0xFF00344F),
      Color(0xFF4A90B8), Color(0xFF1F5F80),
    ],
    SchedulePaletteMode.pastel: [
      Color(0xFF8FB8DE), Color(0xFFF4A7B9), Color(0xFFA8D5BA), Color(0xFFFFD59E),
      Color(0xFFC3B1E1), Color(0xFF9ED9D8),
    ],
    SchedulePaletteMode.warm: [
      Color(0xFFD84315), Color(0xFFEF6C00), Color(0xFFF9A825), Color(0xFFC62828),
      Color(0xFF8D6E63), Color(0xFFAD1457),
    ],
    SchedulePaletteMode.cold: [
      Color(0xFF1565C0), Color(0xFF00838F), Color(0xFF283593), Color(0xFF2E7D32),
      Color(0xFF4527A0), Color(0xFF0277BD),
    ],
    // Paleta de Okabe-Ito: distinguible con daltonismo.
    SchedulePaletteMode.accessible: [
      Color(0xFF0072B2), Color(0xFFE69F00), Color(0xFF009E73), Color(0xFFCC79A7),
      Color(0xFF56B4E9), Color(0xFFD55E00),
    ],
  };

  /// Paletas que el usuario puede elegir (la personalizada no tiene editor).
  static List<SchedulePaletteMode> get selectable => _palettes.keys.toList();

  static String label(SchedulePaletteMode mode) => switch (mode) {
        SchedulePaletteMode.institutional => 'Institucional',
        SchedulePaletteMode.pastel => 'Pastel',
        SchedulePaletteMode.warm => 'Cálida',
        SchedulePaletteMode.cold => 'Fría',
        SchedulePaletteMode.accessible => 'Accesible',
        SchedulePaletteMode.custom => 'Personalizada',
      };

  static List<Color> colors(SchedulePaletteMode mode) =>
      _palettes[mode] ?? _palettes[SchedulePaletteMode.institutional]!;

  /// Color estable para una materia (misma materia → mismo color).
  static Color colorFor(String subjectName, SchedulePaletteMode mode) {
    final palette = colors(mode);
    final key = subjectSelectionKey(subjectName);
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: EscomColors.blue,
      brightness: brightness,
      primary: brightness == Brightness.light ? EscomColors.blue : const Color(0xFF8FCDEB),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
