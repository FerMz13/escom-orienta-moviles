import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'schedule_dao.g.dart';

/// Horario activo junto con sus clases.
class ScheduleWithClassesRow {
  const ScheduleWithClassesRow(this.schedule, this.classes);
  final ProcessedScheduleRow schedule;
  final List<ClassSessionRow> classes;
}

@DriftAccessor(tables: [ProcessedSchedules, ClassSessions])
class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
  ScheduleDao(super.attachedDatabase);

  OrderingTerm get _byDayAndTime => OrderingTerm.asc(classSessions.dayOfWeek);

  // --- Horarios ---

  Future<int> insertSchedule(ProcessedSchedulesCompanion schedule) =>
      into(processedSchedules).insert(schedule);

  Future<int> deleteScheduleById(int scheduleId) =>
      (delete(processedSchedules)..where((s) => s.id.equals(scheduleId))).go();

  Future<int> deleteAllSchedules() => delete(processedSchedules).go();

  SimpleSelectStatement<$ProcessedSchedulesTable, ProcessedScheduleRow> _activeSchedule() =>
      select(processedSchedules)
        ..orderBy([(s) => OrderingTerm.desc(s.loadedAt), (s) => OrderingTerm.desc(s.id)])
        ..limit(1);

  Future<int?> getActiveScheduleId() async => (await _activeSchedule().getSingleOrNull())?.id;

  Future<int> countClassesForSchedule(int scheduleId) {
    final count = classSessions.id.count();
    final query = selectOnly(classSessions)
      ..addColumns([count])
      ..where(classSessions.scheduleId.equals(scheduleId));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<void> updateScheduleClassCount(int scheduleId, int totalClasses) =>
      (update(processedSchedules)..where((s) => s.id.equals(scheduleId)))
          .write(ProcessedSchedulesCompanion(totalClasses: Value(totalClasses)));

  Future<ScheduleWithClassesRow?> getActiveScheduleWithClasses() => transaction(() async {
        final schedule = await _activeSchedule().getSingleOrNull();
        if (schedule == null) return null;
        final classes = await (select(classSessions)
              ..where((c) => c.scheduleId.equals(schedule.id))
              ..orderBy([(_) => _byDayAndTime, (c) => OrderingTerm.asc(c.startTime)]))
            .get();
        return ScheduleWithClassesRow(schedule, classes);
      });

  /// Horario activo con sus clases; emite de nuevo ante cualquier cambio en
  /// horarios o clases.
  Stream<ScheduleWithClassesRow?> watchActiveScheduleWithClasses() async* {
    yield await getActiveScheduleWithClasses();
    await for (final _ in tableUpdates(
      TableUpdateQuery.onAllTables([processedSchedules, classSessions]),
    )) {
      yield await getActiveScheduleWithClasses();
    }
  }

  // --- Clases ---

  Future<void> insertClassSessions(List<ClassSessionsCompanion> classes) =>
      batch((b) => b.insertAll(classSessions, classes));

  Future<bool> updateClassSession(ClassSessionRow row) => update(classSessions).replace(row);

  Future<int> deleteClassSessionById(int id) =>
      (delete(classSessions)..where((c) => c.id.equals(id))).go();

  /// Borra todas las sesiones de una materia/grupo del horario.
  Future<int> deleteClassSessionsBySubject(int scheduleId, String subjectName, String? groupName) =>
      (delete(classSessions)
            ..where((c) =>
                c.scheduleId.equals(scheduleId) &
                c.subjectName.equals(subjectName) &
                (groupName == null ? c.groupName.isNull() : c.groupName.equals(groupName))))
          .go();

  Future<ClassSessionRow?> getClassSessionById(int id) =>
      (select(classSessions)..where((c) => c.id.equals(id))).getSingleOrNull();

  SimpleSelectStatement<$ClassSessionsTable, ClassSessionRow> _classes({int? dayOfWeek}) =>
      select(classSessions)
        ..where((c) => dayOfWeek == null ? const Constant(true) : c.dayOfWeek.equals(dayOfWeek))
        ..orderBy([(_) => _byDayAndTime, (c) => OrderingTerm.asc(c.startTime)]);

  Stream<List<ClassSessionRow>> watchAllClasses() => _classes().watch();
  Future<List<ClassSessionRow>> getAllClasses() => _classes().get();
  Stream<List<ClassSessionRow>> watchClassesByDay(int dayOfWeek) =>
      _classes(dayOfWeek: dayOfWeek).watch();
  Future<List<ClassSessionRow>> getClassesByDay(int dayOfWeek) =>
      _classes(dayOfWeek: dayOfWeek).get();

  Future<List<String>> getUniqueSubjects() {
    final query = selectOnly(classSessions, distinct: true)
      ..addColumns([classSessions.subjectName]);
    return query.map((row) => row.read(classSessions.subjectName)!).get();
  }
}
