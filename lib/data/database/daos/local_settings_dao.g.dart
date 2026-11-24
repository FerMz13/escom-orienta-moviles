// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalSettingsTableTable get localSettingsTable =>
      attachedDatabase.localSettingsTable;
  LocalSettingsDaoManager get managers => LocalSettingsDaoManager(this);
}

class LocalSettingsDaoManager {
  final _$LocalSettingsDaoMixin _db;
  LocalSettingsDaoManager(this._db);
  $$LocalSettingsTableTableTableManager get localSettingsTable =>
      $$LocalSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.localSettingsTable,
      );
}
