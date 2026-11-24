/// Texto extraído de un PDF, con posiciones por palabra.
///
/// Coordenadas en puntos PDF con origen arriba a la izquierda (la `y` crece
/// hacia abajo), igual que `yDirAdj` de PDFBox en la versión Kotlin.
library;

class PdfTextDocument {
  const PdfTextDocument({required this.plainText, required this.tokens});
  final String plainText;
  final List<PdfTextToken> tokens;
}

class PdfTextToken {
  const PdfTextToken({
    required this.text,
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.endX,
    required this.height,
  });

  final String text;
  final int pageIndex;
  final double x;

  /// Línea base aproximada.
  final double y;
  final double endX;
  final double height;

  double get centerX => (x + endX) / 2;

  @override
  String toString() => 'Token("$text", p$pageIndex, x=$x..$endX, y=$y)';
}

class PdfTextLine {
  const PdfTextLine({
    required this.text,
    required this.pageIndex,
    required this.x,
    required this.y,
    required this.endX,
  });
  final String text;
  final int pageIndex;
  final double x;
  final double y;
  final double endX;
}
