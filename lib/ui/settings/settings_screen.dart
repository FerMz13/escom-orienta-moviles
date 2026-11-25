import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/schedule/classroom_rules.dart';
import '../../domain/schedule/schedule_models.dart';
import '../common/common_widgets.dart';
import '../providers.dart';
import '../theme/app_theme.dart';

/// Configuración y personalización local (RF-41), recordatorios (RF-18 a RF-22)
/// y gestión de la información guardada en el dispositivo (RF-35).
///
/// Cada cambio se guarda al instante en la base local; `notificationSyncProvider`
/// reprograma los recordatorios automáticamente al detectar el cambio (RF-23).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AsyncValueView(
        value: settings,
        onRetry: () => ref.invalidate(localSettingsProvider),
        data: (s) => _SettingsBody(settings: s),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});
  final LocalSettings settings;

  Future<void> _update(WidgetRef ref, LocalSettings Function(LocalSettings) change) =>
      ref.read(scheduleRepositoryProvider).transformLocalSettings(change);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = settings;
    final reminders = s.remindersEnabled;
    final subjects = {
      for (final c in ref.watch(activeScheduleProvider).value?.classes ?? const <ClassSession>[])
        subjectSelectionKey(c.subjectName): c.subjectName,
    };
    final selected = decodeSubjectSelection(s.notificationSubjects);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // --- Personalización (RF-41) ---
        const SectionTitle('Apariencia', icon: Icons.palette_outlined),
        Text('Tema', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(value: AppThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: AppThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: AppThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {s.themeMode},
          onSelectionChanged: (v) => _update(ref, (c) => c.copyWith(themeMode: v.single)),
        ),
        const SizedBox(height: 16),
        Text('Colores del horario', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in SchedulePalettes.selectable)
              ChoiceChip(
                selected: s.schedulePaletteMode == mode,
                onSelected: (_) => _update(ref, (c) => c.copyWith(schedulePaletteMode: mode)),
                avatar: _Swatch(SchedulePalettes.colors(mode)),
                label: Text(SchedulePalettes.label(mode)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Nombre para mostrar'),
          subtitle: Text(s.sanitizedUserAlias),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editAlias(context, ref),
        ),

        // --- Recordatorios (RF-18 a RF-22) ---
        const SectionTitle('Recordatorios de clase', icon: Icons.notifications_outlined),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Recordatorios activados'),
                subtitle: const Text('Avisos generados a partir de tu horario'),
                value: reminders,
                onChanged: (v) => _update(ref, (c) => c.copyWith(remindersEnabled: v)),
              ),
              const Divider(height: 0),
              SwitchListTile(
                title: const Text('Avisar antes de la clase'),
                value: s.sanitizedReminderInterval > 0,
                onChanged: reminders
                    ? (v) => _update(ref, (c) => c.copyWith(classNotificationMinutes: v ? 10 : 0))
                    : null,
              ),
              if (s.sanitizedReminderInterval > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad de avisos', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      SegmentedButton<int>(
                        segments: [
                          for (final n in LocalSettings.allowedReminderCounts)
                            ButtonSegment(value: n, label: Text('$n')),
                        ],
                        selected: {s.sanitizedReminderCount},
                        onSelectionChanged: reminders
                            ? (v) => _update(ref, (c) => c.copyWith(reminderCount: v.single))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text('Intervalo entre avisos', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final m in LocalSettings.allowedReminderIntervals)
                            ChoiceChip(
                              label: Text('$m min'),
                              selected: s.sanitizedReminderInterval == m,
                              onSelected: reminders
                                  ? (_) => _update(ref, (c) => c.copyWith(classNotificationMinutes: m))
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recibirás avisos ${s.reminderOffsetsMinutes.map((m) => '$m').join(', ')} '
                        'min antes de cada clase.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 0),
              SwitchListTile(
                title: const Text('Avisar al iniciar la clase'),
                value: s.enableStartClassNotification,
                onChanged: reminders
                    ? (v) => _update(ref, (c) => c.copyWith(enableStartClassNotification: v))
                    : null,
              ),
              const Divider(height: 0),
              RadioGroup<NotificationScope>(
                groupValue: s.notificationScope,
                onChanged: (v) {
                  if (reminders && v != null) _update(ref, (c) => c.copyWith(notificationScope: v));
                },
                child: Column(
                  children: [
                    RadioListTile(
                      enabled: reminders,
                      value: NotificationScope.allSubjects,
                      title: const Text('Todas las materias'),
                    ),
                    RadioListTile(
                      enabled: reminders,
                      value: NotificationScope.selectedSubjects,
                      title: const Text('Solo materias seleccionadas'),
                    ),
                  ],
                ),
              ),
              if (s.notificationScope == NotificationScope.selectedSubjects)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: subjects.isEmpty
                      ? Text('Carga tu horario para elegir materias.', style: theme.textTheme.bodySmall)
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final MapEntry(:key, :value) in subjects.entries)
                              FilterChip(
                                label: Text(value),
                                selected: selected.contains(key),
                                onSelected: reminders
                                    ? (on) => _update(ref, (c) {
                                          final next = decodeSubjectSelection(c.notificationSubjects);
                                          on ? next.add(key) : next.remove(key);
                                          return c.copyWith(notificationSubjects: encodeSubjectSelection(next));
                                        })
                                    : null,
                              ),
                          ],
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final service = ref.read(notificationServiceProvider);
                await service.requestPermissions();
                await service.showTest();
                if (context.mounted) showSnack(context, 'Notificación de prueba enviada.');
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Probar y dar permisos'),
            ),
          ],
        ),

        // --- Información local (RF-35) ---
        const SectionTitle('Datos en este dispositivo', icon: Icons.storage_outlined),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Restablecer ajustes'),
                subtitle: const Text('Vuelve a la configuración inicial; tu horario se conserva.'),
                onTap: () async {
                  final ok = await confirmDeletion(
                    context,
                    title: '¿Restablecer ajustes?',
                    message: 'Tema, colores y recordatorios volverán a sus valores iniciales.',
                    confirmLabel: 'Restablecer',
                  );
                  if (ok) await ref.read(scheduleRepositoryProvider).updateLocalSettings(const LocalSettings());
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                title: const Text('Borrar datos locales'),
                subtitle: const Text('Elimina tu horario y restablece los ajustes.'),
                onTap: () async {
                  final ok = await confirmDeletion(
                    context,
                    title: '¿Borrar datos locales?',
                    message: 'Se eliminará tu horario guardado y se restablecerán los ajustes. '
                        'Esta acción no se puede deshacer.',
                    confirmLabel: 'Borrar',
                  );
                  if (!ok) return;
                  await ref.read(scheduleRepositoryProvider).clearLocalData();
                  if (context.mounted) showSnack(context, 'Datos locales borrados.');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editAlias(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: settings.userAlias);
    final alias = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nombre para mostrar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: LocalSettings.maxUserAliasLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre o apodo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (alias != null) await _update(ref, (c) => c.copyWith(userAlias: alias));
  }
}

/// Muestra de los primeros colores de una paleta.
class _Swatch extends StatelessWidget {
  const _Swatch(this.colors);
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 24,
        height: 12,
        child: Row(
          children: [
            for (final c in colors.take(3))
              Expanded(child: ColoredBox(color: c)),
          ],
        ),
      );
}
