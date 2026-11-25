import 'package:drift/native.dart';
import 'package:escom_orienta_moviles/data/database/app_database.dart';
import 'package:escom_orienta_moviles/data/schedule/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quien actualice la app conserva su horario y sus preferencias al pasar del
/// esquema v1 al v2 (columnas `reminders_enabled` y `reminder_count`).
void main() {
  test('migración v1 → v2 conserva datos y agrega valores por defecto', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      // Esquema v1 tal como lo creaba la versión anterior.
      raw.execute('''
        CREATE TABLE local_settings (
          id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
          user_alias TEXT NOT NULL DEFAULT 'Alumno',
          theme_mode TEXT NOT NULL DEFAULT 'SYSTEM',
          schedule_palette_mode TEXT NOT NULL DEFAULT 'INSTITUTIONAL',
          custom_schedule_colors TEXT NOT NULL DEFAULT '',
          class_notification_minutes INTEGER NOT NULL DEFAULT 10,
          enable_start_class_notification INTEGER NOT NULL DEFAULT 1,
          notification_scope TEXT NOT NULL DEFAULT 'ALL_SUBJECTS',
          notification_subjects TEXT NOT NULL DEFAULT '',
          interface_language TEXT NOT NULL DEFAULT 'es'
        );''');
      raw.execute('''
        CREATE TABLE processed_schedules (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          loaded_at INTEGER NOT NULL,
          publication_status TEXT NOT NULL,
          source_file_name TEXT NULL,
          total_classes INTEGER NOT NULL DEFAULT 0
        );''');
      raw.execute('''
        CREATE TABLE class_sessions (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          schedule_id INTEGER NOT NULL REFERENCES processed_schedules (id) ON DELETE CASCADE,
          subject_name TEXT NOT NULL,
          group_name TEXT NULL,
          teacher_name TEXT NULL,
          day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          classroom_name TEXT NULL,
          classroom_status TEXT NOT NULL,
          raw_text TEXT NULL
        );''');
      raw.execute("INSERT INTO local_settings (id, user_alias, theme_mode, class_notification_minutes) "
          "VALUES (1, 'Fer', 'DARK', 15);");
      raw.execute("INSERT INTO processed_schedules (id, loaded_at, publication_status, total_classes) "
          "VALUES (1, 0, 'MANUAL', 1);");
      raw.execute("INSERT INTO class_sessions (schedule_id, subject_name, day_of_week, start_time, "
          "end_time, classroom_status) VALUES (1, 'Cálculo', 1, '07:00', '08:30', 'PENDING');");
      raw.userVersion = 1;
    });

    final db = AppDatabase(executor);
    addTearDown(db.close);
    final repository = ScheduleRepository(db);

    final settings = await repository.getOrCreateLocalSettings();
    expect(settings.userAlias, 'Fer');
    expect(settings.classNotificationMinutes, 15);
    expect(settings.remindersEnabled, isTrue);
    expect(settings.reminderCount, 1);

    final classes = await repository.getAllClasses();
    expect(classes.single.subjectName, 'Cálculo');
  });
}
