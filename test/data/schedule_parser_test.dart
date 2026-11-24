import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:escom_orienta_moviles/data/schedule/pdf/pdf_schedule_processor.dart';
import 'package:escom_orienta_moviles/data/schedule/pdf/pdf_text_models.dart';
import 'package:escom_orienta_moviles/data/schedule/pdf/schedule_normalizer.dart';
import 'package:escom_orienta_moviles/data/schedule/pdf/schedule_parser.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_conflict_detector.dart';
import 'package:escom_orienta_moviles/domain/schedule/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

PdfTextToken token(String text, double x, double endX, double y) =>
    PdfTextToken(text: text, pageIndex: 0, x: x, y: y, endX: endX, height: 8);

const columns = TableColumns(
  groupStartX: 20,
  subjectStartX: 60,
  creditsStartX: 230,
  teacherStartX: 300,
  mondayStartX: 400,
  tuesdayStartX: 480,
  wednesdayStartX: 560,
  thursdayStartX: 640,
  fridayStartX: 720,
);

/// Genera un PDF con la estructura de la tabla del horario del SAES.
Uint8List buildSaesLikePdf() {
  final document = sf.PdfDocument();
  document.pageSettings
    ..orientation = sf.PdfPageOrientation.landscape
    ..margins.all = 0;
  final page = document.pages.add();
  final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 7);
  void text(String value, double x, double y) =>
      page.graphics.drawString(value, font, bounds: Rect.fromLTWH(x, y, 200, 10));

  const header = 100.0;
  text('Gpo', 20, header);
  text('Unidad de Aprendizaje', 60, header);
  text('Créditos', 230, header);
  text('Profesor', 300, header);
  text('Lunes', 400, header);
  text('Martes', 500, header);
  text('Miércoles', 600, header);
  text('Jueves', 700, header);
  text('Viernes', 790, header);

  // Fila 1: dos días con salón (Edificio 2, salón 102 → 2102).
  text('3CM1', 20, 130);
  text('ANALISIS DE ALGORITMOS', 60, 130);
  text('7.50', 232, 130);
  text('ORTIZ RAMIREZ', 302, 130);
  text('JOSE ANTONIO', 302, 140);
  for (final x in [402.0, 602.0]) {
    text('10:30 - 12:00', x, 130);
    text('Edificio: 2', x, 140);
    text('Salón: 102', x, 150);
  }

  // Fila 2: profesor sin asignar, un día sin salón y otro con salón inexistente.
  text('3CM2', 20, 180);
  text('REDES DE COMPUTADORAS II', 60, 180);
  text('7.50', 232, 180);
  text('SIN ASIGNAR', 302, 180);
  text('8:30 - 10:00', 502, 180);
  text('8:30 - 10:00', 702, 180);
  text('Edificio: 4', 702, 190);
  text('Salón: 999', 702, 200);

  // Fila 3: choca con la fila 1 el lunes.
  text('3CM3', 20, 230);
  text('INGENIERIA DE SOFTWARE', 60, 230);
  text('7.50', 232, 230);
  text('MORALES ANA', 302, 230);
  text('11:00 - 12:30', 402, 230);

  text('Nota: horario sujeto a cambios', 20, 300);
  text('3CM9 NO DEBE LEERSE 07:00 - 08:00', 20, 320);

  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();
  return bytes;
}

