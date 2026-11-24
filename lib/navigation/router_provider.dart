import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/auth/auth_controller.dart';
import 'app_router.dart';

/// Enrutador único de la app, conectado al estado de sesión de Riverpod.
///
/// Un [ValueNotifier] actúa como `refreshListenable`: cada cambio de sesión lo
/// incrementa y el `redirect` del enrutador se reevalúa.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  final router = createAppRouter(
    refreshListenable: refresh,
    readAuthState: () => ref.read(authControllerProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});
