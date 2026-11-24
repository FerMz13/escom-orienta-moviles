import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'domain/schedule/schedule_models.dart';
import 'navigation/app_router.dart';
import 'ui/providers.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: EscomOrientaApp()));
}

class EscomOrientaApp extends ConsumerStatefulWidget {
  const EscomOrientaApp({super.key, this.router});

  /// Permite inyectar un router en pruebas.
  final GoRouter? router;

  @override
  ConsumerState<EscomOrientaApp> createState() => _EscomOrientaAppState();
}

class _EscomOrientaAppState extends ConsumerState<EscomOrientaApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  Widget build(BuildContext context) {
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
      routerConfig: _router,
    );
  }
}
