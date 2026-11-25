import 'package:drift/drift.dart';

/// Horario cargado (PDF del SAES o captura manual). Solo uno está activo: el
/// más reciente.
@DataClassName('ProcessedScheduleRow')
class ProcessedSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loadedAt => dateTime()();
  TextColumn get publicationStatus => text()();
  TextColumn get sourceFileName => text().nullable()();
  IntColumn get totalClasses => integer().withDefault(const Constant(0))();
}

@DataClassName('ClassSessionRow')
@TableIndex(name: 'idx_class_sessions_schedule_id', columns: {#scheduleId})
@TableIndex(name: 'idx_class_sessions_day_of_week', columns: {#dayOfWeek})
class ClassSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleId =>
      integer().references(ProcessedSchedules, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectName => text()();
  TextColumn get groupName => text().nullable()();
  TextColumn get teacherName => text().nullable()();

  /// 1 = lunes … 6 = sábado.
  // ignore: recursive_getters — patrón de Drift para restricciones CHECK.
  IntColumn get dayOfWeek => integer().check(dayOfWeek.isBetweenValues(1, 7))();

  /// `HH:mm`
  TextColumn get startTime => text().withLength(min: 4, max: 8)();

  /// `HH:mm`
  TextColumn get endTime => text().withLength(min: 4, max: 8)();
  TextColumn get classroomName => text().nullable()();
  TextColumn get classroomStatus => text()();
  TextColumn get rawText => text().nullable()();
}

/// Preferencias del usuario: una sola fila con `id = 1`.
@DataClassName('LocalSettingsRow')
class LocalSettingsTable extends Table {
  @override
  String get tableName => 'local_settings';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get userAlias => text().withDefault(const Constant('Alumno'))();
  TextColumn get themeMode => text().withDefault(const Constant('SYSTEM'))();
  TextColumn get schedulePaletteMode =>
      text().withDefault(const Constant('INSTITUTIONAL'))();
  TextColumn get customScheduleColors => text().withDefault(const Constant(''))();
  /// Interruptor general de recordatorios (RF-18). Esquema v2.
  BoolColumn get remindersEnabled => boolean().withDefault(const Constant(true))();

  /// Cantidad de avisos previos por clase (RF-20). Esquema v2.
  IntColumn get reminderCount => integer().withDefault(const Constant(1))();

  /// Intervalo en minutos entre avisos previos (el primero sale N min antes).
  IntColumn get classNotificationMinutes => integer().withDefault(const Constant(10))();
  BoolColumn get enableStartClassNotification =>
      boolean().withDefault(const Constant(true))();
  TextColumn get notificationScope =>
      text().withDefault(const Constant('ALL_SUBJECTS'))();
  TextColumn get notificationSubjects => text().withDefault(const Constant(''))();
  TextColumn get interfaceLanguage => text().withDefault(const Constant('es'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
