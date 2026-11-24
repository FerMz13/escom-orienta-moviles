import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../ui/home/home_screen.dart';
import '../ui/map/map_screen.dart';
import '../ui/procedures/procedure_detail_screen.dart';
import '../ui/procedures/procedures_screen.dart';
import '../ui/schedule/schedule_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Navegación principal: cuatro pestañas que conservan su estado
/// (`StatefulShellRoute.indexedStack`).
GoRouter createAppRouter({String initialLocation = AppRoutes.home}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.map,
                pageBuilder: (context, state) => NoTransitionPage(
                  // La clave fuerza a aplicar un nuevo lugar/ruta pedido desde
                  // otra pantalla aunque el mapa ya estuviera abierto.
                  key: ValueKey(state.uri.toString()),
                  child: MapScreen(
                    initialPlaceId: state.uri.queryParameters['lugar'],
                    routeToPlace: state.uri.queryParameters['ruta'] == '1',
                  ),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.schedule,
                pageBuilder: (context, state) => const NoTransitionPage(child: ScheduleScreen()),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: AppRoutes.procedures,
                pageBuilder: (context, state) => const NoTransitionPage(child: ProceduresScreen()),
                routes: [
                  GoRoute(
                    path: AppRoutes.procedureDetail,
                    builder: (context, state) =>
                        ProcedureDetailScreen(resourceId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
        ),
      ),
    );
