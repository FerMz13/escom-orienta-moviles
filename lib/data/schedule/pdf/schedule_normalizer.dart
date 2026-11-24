import '../../../domain/schedule/schedule_models.dart';
import '../../../domain/text/text_normalization.dart';
import 'schedule_parser.dart';

/// Convierte las sesiones crudas del PDF en borradores listos para guardar
/// (portado de `ScheduleNormalizer.kt`).
///
/// - Día → 1..6, hora → `HH:mm`.
/// - Materia en formato legible ("Análisis De Algoritmos", siglas cortas en
///   mayúsculas).
/// - Grupo en mayúsculas; salón sin prefijos "Salón:".
/// - Elimina duplicados y ordena por día, hora y materia.
class ScheduleNormalizer {
  const ScheduleNormalizer();

  List<ClassSessionDraft> normalize(List<RawScheduleSession> rawSessions) {
    final seen = <String>{};
    final result = <ClassSessionDraft>[];
    for (final raw in rawSessions) {
      final day = dayOfWeekFromLabel(raw.dayName);
      final start = normalizeTime(raw.startTime);
      final end = normalizeTime(raw.endTime);
      if (day == null || start == null || end == null) continue;

      final classroom = _normalizeClassroom(raw.classroomName);
      final teacher = raw.teacherName == null ? null : cleanSpaces(raw.teacherName!);
      final draft = ClassSessionDraft(
        subjectName: _normalizeSubject(raw.subjectName),
        groupName: raw.groupName == null ? null : cleanSpaces(raw.groupName!).toUpperCase(),
        teacherName: teacher == null || teacher.isEmpty ? null : teacher,
        dayOfWeek: day,
        startTime: start,
        endTime: end,
        classroomName: classroom,
        classroomStatus: classroom == null ? ClassroomStatus.pending : ClassroomStatus.available,
        rawText: raw.rawText,
      );
      final key = '${draft.subjectName}|${draft.groupName}|${draft.dayOfWeek}|'
          '${draft.startTime}|${draft.endTime}|${draft.classroomName}';
      if (seen.add(key)) result.add(draft);
    }
    result.sort(compareDrafts);
    return result;
  }

  /// Orden por día, hora de inicio y materia.
  static int compareDrafts(ClassSessionDraft a, ClassSessionDraft b) {
    final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
    if (byDay != 0) return byDay;
    final byStart = a.startTime.compareTo(b.startTime);
    return byStart != 0 ? byStart : a.subjectName.compareTo(b.subjectName);
  }

  /// `lunes` → 1 … `sábado` → 6 (sin importar acentos ni mayúsculas).
  static int? dayOfWeekFromLabel(String label) =>
      _days[removeDiacritics(label).toLowerCase().trim()];

  static const _days = {
    'lunes': 1,
    'martes': 2,
    'miercoles': 3,
    'jueves': 4,
    'viernes': 5,
    'sabado': 6,
  };

  /// `7:00` / `07.00` → `07:00`.
  static String? normalizeTime(String value) {
    final match = _time.firstMatch(cleanSpaces(value));
    if (match == null) return null;
    final hour = int.tryParse(match[1]!);
    final minute = int.tryParse(match[2]!);
    if (hour == null || minute == null) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static final _time = RegExp(r'(\d{1,2})[:.](\d{2})');

  String _normalizeSubject(String value) =>
      _toReadableCase(cleanSpaces(value.replaceAll('|', ' / ')));

  String? _normalizeClassroom(String? value) {
    if (value == null) return null;
    final cleaned = cleanSpaces(value.replaceAll(_classroomPrefix, ''));
    return cleaned.isEmpty ? null : cleaned;
  }

  static final _classroomPrefix = RegExp(r'(?:sal[oó]n|aula)\s*:', caseSensitive: false);

  /// Cada palabra con mayúscula inicial; las de 1–2 letras (siglas, números
  /// romanos) en mayúsculas, salvo "de", "la", "el" y "en".
  static String _toReadableCase(String value) =>
      value.toLowerCase().split(' ').map((word) {
        if (word.isEmpty) return word;
        if (word.length <= 2 && !const {'de', 'la', 'el', 'en'}.contains(word)) {
          return word.toUpperCase();
        }
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
}
