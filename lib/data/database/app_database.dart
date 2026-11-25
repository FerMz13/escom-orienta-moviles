import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/local_settings_dao.dart';
import 'daos/schedule_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Base de datos local (equivalente a `AppDatabase.kt` de Room).
///
/// Para regenerar el código tras cambiar tablas o DAOs:
/// `dart run build_runner build`
@DriftDatabase(
  tables: [ProcessedSchedules, ClassSessions, LocalSettingsTable],
  daos: [ScheduleDao, LocalSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] permite inyectar `NativeDatabase.memory()` en pruebas.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const databaseName = 'escom_orienta';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: interruptor general y cantidad de avisos previos (RF-18, RF-20).
          if (from < 2) {
            await m.addColumn(localSettingsTable, localSettingsTable.remindersEnabled);
            await m.addColumn(localSettingsTable, localSettingsTable.reminderCount);
          }
        },
        beforeOpen: (details) async {
          // SQLite trae las llaves foráneas desactivadas; sin esto no hay
          // borrado en cascada de clases al borrar un horario.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: databaseName);
}
