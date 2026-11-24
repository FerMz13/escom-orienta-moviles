// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_dao.dart';

// ignore_for_file: type=lint
mixin _$ScheduleDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProcessedSchedulesTable get processedSchedules =>
      attachedDatabase.processedSchedules;
  $ClassSessionsTable get classSessions => attachedDatabase.classSessions;
  ScheduleDaoManager get managers => ScheduleDaoManager(this);
}

class ScheduleDaoManager {
  final _$ScheduleDaoMixin _db;
  ScheduleDaoManager(this._db);
  $$ProcessedSchedulesTableTableManager get processedSchedules =>
      $$ProcessedSchedulesTableTableManager(
        _db.attachedDatabase,
        _db.processedSchedules,
      );
  $$ClassSessionsTableTableManager get classSessions =>
      $$ClassSessionsTableTableManager(_db.attachedDatabase, _db.classSessions);
}
