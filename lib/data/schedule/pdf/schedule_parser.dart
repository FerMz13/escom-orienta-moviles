import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../../domain/schedule/classroom_rules.dart';
import '../../../domain/text/text_normalization.dart';
import 'pdf_text_models.dart';

/// Sesión tal como se lee del PDF, antes de normalizar.
class RawScheduleSession {
  const RawScheduleSession({
    required this.subjectName,
    this.groupName,
    this.teacherName,
    required this.dayName,
    required this.startTime,
    required this.endTime,
    this.classroomName,
    this.rawText,
    this.teacherSourceText,
  });

  final String subjectName;
  final String? groupName;
  final String? teacherName;
  final String dayName;
  final String startTime;
  final String endTime;
  final String? classroomName;
  final String? rawText;
  final String? teacherSourceText;

  @override
  String toString() =>
      'Raw($groupName, $subjectName, $dayName $startTime-$endTime, $classroomName, $teacherName)';
}

class TeacherName {
  const TeacherName(this.sourceText, this.displayText);

  /// Texto tal cual aparece en el PDF.
  final String sourceText;

  /// Nombre formateado, o `null` si el profesor está "SIN ASIGNAR".
  final String? displayText;
}

/// Inicio horizontal de cada columna de la tabla del SAES.
class TableColumns {
  const TableColumns({
    required this.groupStartX,
    required this.subjectStartX,
    required this.creditsStartX,
    required this.teacherStartX,
    required this.mondayStartX,
    required this.tuesdayStartX,
    required this.wednesdayStartX,
    required this.thursdayStartX,
    required this.fridayStartX,
  });
  final double groupStartX;
  final double subjectStartX;
  final double creditsStartX;
  final double teacherStartX;
  final double mondayStartX;
  final double tuesdayStartX;
  final double wednesdayStartX;
  final double thursdayStartX;
  final double fridayStartX;
}

/// Lee la tabla del horario del SAES (portado de `ScheduleParser.kt`).
///
/// 1. Lectura posicional: ubica las columnas por los encabezados de los días
///    y las filas por los códigos de grupo (`3CM1`), y asigna cada rango de
///    horas a su celda.
/// 2. Si eso falla, lectura de texto plano asignando días en orden.
class ScheduleParser {
  const ScheduleParser();

  List<RawScheduleSession> parse(PdfTextDocument document) {
    final positioned = _parsePositionedTable(document);
    return positioned.isNotEmpty ? positioned : _parsePlainTextFallback(document.plainText);
  }

