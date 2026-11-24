import 'schedule_models.dart';

/// Par de clases del mismo día cuyos horarios se traslapan.
class ScheduleConflict {
  const ScheduleConflict(this.first, this.second);
  final ClassSessionData first;
  final ClassSessionData second;

  @override
  bool operator ==(Object other) =>
      other is ScheduleConflict && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);
}

/// Detección de traslapes (portado de `ScheduleConflictDetector.kt`).
///
/// Dos clases chocan si `inicioA < finB && inicioB < finA`; las que solo se
/// tocan (una termina 11:00 y otra empieza 11:00) no son conflicto. Las horas
/// inválidas nunca generan conflicto.
abstract final class ScheduleConflictDetector {
  /// ¿Alguno de los [drafts] choca con las clases ya guardadas?
  static bool conflictsWithExisting(
    List<ClassSessionData> existing,
    List<ClassSessionData> drafts,
  ) =>
      drafts.any((draft) => existing.any(
            (saved) => saved.dayOfWeek == draft.dayOfWeek && overlap(saved, draft),
          ));

  /// Todos los pares en conflicto, agrupados por día y en orden de aparición.
  static List<ScheduleConflict> detect(List<ClassSessionData> classes) {
    final byDay = <int, List<ClassSessionData>>{};
    for (final c in classes) {
      byDay.putIfAbsent(c.dayOfWeek, () => []).add(c);
    }
    return [
      for (final sameDay in byDay.values)
        for (var i = 0; i < sameDay.length; i++)
          for (var j = i + 1; j < sameDay.length; j++)
            if (overlap(sameDay[i], sameDay[j])) ScheduleConflict(sameDay[i], sameDay[j]),
    ];
  }

  static bool overlap(ClassSessionData a, ClassSessionData b) =>
      overlapTimes(a.startTime, a.endTime, b.startTime, b.endTime);

  static bool overlapTimes(String startA, String endA, String startB, String endB) {
    final sA = parseTime(startA), eA = parseTime(endA);
    final sB = parseTime(startB), eB = parseTime(endB);
    if (sA == null || eA == null || sB == null || eB == null) return false;
    return sA < eB && sB < eA;
  }

  static final RegExp _time = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$');

  /// Minutos desde medianoche para `HH:mm` o `HH:mm:ss` válidos (como
  /// `LocalTime.parse`), o `null`.
  static int? parseTime(String value) {
    final m = _time.firstMatch(value);
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    final s = m[3] == null ? 0 : int.parse(m[3]!);
    if (h > 23 || min > 59 || s > 59) return null;
    return h * 60 + min;
  }
}
