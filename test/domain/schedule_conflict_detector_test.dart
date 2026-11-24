import 'package:escom_orienta_moviles/domain/schedule/classroom_rules.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_conflict_detector.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

ClassSession session(int id, String start, String end, {int day = 1}) => ClassSession(
      id: id,
      scheduleId: 1,
      subjectName: 'Materia $id',
      dayOfWeek: day,
      startTime: start,
      endTime: end,
      classroomStatus: ClassroomStatus.pending,
    );

void main() {
  group('ScheduleConflictDetector', () {
    test('reporta clases traslapadas sin descartarlas', () {
      final a = session(1, '10:00', '11:30'), b = session(2, '11:00', '12:00');
      final classes = [a, b];
      expect(ScheduleConflictDetector.detect(classes), [ScheduleConflict(a, b)]);
      expect(classes, hasLength(2));
    });

    test('clases que solo se tocan no son conflicto', () {
      expect(
        ScheduleConflictDetector.detect([session(1, '10:00', '11:00'), session(2, '11:00', '12:00')]),
        isEmpty,
      );
    });

    test('días distintos no chocan', () {
      expect(
        ScheduleConflictDetector.detect(
            [session(1, '10:00', '12:00'), session(2, '10:00', '12:00', day: 2)]),
        isEmpty,
      );
    });

    test('detecta conflicto de un borrador antes de guardarlo', () {
      final existing = [session(1, '10:00', '11:30')];
      final overlap = ClassSessionDraft(
          subjectName: 'Nueva', dayOfWeek: 1, startTime: '11:00', endTime: '12:00');
      final boundary = overlap.copyWith(startTime: '11:30');
      expect(ScheduleConflictDetector.conflictsWithExisting(existing, [overlap]), isTrue);
      expect(ScheduleConflictDetector.conflictsWithExisting(existing, [boundary]), isFalse);
    });

    test('horas inválidas nunca generan conflicto', () {
      expect(ScheduleConflictDetector.overlapTimes('7:00', '09:00', '08:00', '10:00'), isFalse);
      expect(ScheduleConflictDetector.overlapTimes('25:00', '26:00', '08:00', '10:00'), isFalse);
    });
  });

  group('Reglas de salones', () {
    test('acepta solo salones existentes', () {
      expect(isKnownClassroom('2102'), isTrue);
      expect(isKnownClassroom('4213'), isTrue);
      expect(isKnownClassroom('4214'), isFalse);
      expect(isKnownClassroom('3001'), isFalse);
      expect(normalizeKnownClassroom(' 1101 '), '1101');
      expect(normalizeKnownClassroom('LAB'), isNull);
    });

    test('clave de selección de materias', () {
      expect(subjectSelectionKey('Análisis de Algoritmos'), 'analisis_de_algoritmos');
      expect(encodeSubjectSelection({'b', 'a', ''}), 'a;b');
      expect(decodeSubjectSelection(' a ; ;b'), {'a', 'b'});
    });
  });
}