  List<RawScheduleSession> _parsePositionedTable(PdfTextDocument document) {
    final tokens = document.tokens;
    if (tokens.isEmpty) return const [];

    final dayColumns = _findDayColumns(tokens);
    if (dayColumns.length < 5) return const [];

    final headerYByPage = _averageBy(dayColumns, (c) => c.pageIndex, (c) => c.y);
    final footerYByPage = <int, double>{};
    for (final t in tokens.where(_isFooterStart)) {
      footerYByPage[t.pageIndex] = math.max(footerYByPage[t.pageIndex] ?? t.y, t.y);
    }

    final sessions = <RawScheduleSession>[];
    final groupTokensByPage = <int, List<PdfTextToken>>{};
    for (final t in tokens) {
      if (_groupFull.hasMatch(t.text.trim())) {
        groupTokensByPage.putIfAbsent(t.pageIndex, () => []).add(t);
      }
    }

    groupTokensByPage.forEach((pageIndex, pageGroupTokens) {
      final pageColumns = detectTableColumns(tokens, pageIndex);
      final creditX = pageColumns?.creditsStartX ??
          tokens
              .where((t) => t.pageIndex == pageIndex && _normalized(t) == 'creditos')
              .firstOrNull
              ?.x ??
          230.0;
      final headerY = headerYByPage[pageIndex];
      final footerY = footerYByPage[pageIndex];
      final pageTokens = [
        for (final t in tokens)
          if (t.pageIndex == pageIndex && !_isBelowFooter(t, headerY, footerY)) t,
      ];
      final rows = _buildRowRanges(pageGroupTokens, headerY);
      final pageDayColumns = dayColumns.where((c) => c.pageIndex == pageIndex).toList();

      for (final row in rows) {
        final rowTokens = [
          for (final t in pageTokens)
            if (t.y >= row.lowerY && t.y <= row.upperY) t,
        ];
        final groupName = row.groupToken.text.trim();
        final readDescending = _shouldReadDescending(headerY, row.groupToken.y);
        final subject = _extractSubject(rowTokens, creditX, row.groupToken.endX, readDescending);
        if (subject.isEmpty) continue;

        final teacher = pageColumns != null
            ? extractTeacher(rowTokens, pageColumns)
            : extractTeacherFromPlainRow(_rowForGroup(document.plainText, groupName));

        for (final dayColumn in pageDayColumns) {
          final cellTokens = [
            for (final t in rowTokens)
              if (t.centerX >= dayColumn.startX &&
                  t.centerX < dayColumn.endX &&
                  !_dayNames.contains(_normalized(t)))
                t,
          ];
          final cellLines = _toLines(cellTokens, readDescending);
          final rawCellText = cellLines.map((l) => l.text).join(' ');
          for (final line in cellLines) {
            for (final match in _timeRange.allMatches(line.text)) {
              sessions.add(RawScheduleSession(
                subjectName: subject,
                groupName: groupName,
                teacherName: teacher?.displayText,
                dayName: dayColumn.dayName,
                startTime: '${match[1]}:${match[2]}',
                endTime: '${match[3]}:${match[4]}',
                classroomName: _extractClassroom(rawCellText),
                rawText: cleanSpaces([groupName, subject, dayColumn.dayName, rawCellText].join(' ')),
                teacherSourceText: teacher?.sourceText,
              ));
            }
          }
        }
      }
    });

    return _distinctBy(
      sessions,
      (s) => '${s.groupName}|${s.subjectName}|${s.dayName}|${s.startTime}|${s.endTime}|${s.classroomName}',
    );
  }

  List<_DayColumn> _findDayColumns(List<PdfTextToken> tokens) {
    final headers = _distinctBy(
      tokens.where((t) => _dayNames.contains(_normalized(t))),
      (t) => '${t.pageIndex}-${_normalized(t)}',
    );
    final byPage = <int, List<PdfTextToken>>{};
    for (final t in headers) {
      byPage.putIfAbsent(t.pageIndex, () => []).add(t);
    }
    final pages = byPage.keys.toList()..sort();
    return [
      for (final page in pages)
        ...() {
          final sorted = byPage[page]!..sort((a, b) => a.x.compareTo(b.x));
          return [
            for (var i = 0; i < sorted.length; i++)
              _DayColumn(
                dayName: _dayNameByNormalized[_normalized(sorted[i])]!,
                pageIndex: page,
                x: sorted[i].x,
                y: sorted[i].y,
                startX: i > 0 ? (sorted[i - 1].x + sorted[i].x) / 2 : sorted[i].x - 35,
                endX: i < sorted.length - 1
                    ? (sorted[i + 1].x + sorted[i].x) / 2
                    : sorted[i].endX + 65,
              ),
          ];
        }(),
    ];
  }

  /// Columnas de la tabla a partir de los encabezados, o `null` si no se
  /// encuentran "PROFESOR" y "LUNES" en orden.
  TableColumns? detectTableColumns(List<PdfTextToken> tokens, int pageIndex) {
    final page = tokens.where((t) => t.pageIndex == pageIndex).toList();
    final professor = _findHeaderToken(page, ['PROFESOR']);
    final monday = _findHeaderToken(page, ['LUNES']);
    if (professor == null || monday == null || professor.x >= monday.x) return null;

    final columns = TableColumns(
      groupStartX: _findHeaderToken(page, ['GPO', 'GRUPO'])?.x ?? 0,
      subjectStartX: _findHeaderPhrase(page, 'UNIDAD DE APRENDIZAJE')?.x ??
          _findHeaderToken(page, ['UNIDAD'])?.x ??
          60,
      creditsStartX: _findHeaderToken(page, ['CREDITOS'])?.x ?? 230,
      teacherStartX: professor.x,
      mondayStartX: monday.x,
      tuesdayStartX: _findHeaderToken(page, ['MARTES'])?.x ?? monday.x,
      wednesdayStartX: _findHeaderToken(page, ['MIERCOLES'])?.x ?? monday.x,
      thursdayStartX: _findHeaderToken(page, ['JUEVES'])?.x ?? monday.x,
      fridayStartX: _findHeaderToken(page, ['VIERNES'])?.x ?? monday.x,
    );
    if (kDebugMode) {
      debugPrint('ScheduleParser: columnas página $pageIndex: '
          'Profesor=${columns.teacherStartX}, Lunes=${columns.mondayStartX}');
    }
    return columns;
  }

