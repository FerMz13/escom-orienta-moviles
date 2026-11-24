/// Inyección de dependencias de la UI (Riverpod).
///
/// Cada repositorio se expone como provider para poder sustituirlo en pruebas
/// con `ProviderScope(overrides: [...])`.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/institutional/institutional_local_data_source.dart';
import '../data/institutional/local_institutional_repository.dart';
import '../data/map/default_route_calculation_service.dart';
import '../data/map/map_repository.dart';
import '../data/schedule/pdf/pdf_schedule_processor.dart';
import '../data/schedule/schedule_repository.dart';
import '../domain/institutional/institutional_map_action_validator.dart';
import '../domain/institutional/institutional_models.dart';
import '../domain/institutional/institutional_repository.dart';
import '../domain/map/map_models.dart';
import '../domain/schedule/schedule_models.dart';

// --- Mapa ---

final mapRepositoryProvider = Provider<MapRepository>((ref) => MapRepository());

/// Repositorio del mapa ya cargado (los JSON se leen una sola vez).
final loadedMapProvider = FutureProvider<MapRepository>((ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  await repository.ensureLoaded();
  return repository;
});

final routeServiceProvider = Provider<DefaultRouteCalculationService>(
  (ref) => DefaultRouteCalculationService(ref.watch(mapRepositoryProvider)),
);

/// Lugar del mapa correspondiente a un número de salón (`2102` → `salon_2102`).
final placeForClassroomProvider = FutureProvider.family<MapPlace?, String>((ref, classroom) async {
  final map = await ref.watch(loadedMapProvider.future);
  final wanted = classroom.trim();
  for (final place in map.allPlaces) {
    if (place.roomNumber == wanted || place.codes.contains(wanted)) return place;
  }
  return null;
});

// --- Base de datos y horario ---

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(appDatabaseProvider)),
);

final activeScheduleProvider = StreamProvider<ProcessedSchedule?>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchActiveScheduleWithClasses(),
);

final localSettingsProvider = StreamProvider<LocalSettings>(
  (ref) => ref.watch(scheduleRepositoryProvider).watchLocalSettings(),
);

final pdfScheduleProcessorProvider = Provider<PdfScheduleProcessor>((ref) => const PdfScheduleProcessor());

/// Hora actual, actualizada cada minuto (para "clase en curso").
final clockProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());
  final timer = Timer.periodic(const Duration(seconds: 30), (_) => controller.add(DateTime.now()));
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

// --- Catálogo institucional ---

final institutionalRepositoryProvider = Provider<InstitutionalRepository>((ref) {
  final map = ref.watch(mapRepositoryProvider);
  return LocalInstitutionalRepository(
    InstitutionalLocalDataSource(),
    // El mapa ya estará cargado cuando se consulten los recursos.
    mapValidator: InstitutionalMapActionValidator((id) => map.placeById(id) != null),
  );
});

final institutionalResourcesProvider = FutureProvider<List<InstitutionalResource>>((ref) async {
  await ref.watch(loadedMapProvider.future);
  return ref.watch(institutionalRepositoryProvider).getAll();
});

final mapActionValidatorProvider = FutureProvider<InstitutionalMapActionValidator>((ref) async {
  final map = await ref.watch(loadedMapProvider.future);
  return InstitutionalMapActionValidator((id) => map.placeById(id) != null);
});
