import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/schedule/schedule_conflict_detector.dart';
import '../../domain/schedule/schedule_models.dart';
import '../../navigation/app_routes.dart';
import '../common/common_widgets.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'class_form_sheet.dart';
import 'pdf_import_flow.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late int _day = DateTime.now().weekday.clamp(1, 6);

  Future<void> _addClass(List<ClassSession> existing) async {
    final draft = await showClassForm(context, initialDay: _day);
    if (draft == null || !mounted) return;
    if (!await _confirmIfConflicts(existing, draft)) return;
    await ref.read(scheduleRepositoryProvider).saveManualClassSessions([draft]);
    if (mounted) setState(() => _day = draft.dayOfWeek);
  }

  Future<void> _editClass(ClassSession session, List<ClassSession> existing) async {
    final draft = await showClassForm(context, initial: session);
    if (draft == null || !mounted) return;
    if (!await _confirmIfConflicts(existing.where((c) => c.id != session.id).toList(), draft)) return;
    await ref.read(scheduleRepositoryProvider).updateClassSession(ClassSession(
          id: session.id,
          scheduleId: session.scheduleId,
          subjectName: draft.subjectName,
          groupName: draft.groupName,
          teacherName: draft.teacherName,
          dayOfWeek: draft.dayOfWeek,
          startTime: draft.startTime,
          endTime: draft.endTime,
          classroomName: draft.classroomName,
          classroomStatus: draft.classroomStatus,
          rawText: session.rawText,
        ));
  }

  /// Los traslapes se permiten (el SAES a veces los tiene), pero se avisan.
  Future<bool> _confirmIfConflicts(List<ClassSession> existing, ClassSessionDraft draft) async {
    final clashes = existing
        .where((c) => c.dayOfWeek == draft.dayOfWeek && ScheduleConflictDetector.overlap(c, draft))
        .toList();
    if (clashes.isEmpty) return true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: const Text('Traslape de horario'),
        content: Text('Esta clase se cruza con:\n'
            '${clashes.map((c) => '• ${c.subjectName} (${c.startTime} - ${c.endTime})').join('\n')}\n\n'
            '¿Guardarla de todos modos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _deleteSchedule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar horario?'),
        content: const Text('Se borrarán todas tus clases guardadas en este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed ?? false) await ref.read(scheduleRepositoryProvider).deleteCurrentSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(activeScheduleProvider);
    final classes = schedule.value?.classes ?? const <ClassSession>[];
    final hasClasses = classes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi horario'),
        actions: [
          IconButton(
            tooltip: 'Cargar horario PDF',
            icon: const Icon(Icons.upload_file),
            onPressed: () => importSchedulePdf(context, ref),
          ),
          if (schedule.value != null)
            PopupMenuButton<String>(
              onSelected: (value) => switch (value) {
                'delete' => _deleteSchedule(),
                _ => null,
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete', child: Text('Eliminar horario')),
              ],
            ),
        ],
      ),
      floatingActionButton: hasClasses
          ? FloatingActionButton.extended(
              onPressed: () => _addClass(classes),
              icon: const Icon(Icons.add),
              label: const Text('Agregar materia'),
            )
          : null,
      body: AsyncValueView(
        value: schedule,
        data: (schedule) {
          if (schedule == null || schedule.classes.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_month,
              title: 'No hay horario cargado',
              message: 'Puedes cargar el PDF del SAES o capturar tus clases manualmente.',
              action: Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => importSchedulePdf(context, ref),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Cargar horario PDF'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _addClass(const []),
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Crear horario manual'),
                  ),
                ],
              ),
            );
          }
          return _ScheduleBody(
            schedule: schedule,
            day: _day,
            onDayChanged: (d) => setState(() => _day = d),
            onEdit: (session) => _editClass(session, schedule.classes),
            onAddForDay: () => _addClass(schedule.classes),
          );
        },
      ),
    );
  }
}

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({
    required this.schedule,
    required this.day,
    required this.onDayChanged,
    required this.onEdit,
    required this.onAddForDay,
  });

  final ProcessedSchedule schedule;
  final int day;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<ClassSession> onEdit;
  final VoidCallback onAddForDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conflicts = ScheduleConflictDetector.detect(schedule.classes);
    final conflicting = {for (final c in conflicts) ...[c.first, c.second]};
    final dayClasses = schedule.classes.where((c) => c.dayOfWeek == day).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    final pendingRooms = schedule.classes.where((c) => c.classroomName == null).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Text(
          [
            '${schedule.totalClasses} clases',
            if (schedule.sourceFileName != null) schedule.sourceFileName!
            else if (schedule.publicationStatus == PublicationStatus.manual) 'captura manual',
          ].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (pendingRooms > 0)
          _Banner(
            icon: Icons.meeting_room_outlined,
            color: theme.colorScheme.tertiary,
            text: '$pendingRooms clase(s) sin salón publicado. Puedes agregarlo editando la clase.',
          ),
        if (conflicts.isNotEmpty)
          _Banner(
            icon: Icons.warning_amber,
            color: theme.colorScheme.error,
            text: 'Hay ${conflicts.length} traslape(s) en tu horario. Se conservan ambas clases para revisión.',
          ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var d = 1; d <= 6; d++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      '${weekDayShortNames[d - 1]} '
                      '(${schedule.classes.where((c) => c.dayOfWeek == d).length})',
                    ),
                    selected: d == day,
                    onSelected: (_) => onDayChanged(d),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (dayClasses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text('Sin clases el ${dayName(day).toLowerCase()}', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onAddForDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar materia'),
                ),
              ],
            ),
          )
        else
          for (final session in dayClasses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClassCard(
                session: session,
                hasConflict: conflicting.contains(session),
                onTap: () => _showActions(context, ref, session),
              ),
            ),
      ],
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref, ClassSession session) async {
    final repository = ref.read(scheduleRepositoryProvider);
    final classroom = session.classroomName;
    final place = classroom == null ? null : await ref.read(placeForClassroomProvider(classroom).future);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(session.subjectName, style: Theme.of(sheetContext).textTheme.titleMedium),
              subtitle: Text([
                '${dayName(session.dayOfWeek)} ${session.startTime} - ${session.endTime}',
                if (session.groupName != null) 'Grupo ${session.groupName}',
                if (session.teacherName != null) session.teacherName!,
              ].join('\n')),
            ),
            const Divider(),
            ListTile(
              enabled: place != null,
              leading: const Icon(Icons.directions_walk),
              title: Text(classroom == null ? 'Salón aún no asignado' : 'Cómo llegar al salón $classroom'),
              subtitle: classroom != null && place == null
                  ? const Text('No se ubica el salón dentro del mapa de ESCOM.')
                  : null,
              onTap: () {
                Navigator.pop(sheetContext);
                context.go(AppRoutes.mapFor(placeId: place!.id, route: true));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar clase'),
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Eliminar esta sesión'),
              onTap: () {
                Navigator.pop(sheetContext);
                repository.deleteClassSession(session.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Eliminar materia'),
              subtitle: Text('Se eliminarán todas las sesiones de ${session.subjectName}.'),
              onTap: () {
                Navigator.pop(sheetContext);
                repository.deleteSubjectSessions(session);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.session, required this.hasConflict, required this.onTap});

  final ClassSession session;
  final bool hasConflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: hasConflict ? theme.colorScheme.error : EscomColors.blue),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${session.startTime} - ${session.endTime}', style: theme.textTheme.labelLarge),
                          const Spacer(),
                          if (hasConflict)
                            Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(session.subjectName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        [
                          session.classroomName == null ? 'Salón pendiente' : 'Salón ${session.classroomName}',
                          if (session.groupName != null) 'Grupo ${session.groupName}',
                        ].join(' · '),
                        style: muted,
                      ),
                      if (session.teacherName != null) Text(session.teacherName!, style: muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}