  PdfTextToken? _findHeaderToken(List<PdfTextToken> tokens, List<String> candidates) {
    final expected = candidates.map(normalizeForMatching).toSet();
    return tokens.where((t) => expected.contains(normalizeForMatching(t.text))).firstOrNull;
  }

  PdfTextToken? _findHeaderPhrase(List<PdfTextToken> tokens, String phrase) {
    final expected = normalizeForMatching(phrase);
    for (final line in _groupIntoTokenLines(tokens)) {
      final sorted = [...line]..sort((a, b) => a.x.compareTo(b.x));
      for (var start = 0; start < sorted.length; start++) {
        var combined = '';
        for (var end = start; end < sorted.length; end++) {
          combined = '$combined ${sorted[end].text}'.trim();
          final normalized = normalizeForMatching(combined);
          if (normalized == expected) return sorted[start];
          if (normalized.length > expected.length + 8) break;
        }
      }
    }
    return null;
  }

  List<_RowRange> _buildRowRanges(List<PdfTextToken> groupTokens, double? headerY) {
    final sorted = [...groupTokens]..sort((a, b) => a.y.compareTo(b.y));
    return [
      for (var i = 0; i < sorted.length; i++)
        () {
          final token = sorted[i];
          var lower = i > 0 ? (sorted[i - 1].y + token.y) / 2 : double.negativeInfinity;
          var upper = i < sorted.length - 1 ? (sorted[i + 1].y + token.y) / 2 : double.infinity;
          if (headerY != null) {
            if (headerY > token.y && i == sorted.length - 1) {
              upper = (headerY + token.y) / 2;
            } else if (headerY < token.y && i == 0) {
              lower = (headerY + token.y) / 2;
            }
          }
          return _RowRange(token, lower, upper);
        }(),
    ];
  }

  String _extractSubject(
    List<PdfTextToken> rowTokens,
    double creditX,
    double groupEndX,
    bool readDescending,
  ) {
    final subjectTokens = [
      for (final t in rowTokens)
        if (t.x > groupEndX + 4 && t.centerX < creditX - 4 && !_timeRange.hasMatch(t.text)) t,
    ];
    return cleanSpaces(_joinForReading(subjectTokens, readDescending)
        .replaceFirst(_courseCodePrefix, '')
        .replaceAll('|', ' / '));
  }

  /// Profesor dentro de la columna "PROFESOR" de una fila.
  TeacherName? extractTeacher(List<PdfTextToken> rowTokens, TableColumns columns) {
    // Un apellido largo puede cruzar el borde visual de la columna; usar el
    // centro lo conserva y aun así descarta las palabras del lunes.
    final accepted = [
      for (final t in rowTokens)
        if (t.x >= columns.teacherStartX - _columnMargin &&
            t.centerX < columns.mondayStartX - _columnMargin &&
            !_isTeacherNoiseToken(t))
          t,
    ];
    // Se lee por renglones (con tolerancia) y de izquierda a derecha, para que
    // diferencias mínimas de `y` dentro de un renglón no alteren el orden.
    return teacherNameFromSource(_joinForReading(accepted, false));
  }

  String? _extractClassroom(String text) {
    final building = int.tryParse(_building.firstMatch(text)?[1] ?? '');
    final room = _room.firstMatch(text);
    if (room != null) {
      final visibleRoom = room[1];
      if (visibleRoom == null || visibleRoom.trim().isEmpty) return null;
      return _normalizeSaesClassroom(building, cleanSpaces(visibleRoom));
    }
    final lab = _lab.firstMatch(text);
    return lab == null ? null : cleanSpaces(lab[0]!);
  }

