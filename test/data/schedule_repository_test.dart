import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:escom_orienta_moviles/data/database/app_database.dart';
import 'package:escom_orienta_moviles/data/schedule/schedule_repository.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSessionDraft draft(String subject, int day, String start, String end,
        {String? group = '3CM1', String? room}) =>
    ClassSessionDraft(
      subjectName: subject,
      groupName: group,
      dayOfWeek: day,
      startTime: start,
      endTime: end,
      classroomName: room,
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ScheduleRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepository(db, clock: () => DateTime(2026, 11, 23, 9));
  });
  tearDown(() => db.close());

  test('guarda un horario completo y lo reemplaza al cargar otro', () async {
    await repository.insertCompleteScheduleWithClasses(
      publicationStatus: PublicationStatus.pdfProcessed,
      sourceFileName: 'a.pdf',
      classes: [draft('Calculo', 1, '07:00', '08:30', room: '1104'), draft('Redes', 2, '10:30', '12:00')],
    );
    await repository.insertCompleteScheduleWithClasses(
      publicationStatus: PublicationStatus.pdfProcessed,
      sourceFileName: 'b.pdf',
      classes: [draft('Software', 3, '08:30', '10:00')],
    );
    final active = await repository.watchActiveScheduleWithClasses().first;
    expect(active?.sourceFileName, 'b.pdf');
    expect(active?.totalClasses, 1);
    expect((await repository.getAllClasses()).map((c) => c.subjectName), ['Software']);
  });

  test('clases manuales crean horario MANUAL y actualizan el conteo', () async {
    await repository.saveManualClassSessions([draft('A', 1, '07:00', '08:30'), draft('B', 1, '08:30', '10:00')]);
    final schedule = await repository.watchActiveScheduleWithClasses().first;
    expect(schedule?.publicationStatus, PublicationStatus.manual);
    expect(schedule?.totalClasses, 2);

    await repository.deleteClassSession(schedule!.classes.first.id);
    expect((await repository.watchActiveScheduleWithClasses().first)?.totalClasses, 1);
  });

  test('borrar el horario borra sus clases en cascada', () async {
    await repository.saveManualClassSessions([draft('A', 1, '07:00', '08:30')]);
    await repository.deleteCurrentSchedule();
    expect(await repository.getAllClasses(), isEmpty);
    expect(await repository.watchActiveScheduleWithClasses().first, isNull);
  });

  test('reemplazar sesiones de una materia respeta el grupo', () async {
    await repository.saveManualClassSessions([
      draft('A', 1, '07:00', '08:30', group: '3CM1'),
      draft('A', 2, '07:00', '08:30', group: '3CM1'),
      draft('A', 3, '07:00', '08:30', group: '3CM2'),
    ]);
    final original = (await repository.getAllClasses()).first;
    await repository.replaceSubjectSessions(original, [draft('A', 5, '12:00', '13:30')]);
    final remaining = await repository.getAllClasses();
    expect([for (final c in remaining) (c.dayOfWeek, c.groupName)], [(3, '3CM2'), (5, '3CM1')]);
  });

  test('clase actual y siguiente', () async {
    await repository.saveManualClassSessions(
        [draft('A', 1, '07:00', '08:30'), draft('B', 1, '10:30', '12:00'), draft('C', 1, '08:30', '10:00')]);
    expect((await repository.getCurrentClass(1, 8 * 60))?.subjectName, 'A');
    expect((await repository.getCurrentClass(1, 8 * 60 + 30))?.subjectName, 'C');
    expect((await repository.getNextClass(1, 8 * 60))?.subjectName, 'C');
    expect(await repository.getNextClass(1, 13 * 60), isNull);
  });

  test('la vista del horario activo emite al editar clases', () async {
    await repository.saveManualClassSessions([draft('A', 1, '07:00', '08:30')]);
    final emissions = repository.watchActiveScheduleWithClasses().map((s) => s?.classes.length);
    final expectation = expectLater(emissions, emitsInOrder([1, 2]));
    await Future<void>.delayed(Duration.zero);
    await repository.saveManualClassSessions([draft('B', 2, '07:00', '08:30')]);
    await expectation;
  });

  group('Preferencias', () {
    test('se crean con valores por defecto', () async {
      final settings = await repository.getOrCreateLocalSettings();
      expect(settings.userAlias, 'Alumno');
      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.classNotificationMinutes, 10);
    });

    test('el alias se recorta a 20 caracteres y nunca queda vacío', () async {
      await repository.updateLocalSettings(const LocalSettings(userAlias: '  Un alias demasiado largo para caber  '));
      expect((await repository.getOrCreateLocalSettings()).userAlias, 'Un alias demasiado l');
      await repository.updateLocalSettings(const LocalSettings(userAlias: '   '));
      expect((await repository.getOrCreateLocalSettings()).userAlias, 'Alumno');
    });

    test('transformaciones concurrentes no se pisan', () async {
      await Future.wait([
        repository.transformLocalSettings((s) => s.copyWith(themeMode: AppThemeMode.dark)),
        repository.transformLocalSettings((s) => s.copyWith(classNotificationMinutes: 25)),
      ]);
      final settings = await repository.getOrCreateLocalSettings();
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.classNotificationMinutes, 25);
    });

    test('RF-22/RF-41: los ajustes de recordatorios y apariencia persisten', () async {
      await repository.transformLocalSettings((s) => s.copyWith(
            remindersEnabled: false,
            reminderCount: 3,
            classNotificationMinutes: 15,
            enableStartClassNotification: false,
            schedulePaletteMode: SchedulePaletteMode.accessible,
          ));
      final settings = await repository.getOrCreateLocalSettings();
      expect(settings.remindersEnabled, isFalse);
      expect(settings.reminderCount, 3);
      expect(settings.classNotificationMinutes, 15);
      expect(settings.enableStartClassNotification, isFalse);
      expect(settings.schedulePaletteMode, SchedulePaletteMode.accessible);
    });

    test('clearLocalData restablece todo', () async {
      await repository.saveManualClassSessions([draft('A', 1, '07:00', '08:30')]);
      await repository.updateLocalSettings(const LocalSettings(userAlias: 'Fer', themeMode: AppThemeMode.dark));
      await repository.clearLocalData();
      expect(await repository.getAllClasses(), isEmpty);
      expect((await repository.getOrCreateLocalSettings()).themeMode, AppThemeMode.system);
    });
  });
}
