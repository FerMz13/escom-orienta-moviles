import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:escom_orienta_moviles/data/database/app_database.dart';
import 'package:escom_orienta_moviles/data/map/map_repository.dart';
import 'package:escom_orienta_moviles/data/notifications/notification_service.dart';
import 'package:escom_orienta_moviles/domain/auth/auth_models.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_models.dart';
import 'package:escom_orienta_moviles/main.dart';
import 'package:escom_orienta_moviles/navigation/app_router.dart';
import 'package:escom_orienta_moviles/navigation/app_routes.dart';
import 'package:escom_orienta_moviles/navigation/router_provider.dart';
import 'package:escom_orienta_moviles/ui/auth/auth_controller.dart';
import 'package:escom_orienta_moviles/ui/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _fakeUser = UserAccount(
  id: 't',
  email: 'test@ipn.mx',
  fullName: 'Alumno Prueba',
  securityQuestion: 'q',
  createdAt: DateTime(2026),
);

/// Sesión ya autenticada para no pasar por el login en las pruebas de UI.
class _AuthedController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(_fakeUser);
}

/// Notificaciones no-op: evita llamadas a canales de plataforma en pruebas.
class _NoopNotifications extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> syncClassReminders(ProcessedSchedule? schedule, LocalSettings settings) async {}
  @override
  Future<void> requestPermissions() async {}
  @override
  Future<void> showTest() async {}
  @override
  Future<void> cancelAll() async {}
}

/// App con base de datos en memoria y datos de mapa leídos del disco.
Future<ProviderContainer> pumpApp(WidgetTester tester, {String initial = AppRoutes.home}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  // Lectura síncrona: un Future completado en la zona real (runAsync) no
  // reanuda sus continuaciones dentro del reloj simulado de la prueba.
  final map = MapRepository(loader: (path) async => File(path).readAsStringSync());
  await map.ensureLoaded();
  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    mapRepositoryProvider.overrideWithValue(map),
    notificationServiceProvider.overrideWithValue(_NoopNotifications()),
    authControllerProvider.overrideWith(_AuthedController.new),
    // Sin reloj periódico en pruebas.
    clockProvider.overrideWith((ref) => Stream.value(DateTime(2026, 11, 23, 9, 45))),
    // Enrutador con la ubicación inicial deseada y sesión ya autenticada.
    appRouterProvider.overrideWith((ref) {
      final refresh = ValueNotifier<int>(0);
      ref.onDispose(refresh.dispose);
      ref.listen(authControllerProvider, (_, __) => refresh.value++);
      return createAppRouter(
        refreshListenable: refresh,
        readAuthState: () => ref.read(authControllerProvider),
        initialLocation: initial,
      );
    }),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const EscomOrientaApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Inicio muestra accesos y navega entre pestañas', (tester) async {
    await pumpApp(tester);
    expect(find.text('ESCOM Orienta'), findsOneWidget);
    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('Agrega tus materias para ver aquí tu próxima clase.'), findsOneWidget);

    await tester.tap(find.text('Horario'));
    await tester.pumpAndSettle();
    expect(find.text('No hay horario cargado'), findsOneWidget);

    await tester.tap(find.text('Mapa').last);
    await tester.pumpAndSettle();
    expect(find.text('Mapa de ESCOM'), findsWidgets);
    expect(find.text('PB'), findsOneWidget);
  });

  testWidgets('Inicio muestra la clase en curso del horario guardado', (tester) async {
    final container = await pumpApp(tester);
    await tester.runAsync(() => container.read(scheduleRepositoryProvider).saveManualClassSessions([
          ClassSessionDraft(
            subjectName: 'Analisis De Algoritmos',
            groupName: '3CM1',
            dayOfWeek: 1, // 23/11/2026 es lunes
            startTime: '08:30',
            endTime: '10:00',
            classroomName: '2102',
          ),
        ]));
    await tester.pumpAndSettle();
    expect(find.text('EN CURSO AHORA'), findsOneWidget);
    expect(find.text('Analisis De Algoritmos'), findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('Mapa abierto con ruta hacia un lugar', (tester) async {
    await pumpApp(tester, initial: AppRoutes.mapFor(placeId: 'biblioteca', route: true));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Entrada principal'), findsOneWidget);
    expect(find.textContaining(' min · '), findsOneWidget);
  });
}