  /// El SAES muestra "Edificio: 2  Salón: 102"; se convierte en `2102`.
  String? _normalizeSaesClassroom(int? building, String visibleRoom) {
    final digits = visibleRoom.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final candidate = digits.length == 4
        ? digits
        : building != null && digits.length <= 3
            ? '$building${digits.padLeft(3, '0')}'
            : digits;
    return normalizeKnownClassroom(candidate);
  }

  List<RawScheduleSession> _parsePlainTextFallback(String text) {
    final cleaned = _trimFooterText(text.replaceAll('\r', '\n'));
    final matches = _group.allMatches(cleaned).toList();
    if (matches.isEmpty) return const [];

    final sessions = <RawScheduleSession>[];
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final nextStart = i + 1 < matches.length ? matches[i + 1].start : cleaned.length;
      final row = cleanSpaces(cleaned.substring(match.start, nextStart));
      final subject = _extractSubjectFromPlainRow(row);
      final teacher = extractTeacherFromPlainRow(row);
      var dayIndex = 0;
      for (final time in _timeRange.allMatches(row)) {
        if (dayIndex >= _plainTextDayOrder.length) break;
        final afterTime = row.substring(time.end);
        sessions.add(RawScheduleSession(
          subjectName: subject,
          groupName: match[0],
          teacherName: teacher?.displayText,
          dayName: _plainTextDayOrder[dayIndex++],
          startTime: '${time[1]}:${time[2]}',
          endTime: '${time[3]}:${time[4]}',
          classroomName: _extractClassroom(
              afterTime.length > 120 ? afterTime.substring(0, 120) : afterTime),
          rawText: row,
          teacherSourceText: teacher?.sourceText,
        ));
      }
    }
    return sessions;
  }

  String _extractSubjectFromPlainRow(String row) {
    final afterGroup = row.replaceFirst(_group, '').trim();
    final credits = _credits.firstMatch(afterGroup);
    final beforeCredits = credits == null ? afterGroup : afterGroup.substring(0, credits.start);
    return cleanSpaces(beforeCredits.replaceFirst(_courseCodePrefix, '').replaceAll('|', ' / '));
  }

  /// Profesor en una fila de texto plano: lo que sigue a los créditos.
  TeacherName? extractTeacherFromPlainRow(String row) {
    final credits = _credits.firstMatch(row);
    if (credits == null) return null;
    return teacherNameFromSource(row.substring(credits.end));
  }

  List<PdfTextLine> _toLines(List<PdfTextToken> tokens, bool readDescending) {
    if (tokens.isEmpty) return const [];
    final lines = _groupIntoTokenLines(tokens);
    double avgY(List<PdfTextToken> line) =>
        line.map((t) => t.y).reduce((a, b) => a + b) / line.length;
    lines.sort((a, b) => readDescending ? avgY(b).compareTo(avgY(a)) : avgY(a).compareTo(avgY(b)));
    return [
      for (final line in lines)
        () {
          final sorted = [...line]..sort((a, b) => a.x.compareTo(b.x));
          return PdfTextLine(
            text: cleanSpaces(sorted.map((t) => t.text).join(' ')),
            pageIndex: sorted.first.pageIndex,
            x: sorted.map((t) => t.x).reduce(math.min),
            y: avgY(sorted),
            endX: sorted.map((t) => t.endX).reduce(math.max),
          );
        }(),
    ];
  }

  List<List<PdfTextToken>> _groupIntoTokenLines(List<PdfTextToken> tokens) {
    final lines = <List<PdfTextToken>>[];
    final sorted = [...tokens]..sort((a, b) => a.y.compareTo(b.y));
    for (final token in sorted) {
      final line = lines.where((existing) {
        final reference = existing.first;
        final tolerance = [
          _defaultLineTolerance,
          reference.height * _relativeLineTolerance,
          token.height * _relativeLineTolerance,
        ].reduce(math.max);
        return (reference.y - token.y).abs() <= tolerance;
      }).firstOrNull;
      if (line == null) {
        lines.add([token]);
      } else {
        line.add(token);
      }
    }
    return lines;
  }

  String _joinForReading(List<PdfTextToken> tokens, bool readDescending) =>
      cleanSpaces(_toLines(tokens, readDescending).map((l) => l.text).join(' '));

  bool _shouldReadDescending(double? headerY, double rowY) => headerY == null || headerY > rowY;

  static String _normalized(PdfTextToken t) => removeDiacritics(t.text).toLowerCase().trim();

  static String _trimPunctuation(String value) => value.replaceFirst(RegExp(r'[:.,]+$'), '');

  bool _isTeacherNoiseToken(PdfTextToken t) {
    final raw = t.text.trim();
    final value = _trimPunctuation(_normalized(t));
    return raw.isEmpty ||
        _creditsFull.hasMatch(raw) ||
        _timeTokenFull.hasMatch(raw) ||
        _numericNoiseFull.hasMatch(raw) ||
        _dayNames.contains(value) ||
        value == 'edificio' ||
        value.startsWith('salon') ||
        value == 'aula';
  }

  static bool _isFooterStart(PdfTextToken t) {
    final value = _trimPunctuation(_normalized(t));
    return value == 'nota' || value.startsWith('dae_web');
  }

  bool _isBelowFooter(PdfTextToken t, double? headerY, double? footerY) {
    if (headerY == null || footerY == null) return false;
    return headerY > footerY ? t.y <= footerY + _footerPadding : t.y >= footerY - _footerPadding;
  }

  String _trimFooterText(String text) {
    final footer = _footerText.firstMatch(text);
    return footer == null ? text : text.substring(0, footer.start);
  }

  String _rowForGroup(String plainText, String groupName) {
    final cleaned = _trimFooterText(plainText.replaceAll('\r', '\n'));
    final match = _group.allMatches(cleaned).where((m) => m[0] == groupName).firstOrNull;
    if (match == null) return '';
    final next = _group.allMatches(cleaned, match.end).firstOrNull?.start ?? cleaned.length;
    return cleanSpaces(cleaned.substring(match.start, next));
  }

  static Map<int, double> _averageBy<T>(
    Iterable<T> items,
    int Function(T) key,
    double Function(T) value,
  ) {
    final sums = <int, (double, int)>{};
    for (final item in items) {
      final (s, c) = sums[key(item)] ?? (0.0, 0);
      sums[key(item)] = (s + value(item), c + 1);
    }
    return sums.map((k, v) => MapEntry(k, v.$1 / v.$2));
  }

  static List<T> _distinctBy<T>(Iterable<T> items, String Function(T) key) {
    final seen = <String>{};
    return [for (final item in items) if (seen.add(key(item))) item];
  }

  static const _dayNameByNormalized = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miercoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sabado',
  };
  static final Set<String> _dayNames = _dayNameByNormalized.keys.toSet();
  static const _plainTextDayOrder = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];

  static final _group = RegExp(r'\b\d+[A-Z]{2}\d\b');
  static final _groupFull = RegExp(r'^\d+[A-Z]{2}\d$');
  static final _credits = RegExp(r'\b\d{1,2}(?:\.\d{1,2})\b');
  static final _creditsFull = RegExp(r'^\d{1,2}(?:\.\d{1,2})$');
  static final _courseCodePrefix = RegExp(r'^[A-Z]\d{3}\s*[-–—]\s*');
  static final _timeRange = RegExp(r'(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})');
  static final _timeTokenFull = RegExp(r'^\d{1,2}[:.]\d{2}$');
  static final _numericNoiseFull = RegExp(r'^[\d.]+$');
  static final _building = RegExp(r'edificio\s*:?\s*([1-4])', caseSensitive: false);
  static final _room = RegExp(r'(?:sal[oó]n|aula)\s*:?\s*([A-Za-z0-9-]+)', caseSensitive: false);
  static final _lab = RegExp(r'\b(?:lab|laboratorio)\s*[A-Za-z0-9-]*\b', caseSensitive: false);
  static final _footerText = RegExp(r'\b(?:nota\s*:|dae_web)\b', caseSensitive: false);
  static const double _columnMargin = 2;
  static const double _defaultLineTolerance = 3.5;
  static const double _relativeLineTolerance = 0.4;
  static const double _footerPadding = 4;
}

