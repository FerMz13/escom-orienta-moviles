import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/schedule/pdf/pdf_schedule_processor.dart';
import '../../domain/schedule/schedule_conflict_detector.dart';
import '../../domain/schedule/schedule_models.dart';
import '../common/common_widgets.dart';
import '../providers.dart';

/// Se ejecuta en un isolate: Syncfusion es CPU intensivo y bloquearía la UI.
ScheduleProcessingResult _processInBackground((Uint8List, String?) args) =>
    const PdfScheduleProcessor().process(args.$1, fileName: args.$2);

/// Selecciona el PDF del SAES, lo procesa, muestra una vista previa y guarda.
Future<void> importSchedulePdf(BuildContext context, WidgetRef ref) async {
  final files = await FilePicker.pickFiles(
    dialogTitle: 'Selecciona tu horario del SAES',
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );
  if (files.isEmpty || !context.mounted) return;
  final file = files.first;

  final progress = _showProgress(context);
  ScheduleProcessingResult result;
  try {
    final bytes = await file.readAsBytes();
    result = await compute(_processInBackground, (bytes, file.name));
  } catch (error) {
    result = ScheduleProcessingError('No se pudo leer el archivo seleccionado.', cause: error);
  } finally {
    progress.close();
  }
  if (!context.mounted) return;

  switch (result) {
    case ScheduleProcessingError(:final message):
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.picture_as_pdf),
          title: const Text('No se pudo cargar el horario'),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
        ),
      );
    case final ScheduleProcessingSuccess success:
      final hasSchedule = ref.read(activeScheduleProvider).value != null;
      final keepTeachers = await showDialog<bool>(
        context: context,
        builder: (context) => _PreviewDialog(result: success, replacesExisting: hasSchedule),
      );
      if (keepTeachers == null || !context.mounted) return;
      final classes = keepTeachers
          ? success.classes
          : [
              for (final c in success.classes)
                ClassSessionDraft(
                  subjectName: c.subjectName,
                  groupName: c.groupName,
                  dayOfWeek: c.dayOfWeek,
                  startTime: c.startTime,
                  endTime: c.endTime,
                  classroomName: c.classroomName,
                  classroomStatus: c.classroomStatus,
                  rawText: c.rawText,
                ),
            ];
      await ref.read(scheduleRepositoryProvider).insertCompleteScheduleWithClasses(
            publicationStatus: PublicationStatus.pdfProcessed,
            sourceFileName: success.sourceFileName,
            classes: classes,
          );
      if (context.mounted) showSnack(context, 'Horario cargado: ${classes.length} clases.');
  }
}

NavigatorState _showProgressNavigator(BuildContext context) => Navigator.of(context, rootNavigator: true);

({void Function() close}) _showProgress(BuildContext context) {
  final navigator = _showProgressNavigator(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Procesando PDF…\nExtrayendo materias, horarios y salones')),
          ],
        ),
      ),
    ),
  );
  return (close: () => navigator.pop());
}

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({required this.result, required this.replacesExisting});
  final ScheduleProcessingSuccess result;
  final bool replacesExisting;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  bool _keepTeachers = true;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final subjects = {for (final c in result.classes) c.subjectName};
    final conflicts = ScheduleConflictDetector.detect(result.classes);
    final hasTeachers = result.classes.any((c) => c.teacherName != null);
    final statusText = switch (result.status) {
      ScheduleStatus.complete => 'Todas las clases tienen salón asignado.',
      ScheduleStatus.partialRooms => 'Algunas clases aún no tienen salón publicado.',
      _ => 'El SAES aún no publica salones para este horario.',
    };

    return AlertDialog(
      title: const Text('Horario detectado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${subjects.length} materias · ${result.classes.length} clases'),
            const SizedBox(height: 8),
            Text(statusText),
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${conflicts.length} traslape(s) de horario. Se conservan ambas clases para revisión.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            for (final subject in subjects.take(8)) Text('• $subject'),
            if (subjects.length > 8) Text('… y ${subjects.length - 8} más'),
            if (hasTeachers)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Guardar nombres de profesores'),
                value: _keepTeachers,
                onChanged: (v) => setState(() => _keepTeachers = v),
              ),
            if (widget.replacesExisting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Se reemplazará tu horario actual.'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, _keepTeachers), child: const Text('Guardar')),
      ],
    );
  }
}
