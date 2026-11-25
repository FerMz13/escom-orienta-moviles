/// Planeación de recordatorios de clase (RF-17 a RF-21).
///
/// Dart puro: decide QUÉ avisos deben existir a partir del horario y las
/// preferencias. La programación real en el sistema operativo vive en
/// `data/notifications/notification_service.dart`.
library;

import 'classroom_rules.dart';
import 'schedule_models.dart';

/// Un aviso semanal: se repite cada semana el [dayOfWeek] a [minutesOfDay].
class PlannedReminder {
  const PlannedReminder({
    required this.dayOfWeek,
    required this.minutesOfDay,
    required this.title,
    required this.body,
  });

  /// 1 = lunes … 7 = domingo (igual que `DateTime.weekday`).
  final int dayOfWeek;

  /// Minuto del día (0..1439).
  final int minutesOfDay;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder(día $dayOfWeek, ${minutesOfDay ~/ 60}:'
      '${(minutesOfDay % 60).toString().padLeft(2, '0')}, $title)';
}

abstract final class ReminderPlanner {
  static const _minutesPerDay = 24 * 60;

  /// Lista de avisos para [schedule] según [settings]. Vacía si los
  /// recordatorios están desactivados o no hay clases.
  static List<PlannedReminder> plan(ProcessedSchedule? schedule, LocalSettings settings) {
    if (!settings.remindersEnabled || schedule == null) return const [];

    final selected = settings.notificationScope == NotificationScope.selectedSubjects
        ? decodeSubjectSelection(settings.notificationSubjects)
        : null;

    final reminders = <PlannedReminder>[];
    for (final session in schedule.classes) {
      if (selected != null && !selected.contains(subjectSelectionKey(session.subjectName))) {
        continue;
      }
      final room = session.classroomName == null ? '' : ' · Salón ${session.classroomName}';

      // RF-19 / RF-20: avisos previos.
      for (final offset in settings.reminderOffsetsMinutes) {
        reminders.add(_at(
          session.dayOfWeek,
          session.startMinutes - offset,
          'Tu clase empieza pronto',
          '${session.subjectName} en $offset min (${session.startTime})$room',
        ));
      }
      // RF-21: aviso al inicio de la clase.
      if (settings.enableStartClassNotification) {
        reminders.add(_at(
          session.dayOfWeek,
          session.startMinutes,
          'Clase en curso',
          '${session.subjectName} (${session.startTime})$room',
        ));
      }
    }
    return reminders;
  }

  /// Normaliza minutos negativos (aviso antes de medianoche) al día anterior.
  static PlannedReminder _at(int day, int minutes, String title, String body) {
    var d = day;
    var m = minutes;
    while (m < 0) {
      m += _minutesPerDay;
      d = d == 1 ? 7 : d - 1;
    }
    return PlannedReminder(dayOfWeek: d, minutesOfDay: m % _minutesPerDay, title: title, body: body);
  }
}