class _DayColumn {
  const _DayColumn({
    required this.dayName,
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.startX,
    required this.endX,
  });
  final String dayName;
  final int pageIndex;
  final double x;
  final double y;
  final double startX;
  final double endX;
}

class _RowRange {
  const _RowRange(this.groupToken, this.lowerY, this.upperY);
  final PdfTextToken groupToken;
  final double lowerY;
  final double upperY;
}

// --- Nombres de profesor ---

/// Sin acentos, mayúsculas, solo `A-Z0-9` y espacios simples.
String normalizeForMatching(String value) => cleanSpaces(
      removeDiacritics(value).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s]'), ' '),
    );

/// Corta la celda del profesor donde empieza otra columna (edificio, día,
/// horario…) y limpia la puntuación de los extremos.
String? cleanTeacherCell(String raw) {
  final cleaned = cleanSpaces(raw);
  if (cleaned.isEmpty) return null;
  final stop = _teacherStop.firstMatch(cleaned);
  final cut = cleanSpaces(
    cleaned
        .substring(0, stop?.start ?? cleaned.length)
        .replaceAll(RegExp(r'^[\s\-–—,;:]+|[\s\-–—,;:]+$'), ''),
  );
  return cut.isEmpty ? null : cut;
}

TeacherName? teacherNameFromSource(String raw) {
  final source = cleanTeacherCell(raw);
  if (source == null || !isPlausibleTeacherName(source)) return null;
  return TeacherName(
    source,
    _unassignedTeacherValues.contains(normalizeForMatching(source))
        ? null
        : _formatTeacherName(source.trim().split(RegExp(r'\s+'))),
  );
}