void main() {
  const parser = ScheduleParser();

  group('Nombres de profesor (portado de ScheduleParserTeacherTest.kt)', () {
    test('conserva el orden del PDF', () {
      expect(teacherNameFromSource('MARCO ANTONIO')?.displayText, 'Marco Antonio');
      expect(teacherNameFromSource('ANA MARIA LOPEZ')?.displayText, 'Ana Maria Lopez');
      expect(teacherNameFromSource('DE LA CRUZ PEREZ JUAN CARLOS')?.displayText,
          'de la Cruz Perez Juan Carlos');
    });

    test('limpia lo que sigue a la celda del profesor', () {
      expect(cleanTeacherCell('ORTIZ RAMIREZ JOSE ANTONIO EDIFICIO: 4 SALÓN: 109'),
          'ORTIZ RAMIREZ JOSE ANTONIO');
      expect(cleanTeacherCell('MORALES ANA 18:30 - 20:00 EDIFICIO: 4'), 'MORALES ANA');
    });

    test('"SIN ASIGNAR" conserva el texto pero no tiene nombre visible', () {
      final teacher = teacherNameFromSource('SIN ASIGNAR');
      expect(teacher?.sourceText, 'SIN ASIGNAR');
      expect(teacher?.displayText, isNull);
    });

    test('rechaza valores implausibles', () {
      expect(teacherNameFromSource('7CV3 EDIFICIO 4'), isNull);
      expect(teacherNameFromSource('2021630074 JOSE'), isNull);
      expect(teacherNameFromSource('JOSE ANTONIO: 4'), isNull);
    });

    test('extracción geométrica solo toma la columna del profesor', () {
      final result = parser.extractTeacher([
        token('ORTIZ', 302, 326, 100),
        token('RAMIREZ', 329, 366, 100),
        token('JOSE', 302, 322, 106),
        token('ANTONIO', 325, 360, 106),
        token('18:30', 402, 426, 100),
        token('Edificio:', 430, 470, 100),
        token('Nota:', 40, 64, 400),
      ], columns);
      expect(result?.sourceText, 'ORTIZ RAMIREZ JOSE ANTONIO');
      expect(result?.displayText, 'Ortiz Ramirez Jose Antonio');
    });

    test('conserva un apellido largo cuyo centro está en la columna', () {
      final result = parser.extractTeacher([
        token('MARCO', 302, 330, 100),
        token('ANTONIO', 333, 368, 100),
        token('HERNANDEZ', 365, 407, 100),
      ], columns);
      expect(result?.displayText, 'Marco Antonio Hernandez');
    });

    test('normalización para comparar encabezados', () {
      expect(normalizeForMatching('Créditos:'), 'CREDITOS');
      expect(normalizeForMatching('Unidad  de aprendizaje'), 'UNIDAD DE APRENDIZAJE');
      expect(isPlausibleTeacherName('ORTIZ RAMIREZ JOSE ANTONIO'), isTrue);
    });
  });

  group('ScheduleNormalizer', () {
    const normalizer = ScheduleNormalizer();

    test('normaliza día, hora, materia, grupo y salón', () {
      final drafts = normalizer.normalize(const [
        RawScheduleSession(
          subjectName: 'CALCULO  APLICADO | IA',
          groupName: ' 2cv1 ',
          dayName: 'Miércoles',
          startTime: '7:00',
          endTime: '8.30',
          classroomName: 'Salón: 1104',
        ),
        RawScheduleSession(subjectName: 'X', dayName: 'Domingo', startTime: '7:00', endTime: '8:00'),
      ]);
      final d = drafts.single;
      expect(d.subjectName, 'Calculo Aplicado / IA');
      expect(d.groupName, '2CV1');
      expect(d.dayOfWeek, 3);
      expect((d.startTime, d.endTime), ('07:00', '08:30'));
      expect(d.classroomName, '1104');
      expect(d.classroomStatus, ClassroomStatus.available);
    });
  });

  group('PdfScheduleProcessor con PDF generado (Syncfusion)', () {
    late ScheduleProcessingResult result;
    setUpAll(() => result = const PdfScheduleProcessor().process(buildSaesLikePdf(), fileName: 'horario.pdf'));

    test('extrae las clases de la tabla y respeta el pie de página', () {
      expect(result, isA<ScheduleProcessingSuccess>(),
          reason: switch (result) {
            ScheduleProcessingError(:final message) => message,
            _ => null,
          });
      final classes = (result as ScheduleProcessingSuccess).classes;
      expect(
        [for (final c in classes) '${c.groupName} ${c.dayOfWeek} ${c.startTime}-${c.endTime} ${c.classroomName}'],
        [
          '3CM1 1 10:30-12:00 2102',
          '3CM3 1 11:00-12:30 null',
          '3CM2 2 08:30-10:00 null',
          '3CM1 3 10:30-12:00 2102',
          '3CM2 4 08:30-10:00 null',
        ],
      );
      expect(classes.any((c) => c.groupName == '3CM9'), isFalse);
    });

    test('materia y profesor legibles', () {
      final classes = (result as ScheduleProcessingSuccess).classes;
      final algoritmos = classes.firstWhere((c) => c.groupName == '3CM1');
      expect(algoritmos.subjectName, 'Analisis De Algoritmos');
      expect(algoritmos.teacherName, 'Ortiz Ramirez Jose Antonio');
      final redes = classes.firstWhere((c) => c.groupName == '3CM2');
      expect(redes.subjectName, 'Redes De Computadoras II');
      expect(redes.teacherName, isNull); // SIN ASIGNAR
    });

    test('estado de salones parcial y conflicto detectado', () {
      final success = result as ScheduleProcessingSuccess;
      expect(success.status, ScheduleStatus.partialRooms);
      final conflicts = ScheduleConflictDetector.detect(success.classes);
      expect(conflicts, hasLength(1));
      expect({conflicts.single.first.groupName, conflicts.single.second.groupName}, {'3CM1', '3CM3'});
    });
  });

  group('PdfScheduleProcessor errores', () {
    test('rechaza archivos que no son PDF', () {
      final r = const PdfScheduleProcessor()
          .process(Uint8List.fromList('hola'.codeUnits), fileName: 'horario.txt');
      expect((r as ScheduleProcessingError).message, 'El archivo seleccionado no es PDF.');
    });

    test('un PDF sin tabla del SAES devuelve error legible', () {
      final document = sf.PdfDocument();
      document.pages.add().graphics.drawString(
          'Documento cualquiera', sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 12),
          bounds: const Rect.fromLTWH(0, 0, 300, 20));
      final bytes = Uint8List.fromList(document.saveSync());
      document.dispose();
      expect(const PdfScheduleProcessor().process(bytes), isA<ScheduleProcessingError>());
    });

    test('isPdf por firma o por extensión', () {
      expect(PdfScheduleProcessor.isPdf(Uint8List.fromList('%PDF-1.7'.codeUnits), null), isTrue);
      expect(PdfScheduleProcessor.isPdf(Uint8List(0), 'HORARIO.PDF'), isTrue);
      expect(PdfScheduleProcessor.isPdf(Uint8List(0), 'a.png'), isFalse);
    });
  });
}
