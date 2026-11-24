/// Salones válidos de ESCOM (portado de `ClassroomRules.kt`).
library;

import '../text/text_normalization.dart';

/// Rangos `[inicio, fin]` inclusivos de salones existentes.
const List<(int, int)> allowedClassroomRanges = [
  (1001, 1014),
  (1101, 1114),
  (1201, 1214),
  (2001, 2014),
  (2101, 2114),
  (2201, 2214),
  (3003, 3014),
  (3101, 3114),
  (3201, 3214),
  (4001, 4014),
  (4101, 4114),
  (4201, 4213),
];

final RegExp _fourDigits = RegExp(r'^\d{4}$');

bool isKnownClassroom(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || !_fourDigits.hasMatch(trimmed)) return false;
  final number = int.parse(trimmed);
  return allowedClassroomRanges.any((r) => number >= r.$1 && number <= r.$2);
}

/// El número de salón recortado si es válido; si no, `null`.
String? normalizeKnownClassroom(String? value) {
  final trimmed = value?.trim() ?? '';
  return isKnownClassroom(trimmed) ? trimmed : null;
}

/// Clave estable de una materia para guardar selecciones (notificaciones).
String subjectSelectionKey(String subject) => removeDiacritics(subject)
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

Set<String> decodeSubjectSelection(String value) =>
    {for (final s in value.split(';')) if (s.trim().isNotEmpty) s.trim()};

String encodeSubjectSelection(Set<String> values) =>
    (values.where((v) => v.trim().isNotEmpty).toList()..sort()).join(';');