bool isPlausibleTeacherName(String value) {
  final normalized = normalizeForMatching(value);
  if (_unassignedTeacherValues.contains(normalized)) return true;
  final words = value.trim().split(RegExp(r'\s+'));
  if (words.length < 2 || words.length > 8 || value.contains(':')) return false;
  if (_timeRangeValidation.hasMatch(value)) return false;
  if (_groupCodeValidation.hasMatch(value)) return false;
  final normalizedWords = normalized.split(' ').toSet();
  if (_noiseTeacherWords.any(normalizedWords.contains)) return false;
  final letters = _letter.allMatches(value).length;
  final meaningful = _letterOrDigit.allMatches(value).length;
  return meaningful > 0 && letters / meaningful >= 0.85;
}

String _formatTeacherName(List<String> words) => words.where((w) => w.isNotEmpty).map((word) {
      final lower = word.toLowerCase();
      if (_surnameParticles.contains(normalizeForMatching(word))) return lower;
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');

final _teacherStop = RegExp(
  r'\b(?:edificio|sal[oó]n|aula|nota|dae[_\s-]*web|lunes|martes|miércoles|miercoles|jueves|viernes|sábado|sabado)\b'
  r'|\b\d{1,2}[:.]\d{2}\s*[-–—]\s*\d{1,2}[:.]\d{2}\b',
  caseSensitive: false,
);
final _timeRangeValidation = RegExp(r'\b\d{1,2}[:.]\d{2}\s*[-–—]\s*\d{1,2}[:.]\d{2}\b');
final _groupCodeValidation = RegExp(r'\b\d+[A-Z]{2}\d\b|\b\d{7,}\b', caseSensitive: false);
final _letter = RegExp(r'\p{L}', unicode: true);
final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);
const _noiseTeacherWords = {
  'EDIFICIO', 'SALON', 'AULA', 'NOTA', 'DAE', 'WEB',
  'LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO',
};
const _unassignedTeacherValues = {'SIN ASIGNAR', 'NO ASIGNADO', 'POR ASIGNAR', 'PENDIENTE'};
const _surnameParticles = {'DE', 'DEL', 'LA', 'LAS', 'LOS', 'Y'};
