import 'package:drift/drift.dart';

import '../../domain/schedule/schedule_models.dart';
import '../database/app_database.dart';

/// Acceso al horario y a las preferencias locales (portado de
/// `ScheduleRepository.kt`).
class ScheduleRepository {
  ScheduleRepository(this._db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  // --- Lectura ---

  Stream<ProcessedSchedule?> watchActiveScheduleWithClasses() =>
      _db.scheduleDao.watchActiveScheduleWithClasses().map((row) => row == null
          ? null
          : ProcessedSchedule(
              id: row.schedule.id,
              loadedAt: row.schedule.loadedAt,
              publicationStatus: row.schedule.publicationStatus,
              sourceFileName: row.schedule.sourceFileName,
              totalClasses: row.schedule.totalClasses,
              classes: row.classes.map(_toDomain).toList(),
            ));

  Stream<List<ClassSession>> watchAllClasses() =>
      _db.scheduleDao.watchAllClasses().map((rows) => rows.map(_toDomain).toList());

  Stream<List<ClassSession>> watchClassesByDay(int dayOfWeek) =>
      _db.scheduleDao.watchClassesByDay(dayOfWeek).map((rows) => rows.map(_toDomain).toList());

  Future<List<ClassSession>> getAllClasses() async =>
      (await _db.scheduleDao.getAllClasses()).map(_toDomain).toList();

  Future<List<ClassSession>> getClassesByDay(int dayOfWeek) async =>
      (await _db.scheduleDao.getClassesByDay(dayOfWeek)).map(_toDomain).toList();

  Future<List<String>> getAllSubjects() => _db.scheduleDao.getUniqueSubjects();

  /// Clase en curso a esa hora (inicio inclusivo, fin exclusivo).
  Future<ClassSession?> getCurrentClass(int dayOfWeek, int currentTimeMinutes) async =>
      (await getClassesByDay(dayOfWeek))
          .where((c) => c.startMinutes <= currentTimeMinutes && c.endMinutes > currentTimeMinutes)
          .firstOrNull;

  /// Siguiente clase del día que aún no empieza.
  Future<ClassSession?> getNextClass(int dayOfWeek, int currentTimeMinutes) async {
    final upcoming = (await getClassesByDay(dayOfWeek))
        .where((c) => c.startMinutes > currentTimeMinutes)
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return upcoming.firstOrNull;
  }

  // --- Escritura ---

  /// Reemplaza todo el horario por uno nuevo (p. ej. el del PDF).
  Future<int> insertCompleteScheduleWithClasses({
    required String publicationStatus,
    String? sourceFileName,
    required List<ClassSessionDraft> classes,
    DateTime? loadedAt,
  }) =>
      _db.transaction(() async {
        await _db.scheduleDao.deleteAllSchedules();
        final scheduleId = await _db.scheduleDao.insertSchedule(ProcessedSchedulesCompanion.insert(
          loadedAt: loadedAt ?? _clock(),
          publicationStatus: publicationStatus,
          sourceFileName: Value(sourceFileName),
          totalClasses: Value(classes.length),
        ));
        await _db.scheduleDao.insertClassSessions([for (final c in classes) _toCompanion(c, scheduleId)]);
        return scheduleId;
      });

  /// Agrega clases capturadas a mano al horario activo (o crea uno manual).
  Future<void> saveManualClassSessions(List<ClassSessionDraft> classes) async {
    if (classes.isEmpty) return;
    await _db.transaction(() async {
      final scheduleId = await _activeOrNewManualScheduleId();
      await _db.scheduleDao.insertClassSessions([for (final c in classes) _toCompanion(c, scheduleId)]);
      await _refreshClassCount(scheduleId);
    });
  }

  Future<void> updateClassSession(ClassSession session) => _db.transaction(() async {
        await _db.scheduleDao.updateClassSession(_toRow(session));
        await _refreshClassCount(session.scheduleId);
      });

  Future<void> replaceClassSessionWithManualSessions(
    int classSessionId,
    List<ClassSessionDraft> replacements,
  ) =>
      _db.transaction(() async {
        final current = await _db.scheduleDao.getClassSessionById(classSessionId);
        final scheduleId = current?.scheduleId ?? await _activeOrNewManualScheduleId();
        if (current != null) await _db.scheduleDao.deleteClassSessionById(classSessionId);
        if (replacements.isNotEmpty) {
          await _db.scheduleDao
              .insertClassSessions([for (final c in replacements) _toCompanion(c, scheduleId)]);
        }
        await _refreshClassCount(scheduleId);
      });

  /// Reemplaza todas las sesiones de la materia/grupo de [original].
  Future<void> replaceSubjectSessions(ClassSession original, List<ClassSessionDraft> replacements) =>
      _db.transaction(() async {
        await _db.scheduleDao
            .deleteClassSessionsBySubject(original.scheduleId, original.subjectName, original.groupName);
        if (replacements.isNotEmpty) {
          await _db.scheduleDao.insertClassSessions(
              [for (final c in replacements) _toCompanion(c, original.scheduleId)]);
        }
        await _refreshClassCount(original.scheduleId);
      });

  Future<void> deleteClassSession(int classSessionId) => _db.transaction(() async {
        final current = await _db.scheduleDao.getClassSessionById(classSessionId);
        await _db.scheduleDao.deleteClassSessionById(classSessionId);
        if (current != null) await _refreshClassCount(current.scheduleId);
      });

  Future<void> deleteSubjectSessions(ClassSession session) => _db.transaction(() async {
        await _db.scheduleDao
            .deleteClassSessionsBySubject(session.scheduleId, session.subjectName, session.groupName);
        await _refreshClassCount(session.scheduleId);
      });

  Future<void> deleteCurrentSchedule() => _db.transaction(() async {
        final id = await _db.scheduleDao.getActiveScheduleId();
        if (id != null) await _db.scheduleDao.deleteScheduleById(id);
      });

  // --- Preferencias ---

  Stream<LocalSettings> watchLocalSettings() => _db.localSettingsDao
      .watchSettings()
      .map((row) => row == null ? const LocalSettings() : _settingsToDomain(row));

  Future<LocalSettings> getOrCreateLocalSettings() => _db.transaction(() async {
        final current = await _db.localSettingsDao.getSettings();
        if (current != null) return _settingsToDomain(current);
        await _db.localSettingsDao.resetSettings();
        return const LocalSettings();
      });

  Future<void> updateLocalSettings(LocalSettings settings) =>
      _db.localSettingsDao.upsertSettings(_settingsToCompanion(settings));

  /// Lectura-modificación-escritura atómica, para que cambios simultáneos de
  /// la UI no se pisen entre sí.
  Future<void> transformLocalSettings(LocalSettings Function(LocalSettings) transform) =>
      _db.transaction(() async {
        final row = await _db.localSettingsDao.getSettings();
        final current = row == null ? const LocalSettings() : _settingsToDomain(row);
        await _db.localSettingsDao.upsertSettings(_settingsToCompanion(transform(current)));
      });

  /// Borra el horario y restablece las preferencias.
  Future<void> clearLocalData() => _db.transaction(() async {
        await _db.scheduleDao.deleteAllSchedules();
        await _db.localSettingsDao.resetSettings();
      });

  // --- Internos ---

  Future<int> _activeOrNewManualScheduleId() async =>
      await _db.scheduleDao.getActiveScheduleId() ??
      await _db.scheduleDao.insertSchedule(ProcessedSchedulesCompanion.insert(
        loadedAt: _clock(),
        publicationStatus: PublicationStatus.manual,
      ));

  Future<void> _refreshClassCount(int scheduleId) async => _db.scheduleDao
      .updateScheduleClassCount(scheduleId, await _db.scheduleDao.countClassesForSchedule(scheduleId));

  static ClassSession _toDomain(ClassSessionRow r) => ClassSession(
        id: r.id,
        scheduleId: r.scheduleId,
        subjectName: r.subjectName,
        groupName: r.groupName,
        teacherName: r.teacherName,
        dayOfWeek: r.dayOfWeek,
        startTime: r.startTime,
        endTime: r.endTime,
        classroomName: r.classroomName,
        classroomStatus: r.classroomStatus,
        rawText: r.rawText,
      );

  static ClassSessionRow _toRow(ClassSession s) => ClassSessionRow(
        id: s.id,
        scheduleId: s.scheduleId,
        subjectName: s.subjectName,
        groupName: s.groupName,
        teacherName: s.teacherName,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime: s.endTime,
        classroomName: s.classroomName,
        classroomStatus: s.classroomStatus,
        rawText: s.rawText,
      );

  static ClassSessionsCompanion _toCompanion(ClassSessionDraft d, int scheduleId) =>
      ClassSessionsCompanion.insert(
        scheduleId: scheduleId,
        subjectName: d.subjectName,
        groupName: Value(d.groupName),
        teacherName: Value(d.teacherName),
        dayOfWeek: d.dayOfWeek,
        startTime: d.startTime,
        endTime: d.endTime,
        classroomName: Value(d.classroomName),
        classroomStatus: d.classroomStatus,
        rawText: Value(d.rawText),
      );

  static LocalSettings _settingsToDomain(LocalSettingsRow r) => LocalSettings(
        userAlias: r.userAlias.trim().isEmpty ? LocalSettings.defaultUserAlias : r.userAlias,
        themeMode: AppThemeMode.fromStoredValue(r.themeMode),
        schedulePaletteMode: SchedulePaletteMode.fromStoredValue(r.schedulePaletteMode),
        customScheduleColors: r.customScheduleColors,
        remindersEnabled: r.remindersEnabled,
        reminderCount: r.reminderCount,
        classNotificationMinutes: r.classNotificationMinutes,
        enableStartClassNotification: r.enableStartClassNotification,
        notificationScope: NotificationScope.fromStoredValue(r.notificationScope),
        notificationSubjects: r.notificationSubjects,
        interfaceLanguage: r.interfaceLanguage,
      );

  static LocalSettingsTableCompanion _settingsToCompanion(LocalSettings s) =>
      LocalSettingsTableCompanion(
        userAlias: Value(s.sanitizedUserAlias),
        themeMode: Value(s.themeMode.storedValue),
        schedulePaletteMode: Value(s.schedulePaletteMode.storedValue),
        customScheduleColors: Value(s.customScheduleColors),
        remindersEnabled: Value(s.remindersEnabled),
        reminderCount: Value(s.sanitizedReminderCount),
        classNotificationMinutes: Value(s.sanitizedReminderInterval),
        enableStartClassNotification: Value(s.enableStartClassNotification),
        notificationScope: Value(s.notificationScope.storedValue),
        notificationSubjects: Value(s.notificationSubjects),
        interfaceLanguage: Value(s.interfaceLanguage),
      );
}
