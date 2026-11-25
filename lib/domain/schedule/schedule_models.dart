/// Modelos del horario de clases (portados de `ScheduleModels.kt`).
library;

abstract final class PublicationStatus {
  static const manual = 'MANUAL';
  static const pdfProcessed = 'PDF_PROCESSED';
}

/// Qué tanto del horario tiene salón asignado.
abstract final class ScheduleStatus {
  static const noRoomsPublished = 'NO_ROOMS_PUBLISHED';
  static const partialRooms = 'PARTIAL_ROOMS';
  static const complete = 'COMPLETE';
}

abstract final class ClassroomStatus {
  static const available = 'AVAILABLE';
  static const pending = 'PENDING';
}

/// Convierte `HH:mm` a minutos desde medianoche (0 si no es válido).
int timeToMinutes(String time) {
  final parts = time.split(':');
  final hours = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return hours * 60 + minutes;
}

/// Campos comunes de una clase guardada o por guardar.
abstract class ClassSessionData {
  String get subjectName;
  String? get groupName;
  String? get teacherName;

  /// 1 = lunes … 6 = sábado.
  int get dayOfWeek;

  /// `HH:mm`
  String get startTime;

  /// `HH:mm`
  String get endTime;
  String? get classroomName;
  String get classroomStatus;
  String? get rawText;

  int get startMinutes => timeToMinutes(startTime);
  int get endMinutes => timeToMinutes(endTime);
}

/// Clase aún no persistida (resultado del PDF o captura manual).
class ClassSessionDraft extends ClassSessionData {
  ClassSessionDraft({
    required this.subjectName,
    this.groupName,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroomName,
    String? classroomStatus,
    this.rawText,
  }) : classroomStatus = classroomStatus ??
            (classroomName == null ? ClassroomStatus.pending : ClassroomStatus.available);

  @override
  final String subjectName;
  @override
  final String? groupName;
  @override
  final String? teacherName;
  @override
  final int dayOfWeek;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final String? classroomName;
  @override
  final String classroomStatus;
  @override
  final String? rawText;

  ClassSessionDraft copyWith({
    String? subjectName,
    String? groupName,
    String? teacherName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroomName,
    String? classroomStatus,
  }) =>
      ClassSessionDraft(
        subjectName: subjectName ?? this.subjectName,
        groupName: groupName ?? this.groupName,
        teacherName: teacherName ?? this.teacherName,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        classroomName: classroomName ?? this.classroomName,
        classroomStatus: classroomStatus ?? this.classroomStatus,
        rawText: rawText,
      );

  @override
  String toString() =>
      'ClassSessionDraft($subjectName, $groupName, día $dayOfWeek, $startTime-$endTime, $classroomName)';
}

/// Clase guardada en la base de datos.
class ClassSession extends ClassSessionData {
  ClassSession({
    required this.id,
    required this.scheduleId,
    required this.subjectName,
    this.groupName,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classroomName,
    required this.classroomStatus,
    this.rawText,
  });

  final int id;
  final int scheduleId;
  @override
  final String subjectName;
  @override
  final String? groupName;
  @override
  final String? teacherName;
  @override
  final int dayOfWeek;
  @override
  final String startTime;
  @override
  final String endTime;
  @override
  final String? classroomName;
  @override
  final String classroomStatus;
  @override
  final String? rawText;

  @override
  bool operator ==(Object other) => other is ClassSession && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClassSession#$id($subjectName, día $dayOfWeek, $startTime-$endTime)';
}

/// Horario activo con sus clases.
class ProcessedSchedule {
  const ProcessedSchedule({
    required this.id,
    required this.loadedAt,
    required this.publicationStatus,
    this.sourceFileName,
    required this.totalClasses,
    required this.classes,
  });

  final int id;
  final DateTime loadedAt;
  final String publicationStatus;
  final String? sourceFileName;
  final int totalClasses;
  final List<ClassSession> classes;
}

enum AppThemeMode {
  system,
  light,
  dark;

  String get storedValue => name.toUpperCase();

  static AppThemeMode fromStoredValue(String value) =>
      values.where((v) => v.storedValue == value).firstOrNull ?? system;
}

enum SchedulePaletteMode {
  institutional,
  pastel,
  warm,
  accessible,
  cold,
  custom;

  String get storedValue => name.toUpperCase();

  static SchedulePaletteMode fromStoredValue(String value) =>
      values.where((v) => v.storedValue == value).firstOrNull ?? institutional;
}

