/// Rutas de la aplicación y constructores de ubicaciones con parámetros.
abstract final class AppRoutes {
  // Autenticación (RF1).
  static const splash = '/cargando';
  static const login = '/login';
  static const register = '/registro';
  static const recover = '/recuperar';
  static const profile = '/perfil';

  static const home = '/inicio';
  static const map = '/mapa';
  static const schedule = '/horario';
  static const procedures = '/tramites';
  static const procedureDetail = 'detalle/:id';

  /// Rutas públicas accesibles sin sesión iniciada.
  static const authLocations = {splash, login, register, recover};

  /// Mapa con un lugar destacado y, opcionalmente, como destino de una ruta.
  static String mapFor({String? placeId, bool route = false}) => Uri(
        path: map,
        queryParameters: {
          'lugar': ?placeId,
          if (route) 'ruta': '1',
        },
      ).toString();

  static String procedure(String id) => '$procedures/detalle/${Uri.encodeComponent(id)}';
}
