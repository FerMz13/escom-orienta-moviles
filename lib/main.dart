import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'domain/schedule/schedule_models.dart';
import 'navigation/router_provider.dart';
import 'ui/providers.dart';
import 'ui/theme/app_theme.dart';

void main() {
  // Manejo GLOBAL de excepciones (RNF2 · Confiabilidad): ningún error no
  // controlado debe cerrar la app de forma inesperada durante la demo.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      debugPrint('FlutterError no controlado: ${details.exceptionAsString()}');
    };

    // Pantalla de error amable en lugar del recuadro rojo en producción.
    ErrorWidget.builder = (details) => _FriendlyError(details: details);

    runApp(const ProviderScope(child: EscomOrientaApp()));
  }, (error, stack) {
    debugPrint('Excepción asíncrona no controlada: $error\n$stack');
  });
}

class EscomOrientaApp extends ConsumerWidget {
  const EscomOrientaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mantiene vivo el efecto que reprograma las notificaciones de clase.
    ref.watch(notificationSyncProvider);

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(localSettingsProvider).value?.themeMode ?? AppThemeMode.system;

    return MaterialApp.router(
      title: 'ESCOM Orienta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}

/// Reemplaza el recuadro rojo de error por un mensaje neutro para el usuario.
class _FriendlyError extends StatelessWidget {
  const _FriendlyError({required this.details});
  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      // En desarrollo conviene seguir viendo el detalle del error.
      return ErrorWidget(details.exception);
    }
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48),
              SizedBox(height: 12),
              Text('Ocurrió un problema al mostrar esta pantalla.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
