import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/auth/auth_models.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/recover_password_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/auth/splash_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/map/map_screen.dart';
import '../ui/procedures/procedure_detail_screen.dart';
import '../ui/procedures/procedures_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/schedule/schedule_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Navegación principal con guardia de sesión (RF1).
///
/// [readAuthState] devuelve el estado de sesión actual y [refreshListenable]
/// notifica al enrutador cuando ese estado cambia (login/logout), de modo que
/// `redirect` se reevalúe y mueva al usuario a la pantalla correcta.
GoRouter createAppRouter({
  required Listenable refreshListenable,
  required AuthState Function() readAuthState,
  String initialLocation = AppRoutes.splash,
}) =>
    GoRouter(
      initialLocation: initialLocation,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final auth = readAuthState();
        final location = state.matchedLocation;
        final onAuthRoute = AppRoutes.authLocations.contains(location);

        // Mientras se restaura la sesión guardada se muestra el splash.
        if (auth.isUnknown) {
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        }
        // Sin sesión: solo se permiten las rutas públicas de autenticación.
        if (!auth.isAuthenticated) {
          return onAuthRoute && location != AppRoutes.splash ? null : AppRoutes.login;
        }
        // Con sesión: fuera del splash y de las pantallas de autenticación.
        if (onAuthRoute) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(path: AppRoutes.recover, builder: (_, __) => const RecoverPasswordScreen()),
        GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
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
