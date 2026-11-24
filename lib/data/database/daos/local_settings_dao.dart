import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'local_settings_dao.g.dart';

@DriftAccessor(tables: [LocalSettingsTable])
class LocalSettingsDao extends DatabaseAccessor<AppDatabase> with _$LocalSettingsDaoMixin {
  LocalSettingsDao(super.attachedDatabase);

  static const settingsId = 1;

  SimpleSelectStatement<$LocalSettingsTableTable, LocalSettingsRow> get _row =>
      select(localSettingsTable)..where((s) => s.id.equals(settingsId));

  Stream<LocalSettingsRow?> watchSettings() => _row.watchSingleOrNull();

  Future<LocalSettingsRow?> getSettings() => _row.getSingleOrNull();

  /// Inserta o reemplaza la fila única de preferencias.
  Future<void> upsertSettings(LocalSettingsTableCompanion settings) =>
      into(localSettingsTable)
          .insertOnConflictUpdate(settings.copyWith(id: const Value(settingsId)));

  /// Restablece las preferencias a sus valores por defecto.
  Future<void> resetSettings() =>
      into(localSettingsTable).insert(
        const LocalSettingsTableCompanion(id: Value(settingsId)),
        mode: InsertMode.insertOrReplace,
      );
}