enum NotificationScope {
  allSubjects('ALL_SUBJECTS'),
  selectedSubjects('SELECTED_SUBJECTS');

  const NotificationScope(this.storedValue);
  final String storedValue;

  static NotificationScope fromStoredValue(String value) =>
      values.where((v) => v.storedValue == value).firstOrNull ?? allSubjects;
}

/// Preferencias locales del usuario (fila única).
class LocalSettings {
  static const defaultUserAlias = 'Alumno';
  static const maxUserAliasLength = 20;

  /// Valores admitidos para la configuración de recordatorios (RF-20).
  static const allowedReminderCounts = [1, 2, 3];
  static const allowedReminderIntervals = [5, 10, 15, 20, 30];

  const LocalSettings({
    this.userAlias = defaultUserAlias,
    this.themeMode = AppThemeMode.system,
    this.schedulePaletteMode = SchedulePaletteMode.institutional,
    this.customScheduleColors = '',
    this.remindersEnabled = true,
    this.reminderCount = 1,
    this.classNotificationMinutes = 10,
    this.enableStartClassNotification = true,
    this.notificationScope = NotificationScope.allSubjects,
    this.notificationSubjects = '',
    this.interfaceLanguage = 'es',
  });

  final String userAlias;
  final AppThemeMode themeMode;
  final SchedulePaletteMode schedulePaletteMode;
  final String customScheduleColors;

  /// Interruptor general: si es `false` no se programa ningún aviso (RF-18).
  final bool remindersEnabled;

  /// Cuántos avisos previos se envían por clase (RF-20).
  final int reminderCount;

  /// Intervalo en minutos entre avisos previos; el más cercano sale
  /// [classNotificationMinutes] antes del inicio (RF-19, RF-20).
  final int classNotificationMinutes;
  final bool enableStartClassNotification;
  final NotificationScope notificationScope;

  /// Claves de materias separadas por `;` (ver `subjectSelectionKey`).
  final String notificationSubjects;
  final String interfaceLanguage;

  /// Alias recortado, nunca vacío y de máximo [maxUserAliasLength] caracteres.
  String get sanitizedUserAlias {
    final trimmed = userAlias.trim();
    final alias = trimmed.isEmpty ? defaultUserAlias : trimmed;
    return alias.length > maxUserAliasLength ? alias.substring(0, maxUserAliasLength) : alias;
  }

  /// [reminderCount] acotado a los valores admitidos.
  int get sanitizedReminderCount => reminderCount.clamp(
      allowedReminderCounts.first, allowedReminderCounts.last);

  /// [classNotificationMinutes] acotado a los valores admitidos (0 = sin aviso previo).
  int get sanitizedReminderInterval => classNotificationMinutes <= 0
      ? 0
      : classNotificationMinutes.clamp(
          allowedReminderIntervals.first, allowedReminderIntervals.last);

  /// Minutos antes del inicio en que sale cada aviso previo, del más lejano
  /// al más cercano. Ej.: 2 avisos cada 10 min → `[20, 10]`.
  List<int> get reminderOffsetsMinutes {
    final interval = sanitizedReminderInterval;
    if (interval == 0) return const [];
    return [for (var i = sanitizedReminderCount; i >= 1; i--) i * interval];
  }

  LocalSettings copyWith({
    String? userAlias,
    AppThemeMode? themeMode,
    SchedulePaletteMode? schedulePaletteMode,
    String? customScheduleColors,
    bool? remindersEnabled,
    int? reminderCount,
    int? classNotificationMinutes,
    bool? enableStartClassNotification,
    NotificationScope? notificationScope,
    String? notificationSubjects,
    String? interfaceLanguage,
  }) =>
      LocalSettings(
        userAlias: userAlias ?? this.userAlias,
        themeMode: themeMode ?? this.themeMode,
        schedulePaletteMode: schedulePaletteMode ?? this.schedulePaletteMode,
        customScheduleColors: customScheduleColors ?? this.customScheduleColors,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        reminderCount: reminderCount ?? this.reminderCount,
        classNotificationMinutes: classNotificationMinutes ?? this.classNotificationMinutes,
        enableStartClassNotification:
            enableStartClassNotification ?? this.enableStartClassNotification,
        notificationScope: notificationScope ?? this.notificationScope,
        notificationSubjects: notificationSubjects ?? this.notificationSubjects,
        interfaceLanguage: interfaceLanguage ?? this.interfaceLanguage,
      );
}
