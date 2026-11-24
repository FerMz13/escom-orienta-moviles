/// Normalización de texto en español (equivalente a `Normalizer.NFD` +
/// eliminación de marcas diacríticas de la versión Kotlin).
library;

const Map<String, String> _diacritics = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
  'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A',
  'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
  'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
  'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O',
  'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
  'Ñ': 'N', 'Ç': 'C', 'Ý': 'Y',
};

/// Marcas combinantes sueltas (U+0300–U+036F), por si el texto ya viene en NFD.
final RegExp _combiningMarks = RegExp('[̀-ͯ]');
final RegExp _whitespace = RegExp(r'\s+');

/// Quita acentos y diéresis conservando el resto de caracteres.
String removeDiacritics(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString().replaceAll(_combiningMarks, '');
}

/// Colapsa espacios consecutivos y recorta.
String cleanSpaces(String value) => value.replaceAll(_whitespace, ' ').trim();

/// Sin acentos, en minúsculas y con espacios colapsados (para búsquedas).
String normalizeForSearch(String value) =>
    cleanSpaces(removeDiacritics(value).toLowerCase());
