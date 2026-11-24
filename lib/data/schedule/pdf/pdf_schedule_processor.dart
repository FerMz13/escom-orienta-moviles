import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../domain/schedule/schedule_models.dart';
import 'pdf_text_extractor.dart';
import 'schedule_normalizer.dart';
import 'schedule_parser.dart';

sealed class ScheduleProcessingResult {
  const ScheduleProcessingResult();
}

class ScheduleProcessingSuccess extends ScheduleProcessingResult {
  const ScheduleProcessingSuccess({
    required this.sourceFileName,
    required this.status,
    required this.classes,
  });

  final String? sourceFileName;

  /// Uno de [ScheduleStatus].
  final String status;
  final List<ClassSessionDraft> classes;
}

class ScheduleProcessingError extends ScheduleProcessingResult {
  const ScheduleProcessingError(this.message, {this.cause});
  final String message;
  final Object? cause;
}

/// Procesa el horario PDF descargado del SAES (portado de
/// `PdfScheduleProcessor.kt`).
///
/// Recibe los bytes y el nombre del archivo (lo que entrega `file_picker`)
/// para no depender de URIs de Android.
class PdfScheduleProcessor {
  const PdfScheduleProcessor({
    this.extractor = const SyncfusionPdfTextExtractor(),
    this.parser = const ScheduleParser(),
    this.normalizer = const ScheduleNormalizer(),
  });

  final PdfTextSource extractor;
  final ScheduleParser parser;
  final ScheduleNormalizer normalizer;

  static const _notSaesMessage =
      'No se pudo identificar el horario. Verifica que el archivo corresponda al horario PDF del SAES.';

  ScheduleProcessingResult process(Uint8List bytes, {String? fileName}) {
    try {
      if (!isPdf(bytes, fileName)) {
        return const ScheduleProcessingError('El archivo seleccionado no es PDF.');
      }

      final document = extractor.extract(bytes);
      if (document.plainText.trim().isEmpty && document.tokens.isEmpty) {
        return const ScheduleProcessingError(
          'El PDF no contiene texto extraíble. Sube el horario original descargado del SAES.',
        );
      }

      final classes = preferSessionsWithClassroom(normalizer.normalize(parser.parse(document)));
      if (classes.isEmpty) return const ScheduleProcessingError(_notSaesMessage);

      return ScheduleProcessingSuccess(
        sourceFileName: fileName,
        status: classifyStatus(classes),
        classes: classes,
      );
    } catch (error, stack) {
      debugPrint('PdfScheduleProcessor: $error\n$stack');
      return ScheduleProcessingError(
        'No se pudo procesar el PDF. Verifica que el archivo corresponda al horario PDF del SAES.',
        cause: error,
      );
    }
  }

  /// Acepta archivos que empiezan con `%PDF` o terminan en `.pdf`.
  static bool isPdf(Uint8List bytes, String? fileName) {
    const magic = [0x25, 0x50, 0x44, 0x46]; // %PDF
    if (bytes.length >= 4 &&
        bytes[0] == magic[0] &&
        bytes[1] == magic[1] &&
        bytes[2] == magic[2] &&
        bytes[3] == magic[3]) {
      return true;
    }
    return fileName?.toLowerCase().endsWith('.pdf') ?? false;
  }

  static String classifyStatus(List<ClassSessionDraft> classes) {
    final withRoom = classes.where((c) => (c.classroomName ?? '').trim().isNotEmpty).length;
    if (withRoom == 0) return ScheduleStatus.noRoomsPublished;
    if (withRoom == classes.length) return ScheduleStatus.complete;
    return ScheduleStatus.partialRooms;
  }

  /// Si la misma clase aparece con y sin salón, se queda la que tiene salón.
  static List<ClassSessionDraft> preferSessionsWithClassroom(List<ClassSessionDraft> classes) {
    String key(String v) => v.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final groups = <String, List<ClassSessionDraft>>{};
    for (final c in classes) {
      groups
          .putIfAbsent(
            [key(c.subjectName), key(c.groupName ?? ''), c.dayOfWeek, c.startTime, c.endTime].join('|'),
            () => [],
          )
          .add(c);
    }
    return [
      for (final sessions in groups.values)
        sessions.where((s) => (s.classroomName ?? '').trim().isNotEmpty).firstOrNull ?? sessions.first,
    ]..sort(ScheduleNormalizer.compareDrafts);
  }
}
