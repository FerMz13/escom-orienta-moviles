import 'package:material_ui/material_ui.dart';

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
