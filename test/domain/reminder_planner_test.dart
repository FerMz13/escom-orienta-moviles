import 'package:escom_orienta_moviles/domain/schedule/classroom_rules.dart';
import 'package:escom_orienta_moviles/domain/schedule/reminder_planner.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSession _session(int id, String subject, int day, String start, {String? room}) => ClassSession(
      id: id,
      scheduleId: 1,
      subjectName: subject,
      dayOfWeek: day,
      startTime: start,
      endTime: '23:00',
      classroomName: room,
      classroomStatus: room == null ? ClassroomStatus.pending : ClassroomStatus.available,
    );

ProcessedSchedule _schedule(List<ClassSession> classes) => ProcessedSchedule(
      id: 1,
      loadedAt: DateTime(2026),
      publicationStatus: PublicationStatus.manual,
      totalClasses: classes.length,
      classes: classes,
    );

void main() {
  final schedule = _schedule([
    _session(1, 'Cálculo', 1, '07:00', room: '2102'),
    _session(2, 'Redes', 3, '10:30'),
  ]);

  group('ReminderPlanner (RF-17 a RF-21)', () {
    test('RF-17: genera avisos solo a partir de las clases del horario', () {
      final plan = ReminderPlanner.plan(schedule, const LocalSettings());
      // 1 aviso previo + 1 al inicio, por cada una de las 2 clases.
      expect(plan, hasLength(4));
      expect(ReminderPlanner.plan(null, const LocalSettings()), isEmpty);
      expect(ReminderPlanner.plan(_schedule(const []), const LocalSettings()), isEmpty);
    });

    test('RF-18: con recordatorios desactivados no se programa nada', () {
      final plan = ReminderPlanner.plan(schedule, const LocalSettings(remindersEnabled: false));
      expect(plan, isEmpty);
    });

    test('RF-19/RF-20: cantidad e intervalo de avisos previos', () {
      const settings = LocalSettings(
        reminderCount: 3,
        classNotificationMinutes: 15,
        enableStartClassNotification: false,
      );
      final plan = ReminderPlanner.plan(_schedule([schedule.classes.first]), settings);
      // Clase a las 07:00 → 06:15, 06:30, 06:45.
      expect(plan.map((r) => r.minutesOfDay), [6 * 60 + 15, 6 * 60 + 30, 6 * 60 + 45]);
      expect(plan.every((r) => r.dayOfWeek == 1), isTrue);
      expect(plan.last.body, contains('Salón 2102'));
    });

    test('RF-20: valores fuera de rango se acotan a los admitidos', () {
      const settings = LocalSettings(reminderCount: 99, classNotificationMinutes: 500);
      expect(settings.sanitizedReminderCount, LocalSettings.allowedReminderCounts.last);
      expect(settings.sanitizedReminderInterval, LocalSettings.allowedReminderIntervals.last);
      expect(const LocalSettings(classNotificationMinutes: 0).reminderOffsetsMinutes, isEmpty);
    });

    test('RF-21: aviso al inicio de la clase según la configuración', () {
      const onlyStart = LocalSettings(classNotificationMinutes: 0);
      final plan = ReminderPlanner.plan(_schedule([schedule.classes.last]), onlyStart);
      expect(plan, hasLength(1));
      expect(plan.single.dayOfWeek, 3);
      expect(plan.single.minutesOfDay, 10 * 60 + 30);
      expect(plan.single.title, 'Clase en curso');

      const noStart = LocalSettings(enableStartClassNotification: false);
      expect(ReminderPlanner.plan(schedule, noStart).any((r) => r.title == 'Clase en curso'), isFalse);
    });

    test('solo materias seleccionadas (claves de subjectSelectionKey)', () {
      final settings = LocalSettings(
        notificationScope: NotificationScope.selectedSubjects,
        notificationSubjects: encodeSubjectSelection({subjectSelectionKey('Cálculo')}),
      );
      final plan = ReminderPlanner.plan(schedule, settings);
      expect(plan, hasLength(2));
      expect(plan.every((r) => r.body.contains('Cálculo')), isTrue);
    });

    test('un aviso antes de medianoche pasa al día anterior', () {
      final early = _schedule([_session(1, 'Temprano', 1, '00:05')]);
      const settings = LocalSettings(classNotificationMinutes: 10, enableStartClassNotification: false);
      final plan = ReminderPlanner.plan(early, settings);
      expect(plan.single.dayOfWeek, 7); // domingo
      expect(plan.single.minutesOfDay, 23 * 60 + 55);
    });
  });
}
